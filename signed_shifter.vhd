--------------------------------------------------------------------------------
-- *** Brief description ***
--
-- *** ChangeLog ***
--
-- Revision 0.02 - Let the synthesizer do more work :) Shift displacement is
-- now a natural :) (forget the pipeline_width_dir_bits)
--
-- Revision 0.01 - File Created
-- 
--------------------------------------------------------------------------------
library IEEE;
use WORK.COMMON.ALL;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity signed_r_shifter is
	generic (
		width : natural := PIPELINE_WIDTH);
	port (
		i : in std_logic_vector(width - 1 downto 0);
		n : in natural;
		o : out std_logic_vector(width - 1 downto 0));
end signed_r_shifter;

architecture beh of signed_r_shifter is
begin
	o <= std_logic_vector(shift_right(signed(i), n));
end beh;
