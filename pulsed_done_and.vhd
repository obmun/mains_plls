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
use IEEE.STD_LOGIC_1164.all;


--! @brief Special "AND" for done pulses.
--!
--! This block generates a 1 cycle pulse at its ouput just once a
--! "pulse" has been received on every input (that is, every input has been at level 1 for 1 clock
--! cycle)
--!
--! Used for simple syncronization of parallel run\_passthru interfaces.
--!
--! Output is going to stay LOW for at least 1 cycle after the pulse
entity pulsed_done_and is
     generic (
          width : natural := 2);
     port (
          clk : in  std_logic;
          rst : in  std_logic;
          i   : in  std_logic_vector(width - 1 downto 0);
          o   : out std_logic);
end entity pulsed_done_and;


architecture beh of pulsed_done_and is
     signal i_s, i_reg : std_logic_vector(width - 1 downto 0);
     signal i_anded_s : std_logic;
     signal o_s, o_reg_s : std_logic;
begin  -- architecture beh
     i_s_gen : for j in 0 to (width - 1) generate
          i_s(j) <= (i(j) and not i_reg(j)) or i_reg(j);
     end generate;

     reg : process(clk, i_s, rst, o_s)
     begin
          if (rising_edge(clk)) then
               if (rst = '1') then
                    i_reg <= (others => '0');
               elsif (o_s = '1') then
                    i_reg <= (others => '0');
               else
                    i_reg <= i_s;
               end if;
          end if;
     end process;

     i_anded_s_gen : process(i_s)
          variable res : std_logic;
     begin
          res := '1';
          for j in 0 to width - 1 loop
               res := res and i_s(j);
          end loop;
          i_anded_s <= res;
     end process;

     o_s <= i_anded_s and not o_reg_s;
     o <= o_s;

     o_reg : process(clk, rst, o_s)
     begin
          if rising_edge(clk) then
               if (rst = '1') then
                    o_reg_s <= '0';
               else
                    o_reg_s <= o_s;
               end if;
          end if;
     end process;
end architecture beh;
