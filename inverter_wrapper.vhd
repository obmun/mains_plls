-- *** Brief description ***
-- Simple VHDL entity around 'inverter' to be able to control entity parameters for synthesis tests

-- ** BLOCK CONFIGURATION **
package inverter_wrapper_config is
     constant WIDTH : integer := 16;
end package inverter_wrapper_config;

library work;
use work.common.all;
use work.inverter_wrapper_config;
library ieee;
use ieee.std_logic_1164.all;

entity inverter_wrapper is
     port (
          i : in std_logic_vector(inverter_wrapper_config.WIDTH - 1 downto 0);
          o : out std_logic_vector(inverter_wrapper_config.WIDTH - 1 downto 0));
end inverter_wrapper;

architecture arch of inverter_wrapper is
begin 
     inv_i : entity work.inverter
          generic map (
               width => inverter_wrapper_config.WIDTH)
          port map (
               i => i,
               o => o);
end arch;
