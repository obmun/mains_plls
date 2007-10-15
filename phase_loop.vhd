--------------------------------------------------------------------------------
-- Company: UVigo
-- Engineer: Jacobo Cabaleiro
--
-- Create Date:    
-- Design Name:    
-- Module Name:    phase_loop - alg
-- Project Name:   
-- Target Device:  
-- Tool versions:
--
-- *** Short desc ***
-- Class: sequential iterative
-- A PLL phase loop. Follows Cordic signals interface (RUN/DONE iface)
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

entity phase_loop is
	port (
		clk, rst, run : in std_logic;
		norm_input : in std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
		phase, norm_sin : out std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
		-- freq : out std_logic_vector(PIPELINE_WIDTH - 1 downto 0); I CANNOT SHOW FREQ!!!! 50 => 6 bits magnitude!!!!!!
		done : out std_logic);
end phase_loop;

architecture alg of phase_loop is
	-- Types
	type state_t is (ST_DONE, ST_RUNNING, ST_LAST);

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

	component fva is
                -- rev 0.02
                generic (
                        width : natural := PIPELINE_WIDTH);
                port (
                        en, clk, rst : in std_logic;
                        i : in std_logic_vector (width - 1 downto 0);
                        o : out std_logic_vector (width - 1 downto 0);
                        run : in std_logic;
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
        signal phase_det_done_s, phase_det_done_pulsed_s, fva_done_s, pi_done_s, pi_done_REG_s : std_logic;
        signal phase_det_run_s : std_logic;
        signal fva_delayed_done_s, pi_delayed_done_s, pi_delayed_done_REG_s, freq2phase_delayed_done_s : std_logic;
	-- > PI signals
	signal p_kcm_out_s, pi_int_out_s, pi_adder_out_s, pi_adder_out_REG_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
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
        
	fa_i : entity work.fa(beh)
                generic map (
                        width => PIPELINE_WIDTH,
                        prec  => PIPELINE_PREC,
                        k => AC_FREQ,
                        delay => 100,     -- fs / 100 Hz = 10000 / 100 = 1ç00
                        delayer_width => 2)
		port map (
			clk => clk, rst => rst,
			i => phase_det_out_s,
			o => fa_out_s,
                        run_en => phase_det_done_pulsed_s,
                        run_passthru => fva_done_s,
                        delayer_in(0) => '-',
                        delayer_in(1) => phase_det_done_s,
                        delayer_out(0) => garbage_1_s,
                        delayer_out(1) => fva_delayed_done_s);

	-- PI filter components
	pi_p_kcm : entity work.kcm(beh)
		generic map (
			k => PHASE_LOOP_PI_P_CONST)
		port map (
			i => fa_out_s,
			o => p_kcm_out_s);

	pi_int : entity work.kcm_integrator(beh)
		generic map (
			k => PHASE_LOOP_PI_I_CONST,
                        delayer_width => 2)
		port map (
			clk => clk, rst => rst,
                        run_en => fva_done_s,
			i => fa_out_s,
			o => pi_int_out_s,
                        run_passthru => pi_done_s,
                        delayer_in(0) => '-',
                        delayer_in(1) => fva_delayed_done_s,
                        delayer_out(0) => garbage_2_s,  -- open <- modelsim
                                                        -- doesn't like this
                        delayer_out(1) => pi_delayed_done_s);

	pi_adder : adder
		port map (
			a => pi_int_out_s,
			b => p_kcm_out_s,
			o => pi_adder_out_s,
                        f_ov => open,
                        f_z => open
		);

        -- Speed up register. Combinational path formed by pi_int -> pi_adder
        -- -> freq2phase combinational logic at input is TOO long
        pi_out_reg_i : entity work.reg(alg)
                generic map (
                        width => PIPELINE_WIDTH + 2)
                port map (
                        clk => clk,
                        we  => '1',
                        rst => rst,
                        i(PIPELINE_WIDTH - 1 downto 0) => pi_adder_out_s,
                        i(PIPELINE_WIDTH) => pi_done_s,
                        i(PIPELINE_WIDTH + 1) => pi_delayed_done_s,
                        o(PIPELINE_WIDTH - 1 downto 0) => pi_adder_out_REG_s,
                        o(PIPELINE_WIDTH) => pi_done_REG_s,
                        o(PIPELINE_WIDTH + 1) => pi_delayed_done_REG_s);
        
	freq2phase_i : entity work.freq2phase(beh)
                generic map (
                        width => PIPELINE_WIDTH,
                        delayer_width => 2)
		port map (
			clk => clk, rst => rst,
			f => pi_adder_out_REG_s,
			p => phase_s,
                        run_en => pi_done_REG_s,
                        run_passthru => open,
                        delayer_in(0) => '-',
                        delayer_in(1) => pi_delayed_done_REG_s,
                        delayer_out(0) => garbage_3_s,
                        delayer_out(1) => freq2phase_delayed_done_s);

	phase <= phase_s;
        done <= freq2phase_delayed_done_s and phase_det_done_s;
        phase_det_run_s <= run and freq2phase_delayed_done_s and phase_det_done_s;
end alg;
