-- *** Brief description ***
-- Simple VHDL entity around adder to be able to control entity parameters for synthesis tests

-- ** BLOCK CONFIGURATION **
package adder_wrapper_config is
     constant WIDTH : integer := 16;
end package adder_wrapper_config;

library work;
use work.common.all;
use work.adder_wrapper_config;
library ieee;
use ieee.std_logic_1164.all;

entity adder_wrapper is
     port (
          a, b : in std_logic_vector(adder_wrapper_config.WIDTH - 1 downto 0);
          o : out std_logic_vector(adder_wrapper_config.WIDTH - 1 downto 0));
end adder_wrapper;

architecture arch of adder_wrapper is
begin 
     adder_i : entity work.adder
          generic map (
               width => adder_wrapper_config.WIDTH)
          port map (
               a => a, b => b,
               o => o,
               f_ov => open, f_z => open);
end arch;
