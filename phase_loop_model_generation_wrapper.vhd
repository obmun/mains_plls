-- Copyright (c) 2012-2016 Jacobo Cabaleiro Cayetano
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

library IEEE;
library WORK;
use WORK.COMMON.all;
use IEEE.STD_LOGIC_1164.all;

--! @brief Stupid wrapper around "phase_loop" entity for the purpose of generating post place and route or post
--! mapping simulation models using Xilinx ISE software
--!
--! @remark NEVER TRY TO IMPLEMENT THIS DESIGN IN THE FPGA: PIN assignment are random
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
