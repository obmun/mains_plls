--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    00:07:10 06/20/06
-- Design Name:    
-- Module Name:    ctr_test - alg
-- Project Name:   
-- Target Device:  
-- Tool versions:  
-- Description:
-- Just a stupid ctr entity to test Xilinx ISE and Modelsim integration (even Matlab)
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity ctr_test is
	port (
		clk, rst : in std_logic;
		o : out std_logic_vector(15 downto 0)
	);
end ctr_test;

architecture alg of ctr_test is
begin
	ctrl : process(clk)
		variable val : signed(15 downto 0);
	begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				val := (others => '0');
			else
				val := val + 1;
			end if;
		end if;
		o <= std_logic_vector(val);
	end process;
end alg;
