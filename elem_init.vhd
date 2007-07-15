--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    18:34:19 06/15/06
-- Design Name:    
-- Module Name:    elem_init - Behavioral
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
use WORK.COMMON.ALL;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity cordic_elem_init is
	generic (
		width : natural := PIPELINE_WIDTH
	);
	port (
		gt_hPI, lt_mhPI : in std_logic;
		x_init_val, y_init_val : out std_logic_vector(width - 1 downto 0)
	);	
end cordic_elem_init;

architecture beh of cordic_elem_init is
begin
	process(gt_hPI, lt_mhPI)
	begin
		if (gt_hPI = '1') then
			x_init_val <= (others => '0');
			y_init_val <= INV_CORDIC_GAIN_V;
		elsif (lt_mhPI = '1') then
			x_init_val <= (others => '0');
			y_init_val <= MINUS_INV_CORDIC_GAIN_V;
		else
			x_init_val <= INV_CORDIC_GAIN_V;
			y_init_val <= (others => '0');
		end if;
	end process;
end beh;
