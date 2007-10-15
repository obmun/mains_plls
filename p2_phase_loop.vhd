--------------------------------------------------------------------------------
-- Company: UVigo
-- Engineer: Jacobo Cabaleiro
--
-- Create Date:    
-- Design Name:    
-- Module Name: p2_phase_loop - beh
-- Project Name:   
-- Target Device:  
-- Tool versions:
--
-- *** Short desc ***
-- Class: sequential iterative
-- The PLL phase loop for the PLLMonofasicoImplementarBeta2 design (see
-- october_2007 paper)
--
-- *** Description ***
-- Has: synchronous reset.
--
-- ** PORT DESCRIPTION **
-- rst -> Synchronous reset port. A reset ONLY initializes some seq elements to a initial known state, but does not reset some big internal storage elements as buffers (see FA). It's stupid as the presence of a FA will always mean that a big initial # of samples are needed to obtain stable output.
--
-- Dependencies:
-- 
-- *** Changelog ***
-- Revision 0.04 - Added register in the middle of a big big big combinational
-- path (pi_int -> pi_adder -> freq2phase input adder -> freq_2_phase reg).
-- Added at 37 % of total delay path [not the best place], in a "correct"
-- place. pi -> REG -> freq2phase
-- Revision 0.03 - Super change. Now, makes use of new seq. block control iface
-- Revision 0.02 - Interface modification. Good phase_det cycle integration with rest of pipeline.
-- Revision 0.01 - File Created
-- 
--------------------------------------------------------------------------------
library IEEE;
library WORK;
use WORK.COMMON.all;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity p2_phase_loop is
	port (
		clk, rst, run : in std_logic;
		norm_input : in std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
		phase, norm_sin : out std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
		-- freq : out std_logic_vector(PIPELINE_WIDTH - 1 downto 0); I CANNOT SHOW FREQ!!!! 50 => 6 bits magnitude!!!!!!
		done : out std_logic);
end p2_phase_loop;

architecture beh of p2_phase_loop is
	-- Types
	type state_t is (ST_DONE, ST_RUNNING, ST_LAST);
        type coef_1st_ord is array (0 to 1) of real;
        type coef_2nd_ord is array (0 to 2) of real;

        -- Some constants
        constant coef_2nd_ord_filt_num : coef_2nd_ord := (0.9755, -1.947, 0.9755);
        constant coef_2nd_ord_filt_den : coef_2nd_ord := (1.0, -1.947, 0.951);
        constant coef_1st_ord_filt_num : coef_1st_ord := (300.0, -282.3);
        constant coef_1st_ord_filt_den : coef_1st_ord := (1.0, -0.9704);
        
	-- Component declaration
	component phase_det is
                -- rev 0.02
		port (
			-- Input value signals
			norm_input, curr_phase : in std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
			-- Input control signals
			run, rst, clk : in std_logic;
			-- Out value signals
			phase_error : out std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
			norm_output : out std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
			-- Out control signals
			done : out std_logic);
	end component;

	component adder is
		generic (
			width : natural := PIPELINE_WIDTH
		);
		port (
			a, b: in std_logic_vector(width - 1 downto 0);
			o: out std_logic_vector(width - 1 downto 0);
			f_ov, f_z: out std_logic
		);
	end component;

	-- Internal signals
	signal phase_s, phase_det_out_s, fa_out_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
        signal phase_det_done_s, phase_det_done_pulsed_s, iir_1st_ord_done_s, iir_2nd_ord_done_s : std_logic;
        signal phase_det_run_s : std_logic;
        signal iir_1st_ord_delayed_done_s, iir_2nd_ord_delayed_done_s, freq2phase_delayed_done_s : std_logic;
	-- > Filter signals
	signal iir_1st_ord_out_s, iir_2nd_ord_out_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
        -- GARBAGE SIGNALS
        -- These are here because ModelSim complains about keeping a formal
        -- partially open (some of its bits are asigned, other are opened), and
        -- ModelSim requires, at the same time, all of the formal bits to be
        -- mapped to a signal. The only way is to use garbage signals, that
        -- later during synthesis get deleted by the synthesizer.
        signal garbage_1_s, garbage_2_s, garbage_3_s : std_logic;
