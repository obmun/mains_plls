--------------------------------------------------------------------------------
-- Company: Universidad de Vigo
-- Engineer: Jacobo Cabaleiro
--
-- Create Date:    
-- Design Name:    
-- Module Name:    freq2phase - alg
-- Project Name:   
-- Target Device:  
-- Tool versions:  
--
-- *** BRIEF DESCRIPTION ***
-- Class: sequential.
-- Entity that transforms freq + phase error info to instant phase for
-- normalized signal generation. Return angle is in range - PI < angle <= PI
-- Works on rising clock edge and has synchronous reset.
-- 
-- *** DESCRIPTION ***
-- 
-- Internally this element is a modified integrator that cannot "get"
-- due to the "PI module" limited cycled output, so a RST signal is not
-- needed. It's still implemented in case user wants to set the element in a
-- known state.
-- 
-- ** PORT DESCRIPTION **
-- rst -> synchronous reset signal
-- 
-- ** IMPLEMENTATION **
-- Why return between (-PI, PI] and not [0, 2PI)? It must be done this way and
-- not with a normal integrator for two reasons:
-- -> Output angle abs value must be limited to 0 < abs < PI. Other-
--    wise pipeline path can get saturated (PI = 3.14!!, 2*PI = 6, we're
--    magnitude limited)
-- -> We require central freq. offset to be sumed and later integrated.
--    But central freq = 50 * 2 * PI >> max available magnitude!!!!
--    2*pi*50 = 314.16
--    Solution (lets supose Fs = 10 Khz): 2*pi*50 * SAMPLE_PERIOD = 0.031416!!!!
-- 
-- ** SPEED **
-- There is a big combinational depth in the path fa -> pi_kp -> freq2phase.
-- Must be corrected outside this element.
--
-- Dependencies:
-- 
-- *** Revision ***
-- Revision 0.05 - Added new seq. block control iface. Removed the speed up register.
-- Revision 0.04 - Added run / done style ports
-- Revision 0.03 - Integrated extra register to achieve better peformance (this had a hot path with
--                 to much logic levels).
-- Revision 0.02 - Integrated central freq., mixed with Tp mul to avoid overflow of data path
-- Revision 0.01 - First version
--
-- *** TODO ***
--
--------------------------------------------------------------------------------
library IEEE;
use WORK.COMMON.all;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity freq2phase is
        -- rev 0.04
	generic (
		width : natural := PIPELINE_WIDTH;
                -- Seq. block iface
                delayer_width : natural := 1);
        
	port (
		clk, rst : in std_logic;
		f : in std_logic_vector(width - 1 downto 0);
		p : out std_logic_vector(width - 1 downto 0);
                run_en : in std_logic;
                run_passthru : out std_logic;
                delayer_in : in std_logic_vector(delayer_width - 1 downto 0);
                delayer_out : out std_logic_vector(delayer_width - 1 downto 0));
end freq2phase;

architecture beh of freq2phase is       -- behavioural
        -- Component declarations
        component kcm is
                generic (
                        width : natural := PIPELINE_WIDTH;
                        prec : natural := PIPELINE_PREC;
                        -- Cte de ejemplo. Una síntesis de esta cte infiere un multiplicador
                        k : pipeline_integer := EXAMPLE_VAL_FX316);
                port (
                        i : in std_logic_vector(width - 1 downto 0);
                        o : out std_logic_vector(width - 1 downto 0));
        end component;
    
        component adder is
                generic (
                        width : natural := PIPELINE_WIDTH);
                port (
                        a, b: in std_logic_vector(width - 1 downto 0);
                        o: out std_logic_vector(width - 1 downto 0);
                        f_ov, f_z: out std_logic);
        end component;

	component k_gt_comp is
		generic (
			width : natural := PIPELINE_WIDTH;
			k : pipeline_integer := 0);
		port (
			a : in std_logic_vector(width - 1 downto 0);
			a_gt_k : out std_logic);
	end component;

	component reg is
		generic (
			width : natural := PIPELINE_WIDTH);
		port (
			clk, we, rst : in std_logic;
			i : in std_logic_vector (width - 1 downto 0);
			o : out std_logic_vector (width - 1 downto 0));
	end component;
        
	component k_2pi_sub is
		generic (
			width : natural := PIPELINE_WIDTH);
		port (
			i : in std_logic_vector(width - 1 downto 0);
			en : in std_logic;
			o : out std_logic_vector(width - 1 downto 0));
	end component;

        -- Signals
        signal gt_pi : std_logic;
        signal reg_out, speed_reg_out, kcm_out, fb_adder_out, in_adder_out, pi_limit_out : std_logic_vector(width - 1 downto 0);
        signal delayer_in_s, delayer_out_s : std_logic_vector(delayer_width - 1 downto 0);

begin
	k_gt_comp_i : k_gt_comp
		generic map (
			k => PI_FX316
		)
		port map (
			a => fb_adder_out,
			a_gt_k => gt_pi
		);

	kcm_i : kcm
		generic map (
			k => SAMPLE_PERIOD_FX316
		)
		port map (
			i => f,
			o => kcm_out
		);

	in_adder : adder
		port map (
			a => f,
			b => std_logic_vector(AC_FREQ_SAMPLE_SCALED_FX316_S),
			o => in_adder_out
		);

	fb_adder : adder
		port map (
			a => in_adder_out,
			b => reg_out,
			o => fb_adder_out
		);

	reg_i : reg
		port map (
			clk => clk, we => run_en, rst => rst,
			i => pi_limit_out, o => reg_out
		);

	k_2pi_sub_i : k_2pi_sub
		port map (
			en => gt_pi,
			i => fb_adder_out,
			o => pi_limit_out
		);

        delayer : reg
                generic map (
                        width => delayer_width)
		port map (
			clk => clk, we => '1', rst => rst,
			i => delayer_in_s,
			o => delayer_out_s);

        single_delayer_gen: if (delayer_width = 1) generate
                delayer_in_s(0) <= run_en;
                run_passthru <= std_logic(delayer_out_s(0));
                delayer_out(0) <= delayer_out_s(0);
        end generate single_delayer_gen;

        broad_delayer_gen: if (delayer_width > 1) generate
                delayer_in_s(0) <= run_en;
                delayer_in_s(delayer_width - 1 downto 1) <= delayer_in(delayer_width - 1 downto 1);
                run_passthru <= std_logic(delayer_out_s(0));
                delayer_out <= delayer_out_s;
        end generate broad_delayer_gen;
                
	p <= reg_out;

end beh;
