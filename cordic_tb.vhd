-- REVISION:
-- Revision 0.02: removed OSC component, so Xilinx correctly recognices the
-- real UUT.
-- Revision 0.01: created

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
library work;
use work.all;
use work.common.all;

entity cordic_tb is
end entity;

architecture alg of cordic_tb is

-- PROBLEM: if I include another COMPONENT inside a TB, Xilinx just thinks
-- its the UUT (Unit Under Test), so osc code must be INLINED in this
-- source file (not a problem, at all)
--    component osc is
--        generic (
--            period : time
--        );
--        port (
--            clk: out std_logic
--        );
--    end component;

    signal clk, rst, run : std_logic;
    signal angle, sin, cos : std_logic_vector(15 downto 0);
    signal done : std_logic;

    constant CLOCK_PERIOD : time := 20 ns;
begin
        cordic_i : entity work.cordic(beh)
                generic map (
                        width => 16,
                        prec => 12)
                port map (
                        clk => clk, rst => rst, run => run,
                        angle => angle, sin => sin, cos => cos,
                        done => done);

        signal_gen : process
        begin
                run <= '0';
                angle <= (others => '0');
                rst <= '1';
                wait for 30 ns;
                rst <= '0';
                wait for 75 ns;
                -- 1st calc cycle
                run <= '1';
                angle <= (others => '0');
                wait on clk until falling_edge(clk);
                -- wait on done until to_x01(done) = '0';
                run <= '0';
                wait on done until to_x01(done) = '1';
                -- 2nd calc cycle
                run <= '1';
                angle <= to_vector(HALF_PI, 16, 12);
                wait on done until to_x01(done) = '0';
                run <= '0';
                wait on done until to_x01(done) = '1';
                -- 3rd calc cycle
                run <= '1';
                angle <= to_vector(MINUS_HALF_PI, 16, 12);
                wait on done until to_x01(done) = '0';
                run <= '0';
                wait on done until to_x01(done) = '1';
                -- 4th calc cycle
                run <= '1';
                angle <= to_vector(PI, 16, 12);
                wait on done until to_x01(done) = '0';
                run <= '0';
                wait on done until to_x01(done) = '1';
                -- 5th calc cycle
                run <= '1';
                angle <= to_vector(MINUS_PI + 0.01, 16, 12);
                wait on done until to_x01(done) = '0';
                run <= '0';
                wait on done until to_x01(done) = '1';                  

                wait;
        end process;

        clock : process
        begin
                clk <= '0';
                wait for CLOCK_PERIOD / 2;
                clk <= '1';
                wait for CLOCK_PERIOD / 2;
        end process clock;
end architecture;
