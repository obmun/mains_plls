--------------------------------------------------------------------------------
-- *** Brief description ***
--
-- Class: combinational.
--
-- Divisor by 4. That is, o = i / 4.0
-- 
--------------------------------------------------------------------------------
library IEEE;
use WORK.COMMON.all;
use IEEE.STD_LOGIC_1164.all;


entity k_4_div is
     generic (
          width : natural := PIPELINE_WIDTH);
     port (
          i : in std_logic_vector(width - 1 downto 0);
          o : out std_logic_vector(width - 1 downto 0));
end k_4_div;


architecture structural of k_4_div is
begin
     o(width - 1) <= i(width - 1);
     o(width - 2) <= i(width - 1);
     o(width - 3) <= i(width - 1);
     o(width - 4) <= i(width - 1);
     o(width - 5 downto 0) <= i(width - 2 downto 3);
end structural;
