-- *** Brief description ***
-- Simple VHDL entity around adder to be able to control entity parameters for synthesis tests

-- ** BLOCK CONFIGURATION **
package k_lt_comp_wrapper_cfg is
     constant WIDTH : integer := 16;
     constant PREC : integer := 12;
     constant K : real := 3.141592;
end package k_lt_comp_wrapper_cfg;

library work;
use work.common.all;
use work.k_lt_comp_wrapper_cfg;
library ieee;
use ieee.std_logic_1164.all;

entity k_lt_comp_wrapper is
     port (
          a : in std_logic_vector(k_lt_comp_wrapper_cfg.WIDTH - 1 downto 0);
          a_lt_k : out std_logic);
end k_lt_comp_wrapper;

architecture arch of k_lt_comp_wrapper is
begin 
     comp_i : entity work.k_lt_comp
          generic map (
               width => k_lt_comp_wrapper_cfg.WIDTH,
               prec => k_lt_comp_wrapper_cfg.PREC,
               k => k_lt_comp_wrapper_cfg.K)
          port map (
               a => a,
               a_lt_k => a_lt_k);
end arch;
