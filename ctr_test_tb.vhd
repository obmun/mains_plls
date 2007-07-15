--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    00:25:00 06/20/06
-- Design Name:    
-- Module Name:    ctr_test_tb - alg
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
use WORK.all;
use IEEE.STD_LOGIC_1164.ALL;


entity ctr_test_tb is
end ctr_test_tb;

architecture alg of ctr_test_tb is
	component ctr_test
		port (
			clk, rst : in std_logic;
			o : out std_logic_vector(15 downto 0)
		);
	end component;

	signal clk, rst : std_logic;
	signal data : std_logic_vector(15 downto 0);
begin
	ctr_test_i : ctr_test
		port map (
			clk => clk,
			rst => rst,
			o => data
		);
end alg;
