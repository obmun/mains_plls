----------------------------------------------------------------------------------------------------
-- *** Brief description ***
--
-- Stupid wrapper around "phase_loop" entity for the purpose of generating post place and route or post
-- mapping simulation models using Xilinx ISE software
--
-- NEVER TRY TO IMPLEMENT THIS DESIGN IN THE FPGA: PIN assignment are random
----------------------------------------------------------------------------------------------------

library IEEE;
library WORK;
use WORK.COMMON.all;
use IEEE.STD_LOGIC_1164.all;

entity phase_loop_model_generation_wrapper is
     port (
          clk, rst, run : in std_logic;
          norm_input : in std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
          phase, norm_sin : out std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
          -- freq : out std_logic_vector(PIPELINE_WIDTH - 1 downto 0); I CANNOT SHOW FREQ!!!! 50 => 6 bits magnitude!!!!!!
          done : out std_logic);
end entity phase_loop_model_generation_wrapper;

architecture arch of phase_loop_model_generation_wrapper is
begin
phase_loop_i : entity work.phase_loop(alg)
     port map (
          clk        => clk,
          rst        => rst,
          run        => run,
          norm_input => norm_input,
          phase      => phase,
          norm_sin   => norm_sin,
          done       => done);
end architecture arch;
