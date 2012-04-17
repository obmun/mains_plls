--------------------------------------------------------------------------------
-- *** Brief description ***
--
-- Simple VHDL entity around freq2phase block to be able to control entity parameters (generics) for
-- cosimulation purposes
--------------------------------------------------------------------------------

-- ** BLOCK CONFIGURATION **
package freq2phase_cosim_wrapper_config is
     constant WIDTH : natural := 16;
     constant PREC : natural := 12;
     constant GAIN : real := 25.0;
end package freq2phase_cosim_wrapper_config;

library work;
use work.common.all;
use work.freq2phase_cosim_wrapper_config;
library ieee;
use ieee.std_logic_1164.all;


entity freq2phase_cosim_wrapper is
     port (
          clk, rst, run_en : in std_logic;
          run_passthru : out std_logic;
          f : in std_logic_vector(freq2phase_cosim_wrapper_config.WIDTH - 1 downto 0);
          p : out std_logic_vector(freq2phase_cosim_wrapper_config.WIDTH - 1 downto 0));
end freq2phase_cosim_wrapper;


architecture arch of freq2phase_cosim_wrapper is
begin 
     f2p_i : entity work.freq2phase(beh)
          generic map (
               width => freq2phase_cosim_wrapper_config.WIDTH,
               prec => freq2phase_cosim_wrapper_config.PREC,
               gain => freq2phase_cosim_wrapper_config.GAIN)
          port map (
               clk => clk, rst => rst,
               f => f, p => p,
               run_en => run_en, run_passthru => run_passthru,
               delayer_in(0) => '-', delayer_out => open);
end arch;
