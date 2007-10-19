--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    13:17:04 06/29/06
-- Design Name:    
-- Module Name:    spll - alg
-- Project Name:   
-- Target Device:  
-- Tool versions:  
-- Description:
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

entity p2_spll is
        -- rev 0.01
	port (
		clk, sample, rst : in std_logic;
		in_signal : in std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
		phase, out_signal : out std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
		done : out std_logic);
end p2_spll;

architecture structural of p2_spll is
	signal ampl_run_s : std_logic;
        signal ampl_done_s, phase_done_s: std_logic;
	signal our_signal_s, norm_in_signal_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
        signal tmp_mierda_s : std_logic;
begin

	ampl_loop_i : entity work.p2_ampl_loop(beh)
		port map (
			clk => clk, run => ampl_run_s, rst => rst,
			in_signal => in_signal, our_signal => our_signal_s,
			norm_in_signal => norm_in_signal_s,
			done => ampl_done_s);

        ampl_run_s <= phase_done_s and sample;
        
	phase_loop_i : entity work.p2_phase_loop(beh)
		port map (
			clk => clk, run => ampl_done_s,
                        rst => rst,
			norm_input => norm_in_signal_s,
			phase => phase, norm_sin => our_signal_s,
			done => phase_done_s);

	done <= phase_done_s;
        out_signal <= our_signal_s;
end structural;
