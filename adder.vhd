--------------------------------------------------------------------------------
-- === TODO ===
-- 1.- Check if overflow flags are necesary. Maybe during debug, but NOT in final production.
--
-- 2.- Implement overflow detection at all!
--------------------------------------------------------------------------------

library IEEE;
use WORK.COMMON.all;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity adder is
        -- rev 0.01
	generic (
		width : natural := PIPELINE_WIDTH);
	port (
		a, b: in std_logic_vector(width - 1 downto 0);
		o: out std_logic_vector(width - 1 downto 0);
		f_ov, f_z: out std_logic);
end adder;

architecture alg of adder is
begin
	process(a, b)
	begin
		o <= std_logic_vector(signed(a) + signed(b));
	end process;
end architecture alg;
