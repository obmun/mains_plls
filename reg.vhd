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
use WORK.COMMON.all;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;


--! @brief Register with synchronous reset
entity reg is
     generic (
          width : natural := PIPELINE_WIDTH
          );
     port (
          clk, we, rst : in std_logic;
          i : in std_logic_vector (width - 1 downto 0);
          o : out std_logic_vector (width - 1 downto 0));
end reg;


architecture alg of reg is
     signal mem : std_logic_vector(width - 1 downto 0) := (others => '0');
begin
     process(clk)
     begin
          if (rising_edge(clk)) then
               if (rst = '1') then
                    mem <= (others => '0');
               else
                    if (we = '1') then
                         mem <= i;
                    end if;
               end if;
          end if;
     end process;
     
     o <= mem;
end alg;
