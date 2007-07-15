library ieee;
use ieee.std_logic_1164.all;

entity osc_tb is
end;

architecture alg of osc_tb is
	component osc is
        generic (
            period : time
        );
        port (
            clk: out std_logic
        );
	end component;
	signal clk: std_logic;
begin
	o1 : osc generic map (50 ns) port map (clk);
end;