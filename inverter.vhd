-- *** Short desc
--
-- Inverts a given vector of bits; that is, input is considered a number in 2s complement, and
-- "inverts" it so that a + (-a) = 0

library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use WORK.common.all;

entity inverter is
        generic (
                width : natural := PIPELINE_WIDTH);
        port (
                i : in  std_logic_vector(width - 1 downto 0);
                o : out std_logic_vector(width - 1 downto 0));
end inverter;

architecture beh of inverter is
begin
        o <= std_logic_vector(-signed(i));
end beh;
