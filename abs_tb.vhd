----------------------------------------------------------------------------------------------------
-- *** Brief description ***
--
-- Functionality test bench for 'absolute' entity (abs.vhd)
--
----------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


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
