--------------------------------------------------------------------------------
-- *** Brief description ***
--
-- Simple VHDL entity around FA filter to be able to control entity parameters (generic) for
-- cosimulation purposes
--------------------------------------------------------------------------------

-- ** BLOCK CONFIGURATION **
package fa_cosim_wrapper_config is
     constant WIDTH : natural := 16;
     constant PREC : natural := 13;
     constant DELAY : natural := 200;
end package fa_cosim_wrapper_config;

library work;
use work.common.all;
use work.fa_cosim_wrapper_config;
library ieee;
use ieee.std_logic_1164.all;


entity fa_cosim_wrapper is
     port (
          clk, rst, run_en : in std_logic;
          run_passthru : out std_logic;
          i : in std_logic_vector(fa_cosim_wrapper_config.WIDTH - 1 downto 0);
          o : out std_logic_vector(fa_cosim_wrapper_config.WIDTH - 1 downto 0));
end fa_cosim_wrapper;


architecture arch of fa_cosim_wrapper is
begin 
     fa_i : entity work.fa(beh)
          generic map (
               width => fa_cosim_wrapper_config.WIDTH,
               prec => fa_cosim_wrapper_config.PREC,
               delay => fa_cosim_wrapper_config.DELAY)
          port map (
               clk => clk, rst => rst,
               i => i, o => o,
               run_en => run_en, run_passthru => run_passthru,
               delayer_in(0) => '-', delayer_out => open);
end arch;
