library ieee;
use ieee.std_logic_1164.all;

entity osc is
  generic (
    period : time
    );
  port (
    clk: out std_logic
    );
end;

architecture alg of osc is
begin
  clock : process
  begin
    clk <= '0';
    wait for period / 2;
    clk <= '1';
    wait for period / 2;
  end process clock;
end architecture;
