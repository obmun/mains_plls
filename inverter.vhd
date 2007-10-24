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
