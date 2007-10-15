--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    19:20:59 06/15/06
-- Design Name:    
-- Module Name:    k_gt_comp - beh
-- Project Name:   
-- Target Device:  
-- Tool versions:  
-- Description:
-- Greater than comparator with constant comparison value
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
--------------------------------------------------------------------------------
library IEEE;
use WORK.COMMON.all;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity k_gt_comp is
	generic (
		width : natural := PIPELINE_WIDTH;
                prec : natural := PIPELINE_PREC;
		k : real);
	port (
		a : in std_logic_vector(width - 1 downto 0);
		a_gt_k : out std_logic);
end k_gt_comp;

architecture beh of k_gt_comp is
begin
	process(a)
		constant k_signed : signed(width - 1 downto 0) := signed(to_vector(k, width, prec));
	begin
		if (signed(a) > k_signed) then
			a_gt_k <= '1';
		else
			a_gt_k <= '0';
		end if;
	end process;
end beh;
