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
use WORK.COMMON.ALL;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- @todo An adder-subtracter is obviously a very OPTIMAL structure. This shouldn't be inferring an adder
-- and a subtracter and then multiplexing output. Check synthesis. See, for example, Wikipedia entry
-- about this subject (adder-substractor)
entity add_sub is
     generic (
          width : natural := PIPELINE_WIDTH
          );
     port (
          a, b: in std_logic_vector(width - 1 downto 0);
          add_nsub : in std_logic;
          o: out std_logic_vector(width - 1 downto 0);
          f_ov, f_z: out std_logic
          );
end add_sub;

architecture alg of add_sub is
begin
     process(a, b, add_nsub)
     begin
          case add_nsub is
               when '0' =>
                    o <= std_logic_vector(signed(a) - signed(b));
               when others =>
                    o <= std_logic_vector(signed(a) + signed(b));
          end case;
     end process;
end architecture alg;
