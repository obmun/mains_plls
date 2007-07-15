--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    04:49:34 05/05/06
-- Design Name:    
-- Module Name:    add_add - alg
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
-- TODO:
-- | 1.- Check if overflow flags are necesary. Maybe during debug, but NOT in final production.
-- | 2.- Implement overflow detection at ALL!!!
--------------------------------------------------------------------------------

library IEEE;
use WORK.COMMON.all;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity adder is
	generic (
		width : natural := PIPELINE_WIDTH
	);
	port (
		a, b: in std_logic_vector(width - 1 downto 0);
		o: out std_logic_vector(width - 1 downto 0);
		f_ov, f_z: out std_logic
	);
end adder;

architecture alg of adder is
begin
	process(a, b)
	begin
		o <= std_logic_vector(signed(a) + signed(b));
	end process;
end architecture alg;