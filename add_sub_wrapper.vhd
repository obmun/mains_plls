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

-- ** BLOCK CONFIGURATION **
package add_sub_wrapper_config is
     constant WIDTH : integer := 16;
end package add_sub_wrapper_config;

library work;
use work.common.all;
use work.add_sub_wrapper_config;
library ieee;
use ieee.std_logic_1164.all;

--! @brief Simple VHDL entity around 'add_sub' to be able to control entity parameters for synthesis tests
entity add_sub_wrapper is
     port (
          a, b : in std_logic_vector(add_sub_wrapper_config.WIDTH - 1 downto 0);
          add_nsub : in std_logic;
          o : out std_logic_vector(add_sub_wrapper_config.WIDTH - 1 downto 0));
end add_sub_wrapper;

architecture arch of add_sub_wrapper is
begin
     as_i : entity work.add_sub
          generic map (
               width => add_sub_wrapper_config.WIDTH)
          port map (
               a => a, b => b,
               add_nsub => add_nsub,
               o => o,
               f_ov => open, f_z => open);
end arch;
