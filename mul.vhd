--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    
-- Design Name:    
-- Module Name:    mul - alg
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
use WORK.COMMON.all;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity mul is
        -- rev 0.01
	generic (
		width : natural := PIPELINE_WIDTH;
		prec_bits : natural := PIPELINE_PREC);
	port (
		a, b : in std_logic_vector (width - 1 downto 0);
		o : out std_logic_vector (width - 1 downto 0));
end mul;

architecture alg of mul is
begin
	process(a, b)
	begin
		o <= std_logic_vector(resize(shift_right(signed(a) * signed(b), prec_bits), width));
	end process;
end alg;
