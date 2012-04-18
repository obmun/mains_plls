--------------------------------------------------------------------------------
-- *** Brief description ***
--
-- Register with synchronous reset
-- 
-- *** Changelog ***
-- | - Version bump (0.02)
-- | - output signal driver taken out of the input process
-- | - Version bump (0.01)
-- | - First implementation
--------------------------------------------------------------------------------
library IEEE;
use WORK.COMMON.all;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity reg is
     generic (
          width : natural := PIPELINE_WIDTH
          );
     port (
          clk, we, rst : in std_logic;
          i : in std_logic_vector (width - 1 downto 0);
          o : out std_logic_vector (width - 1 downto 0));
end reg;


architecture alg of reg is
     signal mem : std_logic_vector(width - 1 downto 0) := (others => '0');
begin
     process(clk)
     begin
          if (rising_edge(clk)) then
               if (rst = '1') then
                    mem <= (others => '0');
               else
                    if (we = '1') then
                         mem <= i;
                    end if;
               end if;
          end if;
     end process;
     
     o <= mem;
end alg;
