--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    
-- Design Name:    
-- Module Name:    ampl_loop - alg
-- Project Name:   
-- Target Device:  
-- Tool versions:  
-- *** Description **
-- Alpha == the multiplication factor needed for normalizing the input signal
--
-- ** The extended pipeline width **
-- Se utiliza una ruta de precisi�n extendida para maximizar el n�mero de
-- decimales que llegan a la entrada del c�culo de ra�z cuadrada. De esta forma
-- se obtiene un "alpha" lo m�s preciso posible. Como se dispone de
-- multiplicadores de 18 bits en la Xilinx, decidimos utilizar este valor como
-- valor de ancho de pipeline extendido.
--
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
--------------------------------------------------------------------------------
library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use WORK.COMMON.all;

entity ampl_loop is
        -- rev 0.01
	port (
		clk, run, rst : in std_logic;
		in_signal, our_signal : in std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
		norm_in_signal : out std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
		done : out std_logic);
end ampl_loop;

architecture alg of ampl_loop is
	component mul is
                -- rev 0.01
		generic (
			width : natural := PIPELINE_WIDTH;
			prec_bits : natural := PIPELINE_PREC);
		port (
			a, b : in std_logic_vector (width - 1 downto 0);
			o : out std_logic_vector (width - 1 downto 0));
	end component;

	-- * Internal elements control *
	signal sqrt_error_s : std_logic;
        signal sqrt_done_s, sqrt_done_pulsed_s, fa_delayed_done_s, pi_integrator_done_s, lpf_done_s, filter_stage_done_s : std_logic;
        signal first_run_s, first_run_pulsed_s : std_logic;

        signal garbage_1_s, garbage_2_s, garbage_3_s : std_logic;

	-- * DATA PATH *
	-- Extended width (FX3.18)
	signal squared_in_EXT_s, squared_alpha_EXT_s, squared_in_norm_EXT_s : std_logic_vector(EXT_PIPELINE_WIDTH - 1 downto 0);
	signal error_EXT_s, int_error_EXT_s, filtered_error_EXT_s : std_logic_vector(EXT_PIPELINE_WIDTH - 1 downto 0);
	signal error_adder_1_out_EXT_s : std_logic_vector(EXT_PIPELINE_WIDTH - 1 downto 0);
	signal alpha_EXT_s : std_logic_vector(EXT_PIPELINE_WIDTH - 1 downto 0);
	-- Normal width (FX3.16)
	signal squared_norm_s, squared_in_s, error_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
	signal squared_in_norm_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
	signal pi_kp_out_s, filtered_error_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
	signal alpha_s, norm_in_signal_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
