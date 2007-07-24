--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    11:19:28 06/16/06
-- Design Name:    
-- Module Name:    subsor - alg
-- Project Name:   
-- Target Device:  
-- Tool versions:  
-- Description:
-- | Calculates a - b
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
use IEEE.NUMERIC_STD.all;

entity subsor is
	generic (
		width : natural := PIPELINE_WIDTH
	);
	port (
		a, b: in std_logic_vector(width - 1 downto 0);
		o: out std_logic_vector(width - 1 downto 0);
		f_ov, f_z: out std_logic
	);
end subsor;

architecture alg of subsor is
begin
	process(a, b)
	begin
		o <= std_logic_vector(signed(a) - signed(b));
	end process;
end architecture alg;
