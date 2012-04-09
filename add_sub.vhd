--------------------------------------------------------------------------------
-- === TODO ===
--
-- * An adder-subtracter is obviously a very OPTIMAL structure. This shouldn't be inferring an adder
-- and a subtracter and then multiplexing output. Check synthesis. See, for example, Wikipedia entry
-- about this subject (adder-substractor)
--------------------------------------------------------------------------------
library IEEE;
use WORK.COMMON.ALL;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

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
