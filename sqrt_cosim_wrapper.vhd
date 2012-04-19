--------------------------------------------------------------------------------
-- *** Brief description ***
--
-- Simple VHDL entity around 'sqrt' entity to be able to control entity parameters (generics) for
-- cosimulation purposes
--------------------------------------------------------------------------------

-- ** BLOCK CONFIGURATION **
package sqrt_cosim_wrapper_config is
     constant WIDTH : natural := 18; -- Hardcoded in the entity
     constant PREC : natural := 14;
end package sqrt_cosim_wrapper_config;

library work;
use work.common.all;
use work.sqrt_cosim_wrapper_config;
library ieee;
use ieee.std_logic_1164.all;


entity sqrt_cosim_wrapper is
     port (
          clk, rst, run : in std_logic;
          done, error_p : out std_logic;
          i : in std_logic_vector(sqrt_cosim_wrapper_config.WIDTH - 1 downto 0);
          o : out std_logic_vector(sqrt_cosim_wrapper_config.WIDTH - 1 downto 0));
end sqrt_cosim_wrapper;


architecture arch of sqrt_cosim_wrapper is
begin 
     sqrt_i : entity work.sqrt(alg)
          generic map (
               prec => sqrt_cosim_wrapper_config.PREC)
          port map (
               clk => clk, rst => rst,
               i => i, o => o,
               run => run, done => done, error_p => error_p);
end arch;
     
