--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    19:35:01 06/15/06
-- Design Name:    
-- Module Name:    k_lt_comp - beh
-- Project Name:   
-- Target Device:  
-- Tool versions:  
-- Description:
-- Less than comparator with constant comparison value
-- Dependencies:
-- 
-- Revision:
-- Revision 0.02 - Simulation with ModelSim showed small problems in generic port declarations.
--                 Input comparison constant is now an INTEGER (fixed point number must be converted to integer with a shift and inserted)
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
--------------------------------------------------------------------------------
library IEEE;
use WORK.COMMON.ALL;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity k_lt_comp is
	generic (
		width : natural := PIPELINE_WIDTH;
                prec : natural := PIPELINE_PREC;
		k : real);
	port (
		a : in std_logic_vector(width - 1 downto 0);
		a_lt_k : out std_logic);
end k_lt_comp;

architecture beh of k_lt_comp is
begin
	process(a)
		constant k_signed : signed(width - 1 downto 0) := signed(to_vector(k, width, prec));
	begin
		if (signed(a) < k_signed) then
			a_lt_k <= '1';
		else
			a_lt_k <= '0';
		end if;
	end process;
end beh;
