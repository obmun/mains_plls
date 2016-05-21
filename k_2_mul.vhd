--------------------------------------------------------------------------------
-- *** Brief description ***
--
-- Times 2 constant multiplier. NON SATURATED!
--------------------------------------------------------------------------------
library IEEE;
use WORK.COMMON.all;
use IEEE.STD_LOGIC_1164.all;

entity k_2_mul is
	generic (
		width : natural := PIPELINE_WIDTH);
	port (
		i : in std_logic_vector(width - 1 downto 0);
		o : out std_logic_vector(width - 1 downto 0));
end k_2_mul;

architecture alg of k_2_mul is
begin
        -- This is just a shift left with sign propagation
	o(width - 1) <= i(width - 1);
	o(width - 2 downto 1) <= i(width - 3 downto 0);
	o(0) <= '0'; -- Even for negative :), already tested (easy proof)
end alg;
