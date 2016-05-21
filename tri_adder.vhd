--------------------------------------------------------------------------------
-- TODO:
-- | 1.- Check if overflow flags are necesary. Maybe during debug, but NOT in final production.
-- | 2.- Implement overflow detection at ALL!!!
--------------------------------------------------------------------------------

library IEEE;
use WORK.COMMON.all;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity tri_adder is
        -- rev 0.01
	generic (
		width : natural := PIPELINE_WIDTH);
	port (
		a, b, c: in std_logic_vector(width - 1 downto 0);
		o: out std_logic_vector(width - 1 downto 0);
		f_ov, f_z: out std_logic);
end tri_adder;

architecture beh of tri_adder is
begin
	process(a, b, c)
	begin
		o <= std_logic_vector(signed(a) + signed(b) + signed(c));
	end process;
end architecture beh;
