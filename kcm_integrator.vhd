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
-- en -> NO THIRD STATE OUTPUT; allows to stop the integrator even if clk
-- signal keeps running
--
-- ** Estability **
-- ONE must be VERY VERY carefull with THIS thing. For example, during
-- simulation, if for some reason a XXX or UUU is stored in the final register,
-- THERE IS NO WAY of making it GO OUT of the STUPID XXX state, due to the
-- output to input feedback. IT'S esential to make a correct use of the RST signal!!!
--
-- Revision:
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
end kcm_integrator;

architecture alg of kcm_integrator is
    type state is (ST_STOP, ST_RUN);
    signal st_s : state;
    
    signal o_s : std_logic_vector(width - 1 downto 0);
    signal a : std_logic_vector(width - 1 downto 0);
    signal b : std_logic_vector(width - 1 downto 0);
    signal c : std_logic_vector(width - 1 downto 0);

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
            k : pipeline_integer := -23410); -- Cte de ejemplo. Una síntesis de esta cte infiere un multiplicador
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
			clk => clk, we => en, rst => rst,
			i => i, o => a);
        
	d_i2 : reg
		generic map (
			width => width)
		port map (
			clk => clk, we => en, rst => rst,
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

        st_ctrl : process(clk)
        begin
            if (rising_edge(clk)) then
                if (en = '1') then
                    if (rst = '1') then
                        st_s <= ST_STOP;
                    else
                        case st_s is
                            when ST_STOP =>
                                if (run = '1') then
                                    st_s <= ST_RUN;
                                else
                                    st_s <= ST_STOP;
                                end if;
                            when ST_RUN =>
                                if (run = '1') then
                                    st_s <= ST_RUN;
                                else
                                    st_s <= ST_STOP;
                                end if;
                            when others =>
                                null;
                        end case;
                    end if;
                end if;
            end if;
        end process st_ctrl;
        
        signal_gen : process(st_s)
        begin
            case st_s is
                when ST_STOP =>
                    done <= '0';
                when ST_RUN =>
                    done <= '1';
                when others =>
                    null;
            end case;
        end process signal_gen;
            
end alg;
