--------------------------------------------------------------------------------
-- Company: UVigo
-- Engineer: Jacobo Cabaleiro
--
-- Create Date:    
-- Design Name:    
-- Module Name:    fa - beh
-- Project Name:  
-- Target Device:  
-- Tool versions: 
--
-- *** SPECS ***
-- Latency: 1 clk [when waken up] / 0 clks
-- Troughoutput: 1 sample / cycle
-- 
-- *** BRIEF DESCRIPTION ***
-- Class: sequential
-- VA, with configurable frequency (and integrator ktk) thru generic ports.
-- Works on clock's rising edge and has synchronous reset.
-- 
-- *** DESCRIPTION ***
-- Includes a synchronous reset because makes use of a saturable integrator.
-- This way a user can reset internal elements to a known state. Big storage
-- (FIFO) is never reseted.
--
-- The onboard integrator adds a delay of 1 run (sample) to the element.
-- Therefore, FIFO implemented delay must be the user desired delay minus 1.
-- Therefore: delay(samples) >= 2
-- 
-- Dependencies:
-- 
-- *** Changelog ***
-- Revision 0.03 - Implement new seq. control iface. REALLY create the generic
-- for freq. and k control, instead of just advertising it in the brief description
-- Revision 0.02 - Added run / done style PORTS for syncronization with other sequential algorithms.
-- Revision 0.01 - File Created
--
-- *** Todo ***
-- | 1.- REVIEW SINTHESIS!!!
-- | 2.- Correctly implement RST behaviour!!!
--------------------------------------------------------------------------------

library IEEE;
library WORK;
use WORK.COMMON.all;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity fa is
        -- rev 0.02
        generic (
                width : natural := PIPELINE_WIDTH;
                prec : natural := PIPELINE_PREC;
                int_k : pipeline_integer := AC_FREQ_SAMPLE_SCALED_FX316;
                delay : natural := 200; 
                -- Seq. block iface
                delayer_width : natural := 1);
	port (
		clk, rst : in std_logic;
		i : in std_logic_vector(width - 1 downto 0);
		o : out std_logic_vector(width - 1 downto 0);
                run_en : in std_logic;
                run_passthru : out std_logic;
                delayer_in : in std_logic_vector(delayer_width - 1 downto 0);
                delayer_out : out std_logic_vector(delayer_width - 1 downto 0));
end fa;

architecture beh of fa is
	signal int_out_s : std_logic_vector(width - 1 downto 0);
	signal fifo_out_s : std_logic_vector(width - 1 downto 0);
        
	component fifo is
		generic (
			width : natural := PIPELINE_WIDTH;
			size : natural := 400
		);
		port (
			clk, we : in std_logic;
			i : in std_logic_vector(width - 1 downto 0);
			o : out std_logic_vector(width - 1 downto 0)
		);
	end component;

begin
        -- This block is used as the implementation of "seq. block control iface"
        int_i : entity work.kcm_integrator(beh)
		generic map (
                        width => width,
                        prec => prec,
			k => int_k,
                        delayer_width => delayer_width)
		port map (
			i => i,
			o => int_out_s,
			clk => clk, rst => rst,
                        run_en => run_en,
                        run_passthru => run_passthru,
                        delayer_in => delayer_in,
                        delayer_out => delayer_out);

	fifo_i : fifo
		generic map (
                        width => width,
                        size => delay - 1)
		port map (
			i => int_out_s,
			o => fifo_out_s,
			clk => clk, we => run_en);

	add_i : entity work.subsor(alg)
		generic map (
                        width => width)
		port map (
			a => int_out_s,
			b => fifo_out_s,
			o => o,
                        -- Unconneted
                        f_ov => open,
                        f_z => open);

end beh;
