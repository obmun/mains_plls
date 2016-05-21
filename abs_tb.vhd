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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


--! @brief Functionality test bench for 'absolute' entity (abs.vhd)
entity absolute_tb is
end entity;


architecture beh of absolute_tb is
     constant WIDTH : natural := 16;
     constant READ_DELAY : time := 1ns;

     shared variable i : integer := -(2**(WIDTH - 1)) - 1;

     signal i_s, o_s : std_logic_vector(WIDTH - 1 downto 0);
begin
     absolute_i : entity work.absolute(beh)
          generic map (
               width => WIDTH)
          port map (
               i => i_s,
               o => o_s);

     test : process
     begin
          -- Test previous output
          if (i >= -2**(WIDTH - 1)) then
               assert (signed(o_s) = to_signed(abs(i), WIDTH)) report "ERROR in output for input " & integer'image(i) severity error;
          end if;
          -- Set new input
          if i < 2**(WIDTH - 1) then
               i := i + 1;
          else
               report "Simulation finished" severity note;
               wait;
          end if;
          i_s <= std_logic_vector(to_signed(i, WIDTH));
          wait for READ_DELAY;
     end process;
end architecture beh;
