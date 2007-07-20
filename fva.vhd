--------------------------------------------------------------------------------
-- Company: UVigo
-- Engineer: Jacobo Cabaleiro
--
-- Create Date:    
-- Design Name:    
-- Module Name:    fva - alg
-- Project Name:  
-- Target Device:  
-- Tool versions: 
--
-- *** SPECS ***
-- Latency: 1 clk [when waken up] / 0 clks
-- Troughoutput: 1 sample / cycle
-- 
-- *** BRIEF DESCRIPTION ***
-- VA, with configurable frequency thru generic port.
-- Works on clock's rising edge and has synchronous reset.
-- 
-- *** DESCRIPTION ***
-- Includes a synchronous reset because makes use of a saturable integrator.
-- This way a user can reset internal elements to a known state. Big storage
-- (FIFO) is never reseted.
-- Has run / done ports, so it can be easily integrated with any other
-- iterative / sequential algorithms.
--
-- ** DONE / RUN iface **
-- OK... run/done ports are a "little" different from what real run/done ports
-- are in cordic or other "big" sequential machines. The reason is that here,
-- ONCE you tell it to run, DURING that first run cycle the new output value is
-- ALREADY ready => once you tell it to run, done will go high. So if run is
-- held continuously, done will be at 1 continuously. The worst part of this
-- is that, theorically, done should go down at least at "a little moment" when
-- we tell it to run. WHY? Because WE NEED IT to propagate the run signal.
-- Otherwise, if we chain done signal thru the done_pulser, there is no way
-- "done pulsed" = "next element run signal" goes high again!! => we couldn't
-- propagate the done.
--
-- For this reason, the behaviour of the run / done ports here IS NOT REAL.
-- When stopped, DONE = 0 (false behaviour, as it should mantain the real value). When running, DONE = 1 (real behaviour).
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.02 - Added run / done style PORTS for syncronization with other sequential algorithms.
-- Revision 0.01 - File Created
--
-- Todo:
-- | 1.- REVIEW SINTHESIS!!!
-- | 2.- Correctly implement RST behaviour!!!
--------------------------------------------------------------------------------

library IEEE;
library WORK;
use WORK.COMMON.all;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity fva is
        -- rev 0.02
        generic (
                width : natural := PIPELINE_WIDTH);
	port (
		en, clk, rst : in std_logic;
		i : in std_logic_vector (width - 1 downto 0);
		o : out std_logic_vector (width - 1 downto 0);
                run : in std_logic;
                done : out std_logic);
end fva;

architecture alg of fva is
	signal kcm_out_s : std_logic_vector(width - 1 downto 0);
	signal int_out_s : std_logic_vector(width - 1 downto 0);
	signal fifo_out_s : std_logic_vector(width - 1 downto 0);
        
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

	component fifo is
		generic (
			width : natural := 16;
			size : natural := 400
		);
		port (
			clk, we : in std_logic;
			i : in std_logic_vector(width - 1 downto 0);
			o : out std_logic_vector(width - 1 downto 0)
		);
	end component;

	component adder is
		generic (
			width : natural := PIPELINE_WIDTH);
		port (
			a, b: in std_logic_vector(width - 1 downto 0);
			o: out std_logic_vector(width - 1 downto 0);
			f_ov, f_z: out std_logic);
	end component;

        type state_t is (ST_STOP, ST_RUN);
        signal st : state_t;
        signal we_s : std_logic;
begin
        int_i : kcm_integrator
		generic map (
			k => AC_FREQ_SAMPLE_SCALED_FX316)
		port map (
			i => i,
			o => int_out_s,
			clk => clk, en => we_s, rst => rst,
                        -- RUN/DONE iface in this component is "bridged" and unused.
                        run => '1',
                        done => open);

	fifo_i : fifo
		-- generic map (
		-- )
		port map (
			i => int_out_s,
			o => fifo_out_s,
			clk => clk, we => we_s);

	add_i : adder
		-- generic map (
		-- )
		port map (
			a => int_out_s,
			b => fifo_out_s,
			o => o,
                        -- Unconneted
                        f_ov => open,
                        f_z => open);

        st_ctrl : process(clk)
        begin
            if rising_edge(clk) then
                if (en = '1') then
                    if (rst = '1') then
                        st <= ST_STOP;
                    else
                        case st is
                            when ST_STOP =>
                                if (run = '1') then
                                    st <= ST_RUN;
                                else
                                    st <= ST_STOP;
                                end if;
                            when ST_RUN =>
                                if (run = '1') then
                                    st <= ST_RUN;
                                else
                                    st <= ST_STOP;
                                end if;
                            when others => null;
                        end case;  
                    end if;                   
                end if;
            end if;
        end process st_ctrl;

        signals_gen : process(st, en)
        begin
                case st is
                        when ST_STOP =>
                                done <= '0';
                                we_s <= '0';
                        when ST_RUN =>
                                done <= '1';
                                we_s <= en;
                        when others =>
                                null;
                end case;
        end process signals_gen;
end alg;
