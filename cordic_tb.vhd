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
    component cordic is
        generic (
            width : natural := PIPELINE_WIDTH
            );
        port (
            clk, rst, run : in std_logic;
            angle : in std_logic_vector(width - 1 downto 0); -- In RADIANS!
            sin, cos : out std_logic_vector(width - 1 downto 0);
            done : out std_logic
            );
    end component;

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
    cordic_i : cordic
        generic map (
            width => 16
            )
        port map (
            clk => clk, rst => rst, run => run,
            angle => angle, sin => sin, cos => cos,
            done => done
            );

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
        angle <= std_logic_vector(to_signed(HALF_PI_FX316, 16));
        wait on done until to_x01(done) = '0';
        run <= '0';
        wait on done until to_x01(done) = '1';
-- 3rd calc cycle
        run <= '1';
        angle <= std_logic_vector(to_signed(MINUS_HALF_PI_FX316, 16));
        wait on done until to_x01(done) = '0';
        run <= '0';
        wait on done until to_x01(done) = '1';
-- 4th calc cycle
        run <= '1';
        angle <= std_logic_vector(to_signed(PI_FX316, 16));
        wait on done until to_x01(done) = '0';
        run <= '0';
        wait on done until to_x01(done) = '1';
-- 5th calc cycle
        run <= '1';
        angle <= std_logic_vector(to_signed(MINUS_PI_FX316 + 1, 16));
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
