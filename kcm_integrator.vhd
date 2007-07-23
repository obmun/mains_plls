--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    
-- Design Name:    
-- Module Name:    integrator - alg
-- Project Name:   
-- Target Device:  
-- Tool versions:  
-- Description:
--
-- *** SPECS ***
-- Latency: 0 cycles [each time the a new value is given, the ouput value is updated]
-- Throughoutput: 1 sample / cycle
--
-- *** BRIEF DESCRIPTION ***
-- Discrete integrator (from continuous integrator using invariant
-- impulse response transform; forward Euler integration) with sync reset
-- 
-- *** DESCRIPTION ***
-- Implements the expression:
-- y[n] = y[n - 1] + K * x[n - 1]
--
-- Integrator which exposes the integrated kcm so it's constant can be set to
-- a specific value. Includes a synchronous reset in case of saturation condition
-- achieved and a manual reset is wanted.
--
-- ** RATIONALE **
-- If kcm is not touched and system Ts is used, PRECISION problems arise.
-- I always recommend using an integrator with a previous hi gain (at least 30) constant multiplier.
-- Set constant multiplier to Ts*<your_value>
-- Works in clock's rising edge. Has synchronous reset.
--
-- ** PORTS **
-- rst -> sync reset: set's internal register to 0.
-- clk -> clk input
-- run_en -> NO THIRD STATE OUTPUT; allows to stop the integrator even if clk
-- signal keeps running
--
-- ** Estability **
-- ONE must be VERY VERY carefull with THIS thing. For example, during
-- simulation, if for some reason a XXX or UUU is stored in the final register,
-- THERE IS NO WAY of making it GO OUT of the STUPID XXX state, due to the
-- output to input feedback. IT'S esential to make a correct use of the RST signal!!!
--
-- Revision:
-- Revision 0.02 - Addition of new seq. block control iface.
-- Revision 0.01 - File Created, derived from rev 0.02 of integrator
--
-- TODO:
--------------------------------------------------------------------------------
library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use WORK.COMMON.all;

entity kcm_integrator is
        -- rev 0.02
        generic (
                width : natural := PIPELINE_WIDTH;
                prec : natural := PIPELINE_PREC;
                k : pipeline_integer := EXAMPLE_VAL_FX316;
                -- Seq. block iface
                delayer_width : natural := 1);
        port (
                clk, rst : in std_logic;
                i : in std_logic_vector (width - 1 downto 0);
                o : out std_logic_vector (width - 1 downto 0);
                run_en : in std_logic;
                run_passthru : out std_logic;
                delayer_in : in std_logic_vector(delayer_width - 1 downto 0);
                delayer_out : out std_logic_vector(delayer_width - 1 downto 0));
end kcm_integrator;

architecture beh of kcm_integrator is
    signal o_s : std_logic_vector(width - 1 downto 0);
    signal a : std_logic_vector(width - 1 downto 0);
    signal b : std_logic_vector(width - 1 downto 0);
    signal c : std_logic_vector(width - 1 downto 0);

    signal delayer_in_s, delayer_out_s : std_logic_vector(delayer_width - 1 downto 0);

    component reg is
        generic(
            width : natural := 16);
        port(
            clk, we, rst : in std_logic;
            i : in std_logic_vector (width - 1 downto 0);
            o : out std_logic_vector (width - 1 downto 0));
    end component;
    
    component kcm is
        generic(
            width : natural := PIPELINE_WIDTH;
            prec : natural := PIPELINE_PREC;
            k : pipeline_integer := -23410); -- Cte de ejemplo. Una s�ntesis de esta cte infiere un multiplicador
        port(
            i : in std_logic_vector(width - 1 downto 0);
            o : out std_logic_vector(width - 1 downto 0));
    end component;

    component adder is
            -- rev 0.01
            generic (
                    width : natural := PIPELINE_WIDTH);
            port (
                    a, b: in std_logic_vector(width - 1 downto 0);
                    o: out std_logic_vector(width - 1 downto 0);
                    f_ov, f_z: out std_logic);
    end component;
begin
	d_i1 : reg
		generic map (
			width => width)
		port map (
			clk => clk, we => run_en, rst => rst,
			i => i, o => a);
        
	d_i2 : reg
		generic map (
			width => width)
		port map (
			clk => clk, we => run_en, rst => rst,
			i => o_s, o => c);
        
	kcm_i : kcm
		generic map (
			width => width,
			prec => prec,
			k => k)
		port map (
			i => a,
			o => b);

	add_add_i : adder
		generic map (
			width => width)
		port map (
			a => b,
			b => c,
			o => o_s);

        o <= o_s;

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

end beh;