begin
	-- ** Big blocks **
	phase_det_i : phase_det
		port map (
			run => phase_det_run_s,
                        rst => rst, clk => clk,
			norm_input => norm_input,
			curr_phase => phase_s,
			-- Out value signals
			phase_error => phase_det_out_s,
			norm_output => norm_sin,
			-- Out control signals
			done => phase_det_done_s);

        phase_det_done_pulser : entity work.done_pulser(beh)
                port map (
                        clk => clk, en  => '1', rst => rst,
                        i   => phase_det_done_s,
                        o   => phase_det_done_pulsed_s);
        
	-- Error filters
        iir_1st_ord : entity work.filter_1st_order_iir(beh)
                generic map (
                        width => PIPELINE_WIDTH, prec => PIPELINE_PREC,
                        b0 => coef_1st_ord_filt_num(0),
                        b1 => coef_1st_ord_filt_num(1),
                        a1 => coef_1st_ord_filt_den(1),
                        delayer_width => 2)
                port map (
                        clk => clk, rst => rst,
                        i => phase_det_out_s,
                        o => iir_1st_ord_out_s,
                        run_en => phase_det_done_pulsed_s,
                        run_passthru => iir_1st_ord_done_s,
                        delayer_in(0) => '-',
                        delayer_in(1) => phase_det_done_s,
                        delayer_out(0) => garbage_1_s,
                        delayer_out(1) => iir_1st_ord_delayed_done_s);
        
        iir_2nd_ord : entity work.filter_2nd_order_iir(beh)
                generic map (
                        width => PIPELINE_WIDTH, prec => PIPELINE_PREC,
                        b0 => coef_2nd_ord_filt_num(0),
                        b1 => coef_2nd_ord_filt_num(1),
                        b2 => coef_2nd_ord_filt_num(2),
                        a1 => coef_2nd_ord_filt_den(1),
                        a2 => coef_2nd_ord_filt_den(2),
                        delayer_width => 2)
                port map (
                        clk => clk, rst => rst,
                        i => iir_1st_ord_out_s,
                        o => iir_2nd_ord_out_s,
                        run_en => iir_1st_ord_done_s,
                        run_passthru => iir_2nd_ord_done_s,
                        delayer_in(0) => '-',
                        delayer_in(1) => iir_1st_ord_delayed_done_s,
                        delayer_out(0) => garbage_2_s,
                        delayer_out(1) => iir_2nd_ord_delayed_done_s);

        -- Speed up register. Combinational path formed by pi_int -> pi_adder
        -- -> freq2phase combinational logic at input is TOO long
--        pi_out_reg_i : entity work.reg(alg)
--                generic map (
--                        width => PIPELINE_WIDTH + 2)
--                port map (
--                        clk => clk,
--                        we  => '1',
--                        rst => rst,
--                        i(PIPELINE_WIDTH - 1 downto 0) => pi_adder_out_s,
--                        i(PIPELINE_WIDTH) => pi_done_s,
--                        i(PIPELINE_WIDTH + 1) => pi_delayed_done_s,
--                        o(PIPELINE_WIDTH - 1 downto 0) => pi_adder_out_REG_s,
--                        o(PIPELINE_WIDTH) => pi_done_REG_s,
--                        o(PIPELINE_WIDTH + 1) => pi_delayed_done_REG_s);
        
	freq2phase_i : entity work.freq2phase(beh)
                generic map (
                        width => PIPELINE_WIDTH,
                        delayer_width => 2)
		port map (
			clk => clk, rst => rst,
			f => iir_2nd_ord_out_s,
			p => phase_s,
                        run_en => iir_2nd_ord_done_s,
                        run_passthru => open,
                        delayer_in(0) => '-',
                        delayer_in(1) => iir_2nd_ord_delayed_done_s,
                        delayer_out(0) => garbage_3_s,
                        delayer_out(1) => freq2phase_delayed_done_s);

	phase <= phase_s;
        done <= freq2phase_delayed_done_s and phase_det_done_s;
        phase_det_run_s <= run and freq2phase_delayed_done_s and phase_det_done_s;
end beh;
