--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    20:52:31 06/15/06
-- Design Name:    
-- Module Name:    signer_shifter - beh
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
use IEEE.MATH_REAL.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity signed_r_shifter is
	generic (
		width : natural := PIPELINE_WIDTH;
		width_dir_bits : natural := PIPELINE_WIDTH_DIR_BITS
	);
	port (
		i : in std_logic_vector(width - 1 downto 0);
		n : in std_logic_vector(width_dir_bits - 1 downto 0);
		o : out std_logic_vector(width - 1 downto 0)
	);
end signed_r_shifter;

architecture beh of signed_r_shifter is
begin
	o <= std_logic_vector(shift_right(signed(i), to_integer(unsigned(n))));
end beh;
