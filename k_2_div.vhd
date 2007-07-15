--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    11:31:38 06/16/06
-- Design Name:    
-- Module Name:    k_2_div - alg
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

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity k_2_div is
	generic (
		width : natural := PIPELINE_WIDTH
	);
	port (
		i : in std_logic_vector(width - 1 downto 0);
		o : out std_logic_vector(width - 1 downto 0)
	);
end k_2_div;

architecture alg of k_2_div is
begin
	o(width - 1) <= i(width - 1);
	o(width - 2) <= i(width - 1);
	o(width - 3 downto 0) <= i(width - 2 downto 1);
end alg;