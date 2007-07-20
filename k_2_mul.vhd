--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    11:41:50 06/16/06
-- Design Name:    
-- Module Name:    k_2_mul - alg
-- Project Name:   
-- Target Device:  
-- Tool versions:
--
-- *** Brief description ***
-- Optimal non-extended doubler for pipeline with 2s complement number representation. Be
-- careful. Result can overload!!!!
--
-- ** Description **
-- Called non extended because given a n bits input, it does not return a n + 1
-- result, so output can be overloaded if a too big value is received.
--
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
--------------------------------------------------------------------------------
library IEEE;
use WORK.COMMON.all;
use IEEE.STD_LOGIC_1164.all;

entity k_2_mul is
	generic (
		width : natural := PIPELINE_WIDTH);
	port (
		i : in std_logic_vector(width - 1 downto 0);
		o : out std_logic_vector(width - 1 downto 0));
end k_2_mul;

architecture alg of k_2_mul is
begin
        -- This is just a shift left with sign propagation
	o(width - 1) <= i(width - 1);
	o(width - 2 downto 1) <= i(width - 3 downto 0);
	o(0) <= '0'; -- Even for negative :), already tested (easy proof)
end alg;
