library IEEE;
use WORK.COMMON.all;
use IEEE.STD_LOGIC_1164.all;

entity freq2phase_tb is
end freq2phase_tb;

architecture beh of freq2phase_tb is
        component freq2phase is
                -- rev 0.04
                generic (
                        width : natural := PIPELINE_WIDTH);
                port (
                        clk, en, rst : in std_logic;
                        f : in std_logic_vector(width - 1 downto 0);
                        p : out std_logic_vector(width - 1 downto 0);
                        run : in std_logic;
                        done : out std_logic);
        end component freq2phase;

        constant CLOCK_PERIOD : time := 20 ns;

        signal clk_s : std_logic;
        signal en_s, rst_s : std_logic;
        signal f_s, p_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
        signal run_s, done_s : std_logic;
begin  -- beh
        clock : process
        begin
                clk_s <= '0';
                wait for CLOCK_PERIOD / 2;
                clk_s <= '1';
                wait for CLOCK_PERIOD / 2;
        end process clock;

        freq2phase_i : freq2phase
                generic map (
                        width => PIPELINE_WIDTH)
                port map (
                        clk => clk_s,
                        en => en_s,
                        rst => rst_s,
                        run => run_s,
                        done => done_s,
                        f => f_s,
                        p => p_s);

        signal_gen : process
        begin
                -- 1st test: GENERATE A PAIR OF CYCLES
                -- What I'm testing here is JUST AN INTEGRATOR.
                -- Output range: 2 * Pi
                -- Rate (per 2 clk cycles): 50 * 2 * pi * Ts = 0.0314
                -- To cover full 2 * Pi range I would need: 2 * Pi / 0.0314 =
                -- 200 cycles.
                -- SURPRISE!!! Obviously, as 200 samples are needed to cover a
                -- full 50 Hz oscillation (obviously stupid).
                -- 200 samples, 2 clks / samples, 50 MHz clk (in this test) =>
                -- 8 us
                rst_s <= '0';
                en_s <= '1';
                run_s <= '1';
                f_s <= (others => '0');
                wait for 8 us;
        end process signal_gen;
end beh;

