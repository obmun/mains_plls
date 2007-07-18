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
-- *** Short desc ***
-- A PLL phase loop. Follows Cordic signals interface (RUN/DONE iface)
--
-- *** Description ***
-- Has: synchronous reset.
-- ** PORT DESCRIPTION **
-- rst -> Synchronous reset port. A reset ONLY initializes some seq elements to a initial known state, but does not reset some big internal storage elements as buffers (see FA). It's stupid as the presence of a FA will always mean that a big initial # of samples are needed to obtain stable output.
-- ** ABOUT STATES AND CYCLES **
-- It takes Cordic cycles to get a new value.
-- Chronograph:
-- 0 : This = ST_RUNNING, Cordic = ST_LAST, Cordic_out = old, Tell_Cordic_to_run (AS WE ALREADY HAVE A NEW PHASE VALUE BASED ON LAST CORDIC WAITING ON IT'S INPUT!!)
-- 1 : This = ST_LAST, Cordic = ST_RUNNING, Cordic_out = new, Tell_rest_to_run (cannot be done before as we don't have Cord out till next clk)
-- 2 : This = ST_DONE | ST_RUNNING, Cordic = ST_RUNNING, Cordic_out = new, Rest_out = OK, we have new value!
-- Dependencies:
-- 
-- TODO:
-- | > Check if reset can be made synchronous
--
-- Revision:
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
                -- rev 0.01
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

	component freq2phase is
                -- rev 0.04
                generic (
                        width : natural := PIPELINE_WIDTH);
                port (
                        clk, en, rst : in std_logic;
                        f : in std_logic_vector(width - 1 downto 0);
                        p : out std_logic_vector(width - 1 downto 0);
                        run : in std_logic;
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

	component kcm is
		generic (
			width : natural := PIPELINE_WIDTH;
			prec : natural := PIPELINE_PREC;
			k : pipeline_integer := -23410 -- Cte de ejemplo. Una síntesis de esta cte infiere un multiplicador
		);
		port (
			i : in std_logic_vector(width - 1 downto 0);
			o : out std_logic_vector(width - 1 downto 0)
		);
	end component;

	component kcm_integrator is
                -- rev 0.01
                generic (
                        width : natural := PIPELINE_WIDTH;
                        prec : natural := PIPELINE_PREC;
                        k : pipeline_integer := EXAMPLE_VAL_FX316);
                port (
                        clk, en, rst : in std_logic;
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
        signal phase_det_done_s, fva_done_s, pi_done_s, freq2phase_done_s : std_logic;
        signal phase_det_run_s : std_logic;
	-- > PI signals
	signal i_kcm_out_s, p_kcm_out_s, pi_int_out_s, pi_adder_out_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
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

	fva_i : fva
		port map (
			en => '1', clk => clk, rst => rst,
			i => phase_det_out_s,
			o => fa_out_s,
                        run => phase_det_done_s,
                        done => fva_done_s);

	-- PI filter components
	pi_p_kcm : kcm
		generic map (
			k => PHASE_LOOP_PI_P_CONST
		)
		port map (
			i => fa_out_s,
			o => p_kcm_out_s);

	pi_int : kcm_integrator
		generic map (
			k => PHASE_LOOP_PI_I_CONST_SAMPLE_SCALED)
		port map (
			clk => clk, en => '1', rst => rst,
                        run => fva_done_s,
			i => fa_out_s,
			o => pi_int_out_s,
                        done => pi_done_s);

	pi_adder : adder
		port map (
			a => pi_int_out_s,
			b => p_kcm_out_s,
			o => pi_adder_out_s,
                        f_ov => open,
                        f_z => open
		);

	-- Semi "DCO"
	freq2phase_i : freq2phase
		port map (
			clk => clk, en => '1', rst => rst,
			f => pi_adder_out_s,
			p => phase_s,
                        run => pi_done_s,
                        done => freq2phase_done_s);

	phase <= phase_s;
        done <= freq2phase_done_s;
        phase_det_run_s <= run and freq2phase_done_s;
end alg;
