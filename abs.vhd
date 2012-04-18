----------------------------------------------------------------------------------------------------
-- *** Brief description ***
--
-- Calculates the absolute value of an input in 2s complement
--
----------------------------------------------------------------------------------------------------

library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use WORK.common.all;

entity absolute is
     generic (
          width : natural := PIPELINE_WIDTH);
     port (
          i : in  std_logic_vector(width - 1 downto 0);
          o : out std_logic_vector(width - 1 downto 0));
end absolute;

architecture beh of absolute is
begin
     o <= i when (i(width - 1) = '0') else std_logic_vector(-signed(i));
end beh;
