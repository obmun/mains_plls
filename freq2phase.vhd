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
-- ** SPEED IMPLEMENTATION **
-- Problem with speed: in route fa -> pi_kp -> freq2phase there is a BIG delay.
-- To solve it a new register was added in this element so speed was increased.
-- Measurement (synthgesis clock report) showed that inserting it AFTER:
-- -> in_adder produced a phase_loop max freq of 47.5 MHz
-- -> in_kcm produced a phase_loop max freq of 55.608 MHz
-- -> in produced a phase_loop max freq of 55.608 MHz (explained as in kcm is set to X"0001"
--
-- Dependencies:
-- 
-- *** Revision ***
-- Revision 0.04 - Added run / done style ports
-- Revision 0.03 - Integrated extra register to achieve better peformance (this had a hot path with
--                 to much logic levels).
-- Revision 0.02 - Integrated central freq., mixed with Tp mul to avoid overflow of data path
-- Revision 0.01 - First version
--
-- *** TODO ***
-- * Speed up register SHOULD NOT BE INSIDE THIS FUCKING ELEMENT!!! Should be
-- outside, in the pipe. WTF was I'm thinking when I implemented this!
--
-- Additional Comments:
-- 
--------------------------------------------------------------------------------
library IEEE;
use WORK.COMMON.all;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity freq2phase is
        -- rev 0.04
	generic (
		width : natural := PIPELINE_WIDTH);
	port (
		clk, en, rst : in std_logic;
		f : in std_logic_vector(width - 1 downto 0);
		p : out std_logic_vector(width - 1 downto 0);
                run : in std_logic;
                done : out std_logic);
end freq2phase;

architecture alg of freq2phase is
        type state_t is (
                ST_LOAD, ST_STORE);

        signal st : state_t;
    
        -- Component declarations
        component kcm is
                generic (
                        width : natural := PIPELINE_WIDTH;
                        prec : natural := PIPELINE_PREC;
                        k : pipeline_integer := -23410 -- Cte de ejemplo. Una síntesis de esta cte infiere un multiplicador
                        );
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
        signal speed_reg_we_s, reg_we_s : std_logic;

begin
	k_gt_comp_i : k_gt_comp
		generic map (
			k => PI_FX316
		)
		port map (
			a => fb_adder_out,
			a_gt_k => gt_pi
		);

	speed_reg_i : reg
		port map (
			clk => clk, we => speed_reg_we_s, rst => rst,
			i => f,
			o => speed_reg_out
		);

	kcm_i : kcm
		generic map (
			k => SAMPLE_PERIOD_FX316
		)
		port map (
			i => speed_reg_out,
			o => kcm_out
		);

	in_adder : adder
		port map (
			a => speed_reg_out,
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
			clk => clk, we => reg_we_s, rst => rst,
			i => pi_limit_out, o => reg_out
		);

	k_2pi_sub_i : k_2pi_sub
		port map (
			en => gt_pi,
			i => fb_adder_out,
			o => pi_limit_out
		);

	p <= reg_out;

        st_ctrl : process(clk)
        begin
                if (rising_edge(clk)) then
                        if (rst = '1') then
                                st <= ST_LOAD;
                        else
                                if (en = '1') then
                                        case st is
                                                when ST_LOAD =>
                                                        if (run = '0') then
                                                                st <= ST_LOAD;
                                                        else
                                                                st <= ST_STORE;
                                                        end if;
                                                when ST_STORE =>
                                                        st <= ST_LOAD;
                                                when others => null;
                                        end case;                     
                                end if;
                        end if;
                end if;
        end process st_ctrl;

        signal_gen : process(st)
        begin
                case st is
                        when ST_LOAD =>
                                speed_reg_we_s <= en and run;
                                reg_we_s <= '0';
                                done <= '0';
                        when ST_STORE =>
                                speed_reg_we_s <= '0';
                                reg_we_s <= en;
                                done <= '1';
                        when others => null;
                end case;
        end process signal_gen;
end alg;
