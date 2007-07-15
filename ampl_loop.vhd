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
-- Se utiliza una ruta de precisión extendida para maximizar el número de
-- decimales que llegan a la entrada del cáculo de raíz cuadrada. De esta forma
-- se obtiene un "alpha" lo más preciso posible. Como se dispone de
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
	port (
		clk, run, rst : in std_logic;
		in_signal, our_signal : in std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
		norm_in_signal : out std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
		done : out std_logic);
end ampl_loop;

architecture alg of ampl_loop is
	-- Types
	type state_t is (ST_DONE, ST_RUNNING, ST_LAST);

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
	signal st : state_t := ST_DONE;
	signal sqrt_done_s, sqrt_error_s : std_logic;
	signal seq_run, component_en : std_logic;

	-- * DATA PATH *
	-- Extended width (FX3.18)
	signal squared_in_EXT_s, squared_alpha_EXT_s, comp_EXT_s : std_logic_vector(EXT_PIPELINE_WIDTH - 1 downto 0);
	signal error_EXT_s, int_error_EXT_s, filtered_error_EXT_s : std_logic_vector(EXT_PIPELINE_WIDTH - 1 downto 0);
	signal error_adder_1_out_EXT_s : std_logic_vector(EXT_PIPELINE_WIDTH - 1 downto 0);
	signal alpha_EXT_s : std_logic_vector(EXT_PIPELINE_WIDTH - 1 downto 0);
	-- Normal width (FX3.16)
	signal norm_s, squared_norm_s, squared_in_s, error_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
	signal comp_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
	signal pi_kp_out_s, filtered_error_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
	signal alpha_s, norm_in_signal_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
begin
	ref_square : mul
		generic map ( width => PIPELINE_WIDTH, prec_bits => PIPELINE_PREC)
		port map (norm_s, norm_s, squared_norm_s);
        
	in_square : mul
		generic map (width => PIPELINE_WIDTH, prec_bits => PIPELINE_PREC)
		port map (in_signal, in_signal, squared_in_s);

	in_mul : mul
		generic map (width => EXT_PIPELINE_WIDTH, prec_bits => EXT_PIPELINE_PREC)
		port map (squared_in_EXT_s, squared_alpha_EXT_s, comp_EXT_s);

	error_sub : entity work.subsor(alg)
		port map (
			a => squared_norm_s, b => squared_in_s, o => error_s,
			f_ov => open, f_z => open);

	comp_s_conv : entity work.pipeline_conv(alg)
		generic map (
			EXT_PIPELINE_WIDTH, EXT_PIPELINE_PREC,
			PIPELINE_WIDTH, PIPELINE_PREC)
		port map ( comp_EXT_s, comp_s );

	error_s_conv : entity work.pipeline_conv(alg)
		generic map (
			PIPELINE_WIDTH, PIPELINE_PREC,
			EXT_PIPELINE_WIDTH, EXT_PIPELINE_PREC)
		port map ( error_s, error_EXT_s);

	pi_integrator : entity work.kcm_integrator(alg)
		generic map (
			width => EXT_PIPELINE_WIDTH, prec => EXT_PIPELINE_PREC,
			k => EXAMPLE_VAL_FX316
		)
		port map (
			clk => clk, we => component_en, rst => rst,
			i => error_EXT_s, o => int_error_EXT_s
		);

	pi_kp_mul : entity work.kcm(alg)
		generic map ( k => EXAMPLE_VAL_FX316 )
		port map ( i => error_s, o => pi_kp_out_s );

	pi_lpf : entity work.first_order_lpf(alg)
		port map (
			clk => clk, we => component_en, rst => rst,
			i_port => pi_kp_out_s, o_port => filtered_error_s
		);

	filtered_error_s_conv : entity work.pipeline_conv(alg)
		generic map (
			PIPELINE_WIDTH, PIPELINE_PREC,
			EXT_PIPELINE_WIDTH, EXT_PIPELINE_PREC
		)
		port map (filtered_error_s, filtered_error_EXT_s);

	error_adder_1 : entity work.adder(alg)
		generic map ( EXT_PIPELINE_WIDTH )
		port map (
			a => int_error_EXT_s, b => filtered_error_EXT_s,
			o => error_adder_1_out_EXT_s
		);

	error_adder_2 : entity work.adder(alg)
		generic map (EXT_PIPELINE_WIDTH)
		port map (
			a => error_adder_1_out_EXT_s, b => std_logic_vector(to_signed(1*8192, EXT_PIPELINE_WIDTH)),
			o => squared_alpha_EXT_s
		);

	sqrt_i : entity work.sqrt(alg)
		port map (
			clk => clk, rst => rst, run => seq_run,
			i => squared_alpha_EXT_s, o => alpha_EXT_s,
			done => sqrt_done_s , error_p => sqrt_error_s);

	alpha_s_conv : entity work.pipeline_conv(alg)
		generic map (
			EXT_PIPELINE_WIDTH, EXT_PIPELINE_PREC,
			PIPELINE_WIDTH, PIPELINE_PREC
		)
		port map ( alpha_EXT_s, alpha_s );

	norm_mul : entity work.mul(alg)
		generic map (width => PIPELINE_WIDTH, prec_bits => PIPELINE_PREC)
		port map (alpha_s, in_signal, norm_in_signal_s);

	fa_i : entity work.fva(alg)
		generic map ( PIPELINE_WIDTH )
		port map (
			clk => clk, en => component_en, rst => rst,
			i => norm_in_signal_s, o => norm_in_signal,
			run => '0'
		);
	
	state_ctrl : process(clk, rst)
	begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				st <= ST_DONE;
			else
				case st is
					when ST_DONE =>
						if (run = '1') then
							-- Next conditions
							st <= ST_RUNNING;
						else
							-- Keep conditions
							st <= ST_DONE;
						end if;
					when ST_RUNNING =>
						if (sqrt_done_s = '1') then
							-- ST_RUNNING: next conditions
							st <= ST_LAST;
						else
							-- ST_RUNNING: keep conditions
							st <= ST_RUNNING;
						end if;
					when ST_LAST =>
						if (run ='1') then
							st <= ST_RUNNING;
						else
							st <= ST_DONE;
						end if;
					when others =>
						st <= st;
				end case;
			end if;
		end if;
	end process state_ctrl;

	signals_gen : process(st, run, sqrt_done_s)
		-- Signals to control are:
		-- Internal:
		-- * component_en
		-- * seq_run
		-- Output:
		-- * done
	begin
		case st is
			when ST_DONE =>
				-- Internal signals
				component_en <= '0';
				seq_run <= run;
				-- Out signals
				done_port <= '1';
			when ST_RUNNING =>
				-- Internal signals
				component_en <= '0';
				seq_run <= sqrt_done_s;
				-- Out signals
				done_port <= '0';
			when ST_LAST =>
				component_en <= '1';
				seq_run <= '1'; -- Or '0', both would be valid. SQRT has been launched in previous cycle (it launched itself)
				-- Out signals
				done_port <= '1';
		end case;
	end process signals_gen;
end alg;
