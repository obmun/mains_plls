--------------------------------------------------------------------------------
-- *** Brief description ***
--
-- Special "AND" for done pulses. This block generates a 1 cycle pulse at its ouput just once a
-- "pulse" has been received on every input (that is, every input has been at level 1 for 1 clock
-- cycle)
--
-- Used for simple syncronization of parallel run\_passthru interfaces.
--
-- *** Description ***
--
-- Output is going to stay LOW for at least 1 cycle after the pulse
--
-- *** Changelog ***
--
-- Revision 0.01 - File Created
--
-- *** TODO ***
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;


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
