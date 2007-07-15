--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    20:33:57 05/04/06
-- Design Name:    
-- Module Name:    adder_test - Behavioral
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
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity adder_test is
	port (
		a, b: in std_logic_vector(15 downto 0);
		o: out std_logic_vector(15 downto 0);
		f_ov, f_z: out std_logic
	);
end adder_test;

architecture alg of adder_test is
begin
	process(a, b)
		-- Declaraciones de variables o señales (en el proceso?)
	begin
		o <= a + b;
	end process;
end architecture alg;