begin
	our_square : mul
		generic map (width => PIPELINE_WIDTH, prec_bits => PIPELINE_PREC)
		port map (our_signal, our_signal, squared_norm_s);
        
	in_square : mul
		generic map (width => PIPELINE_WIDTH, prec_bits => PIPELINE_PREC)
		port map (in_signal, in_signal, squared_in_s);

        squared_in_s_conv : entity work.pipeline_conv(alg)
                generic map (
                        in_width  => PIPELINE_WIDTH,
                        in_prec   => PIPELINE_PREC,
                        out_width => EXT_PIPELINE_WIDTH,
                        out_prec  => EXT_PIPELINE_PREC)
                port map (
                        i => squared_in_s,
                        o => squared_in_EXT_s);
                
	in_mul : mul
		generic map (width => EXT_PIPELINE_WIDTH, prec_bits => EXT_PIPELINE_PREC)
		port map (squared_in_EXT_s, squared_alpha_EXT_s, squared_in_norm_EXT_s);

	error_sub : entity work.subsor(alg)
		port map (
			a => squared_norm_s, b => squared_in_norm_s, o => error_s,
			f_ov => open, f_z => open);

	squared_in_norm_s_conv : entity work.pipeline_conv(alg)
		generic map (
			in_width => EXT_PIPELINE_WIDTH, in_prec => EXT_PIPELINE_PREC,
			out_width => PIPELINE_WIDTH, out_prec => PIPELINE_PREC)
		port map ( i => squared_in_norm_EXT_s, o => squared_in_norm_s );

        -- squared_in_norm_s <= squared_in_norm_EXT_s(15 downto 0);

	error_s_conv : entity work.pipeline_conv(alg)
		generic map (
			PIPELINE_WIDTH, PIPELINE_PREC,
			EXT_PIPELINE_WIDTH, EXT_PIPELINE_PREC)
		port map ( error_s, error_EXT_s);

	pi_integrator : entity work.kcm_integrator(beh)
		generic map (
			width => EXT_PIPELINE_WIDTH, prec => EXT_PIPELINE_PREC,
			k => 4)       -- Ts * 10 = 5e-4 => 4.09 (ans * 8192)
		port map (
			clk => clk, rst => rst,
			i => error_EXT_s, o => int_error_EXT_s,
                        run_en => first_run_pulsed_s, run_passthru => pi_integrator_done_s,
                        delayer_in(0) => '-',
                        delayer_out(0) => garbage_3_s);

        first_run_s <= fa_delayed_done_s and run;
        first_run_pulser : entity work.done_pulser(beh)
                port map (
                        clk => clk,
                        en  => '1',
                        rst => rst,
                        i   => first_run_s,
                        o   => first_run_pulsed_s);
        
	pi_kp_mul : entity work.kcm(alg)
		generic map ( k =>  16384 ) -- 2 * 8192
		port map ( i => error_s, o => pi_kp_out_s );

	pi_lpf : entity work.first_order_lpf(alg)
		port map (
			clk => clk, rst => rst,
			i => pi_kp_out_s, o => filtered_error_s,
                        run_en => first_run_pulsed_s, run_passthru => lpf_done_s,
                        delayer_in(0) => '-',
                        delayer_out(0) => garbage_2_s);

        filter_stage_done_s <= lpf_done_s and pi_integrator_done_s;
                               
	filtered_error_s_conv : entity work.pipeline_conv(alg)
		generic map (
			PIPELINE_WIDTH, PIPELINE_PREC,
			EXT_PIPELINE_WIDTH, EXT_PIPELINE_PREC)
		port map (filtered_error_s, filtered_error_EXT_s);

	error_adder_1 : entity work.adder(alg)
		generic map ( EXT_PIPELINE_WIDTH )
		port map (
			a => int_error_EXT_s, b => filtered_error_EXT_s,
			o => error_adder_1_out_EXT_s);

	error_adder_2 : entity work.adder(alg)
		generic map ( EXT_PIPELINE_WIDTH )
		port map (
			a => error_adder_1_out_EXT_s, b => std_logic_vector(to_signed(1*8192, EXT_PIPELINE_WIDTH)),
			o => squared_alpha_EXT_s);

	sqrt_i : entity work.sqrt(alg)
		port map (
			clk => clk, rst => rst, run => filter_stage_done_s,
			i => squared_alpha_EXT_s, o => alpha_EXT_s,
			done => sqrt_done_s , error_p => sqrt_error_s);

        sqrt_done_pulser : entity work.done_pulser(beh)
                port map (
                        clk => clk,
                        en  => '1',
                        rst => rst,
                        i   => sqrt_done_s,
                        o   => sqrt_done_pulsed_s);

	alpha_s_conv : entity work.pipeline_conv(alg)
		generic map (
			EXT_PIPELINE_WIDTH, EXT_PIPELINE_PREC,
			PIPELINE_WIDTH, PIPELINE_PREC)
		port map ( alpha_EXT_s, alpha_s );
        
        -- alpha_s <= alpha_EXT_s(15 downto 0);

	norm_mul : entity work.mul(alg)
		generic map (width => PIPELINE_WIDTH, prec_bits => PIPELINE_PREC)
		port map (alpha_s, in_signal, norm_in_signal_s);

	fa_i : entity work.fa(beh)
		generic map (
                        width => PIPELINE_WIDTH,
                        prec => PIPELINE_PREC,
                        int_k => AC_FREQ_SAMPLE_SCALED_FX316,
                        delay => 200,   -- fs / 50 Hz = 10000 / 50 = 200
                        delayer_width => 2)
		port map (
			clk => clk, rst => rst,
			i => norm_in_signal_s, o => norm_in_signal,
                        run_en => sqrt_done_pulsed_s, 
			run_passthru => open,
                        delayer_in(0) => '-',
                        delayer_in(1) => sqrt_done_s,
                        delayer_out(0) => garbage_1_s,
                        delayer_out(1) => fa_delayed_done_s);

        done <= fa_delayed_done_s;
end alg;
