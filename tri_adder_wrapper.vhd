-- *** Brief description ***
-- Simple VHDL entity around adder to be able to control entity parameters for synthesis tests

-- ** BLOCK CONFIGURATION **
package wrapper_config is
     constant WIDTH : integer := 5;
end package wrapper_config;

library work;
use work.common.all;
use work.wrapper_config;
library ieee;
use ieee.std_logic_1164.all;

entity tri_adder_wrapper is
     port (
          a, b, c : in std_logic_vector(wrapper_config.WIDTH - 1 downto 0);
          o : out std_logic_vector(wrapper_config.WIDTH - 1 downto 0));
end tri_adder_wrapper;

architecture arch of tri_adder_wrapper is
begin 
     i : entity work.tri_adder
          generic map (
               width => wrapper_config.WIDTH)
          port map (
               a => a, b => b, c => c,
               o => o,
               f_ov => open, f_z => open);
end arch;
