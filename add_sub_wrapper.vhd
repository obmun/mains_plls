-- *** Brief description ***
-- Simple VHDL entity around 'add_sub' to be able to control entity parameters for synthesis tests

-- ** BLOCK CONFIGURATION **
package add_sub_wrapper_config is
     constant WIDTH : integer := 16;
end package add_sub_wrapper_config;

library work;
use work.common.all;
use work.add_sub_wrapper_config;
library ieee;
use ieee.std_logic_1164.all;

entity add_sub_wrapper is
     port (
          a, b : in std_logic_vector(add_sub_wrapper_config.WIDTH - 1 downto 0);
          add_nsub : in std_logic;
          o : out std_logic_vector(add_sub_wrapper_config.WIDTH - 1 downto 0));
end add_sub_wrapper;

architecture arch of add_sub_wrapper is
begin 
     as_i : entity work.add_sub
          generic map (
               width => add_sub_wrapper_config.WIDTH)
          port map (
               a => a, b => b,
               add_nsub => add_nsub,
               o => o,
               f_ov => open, f_z => open);
end arch;
