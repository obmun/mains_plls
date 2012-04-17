-- *** Brief description ***
-- Simple VHDL entity around 'subsor' to be able to control entity parameters for synthesis tests

-- ** BLOCK CONFIGURATION **
package subsor_wrapper_config is
     constant WIDTH : integer := 16;
end package subsor_wrapper_config;

library work;
use work.common.all;
use work.subsor_wrapper_config;
library ieee;
use ieee.std_logic_1164.all;

entity subsor_wrapper is
     port (
          a, b : in std_logic_vector(subsor_wrapper_config.WIDTH - 1 downto 0);
          o : out std_logic_vector(subsor_wrapper_config.WIDTH - 1 downto 0));
end subsor_wrapper;

architecture arch of subsor_wrapper is
begin 
     subsor_i : entity work.subsor
          generic map (
               width => subsor_wrapper_config.WIDTH)
          port map (
               a => a, b => b,
               o => o,
               f_ov => open, f_z => open);
end arch;
