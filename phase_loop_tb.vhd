-- *** Description ***
-- Right now, stupid 

library IEEE;
use WORK.COMMON.ALL;
use IEEE.STD_LOGIC_1164.ALL;

entity phase_loop_tb is
end phase_loop_tb;

architecture beh of phase_loop_tb is
        constant CLOCK_PERIOD : time := 20 ns;

        signal clk_s, rst_s, run_s, done_s : std_logic;
        signal norm_input_s, phase_s, norm_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
begin  -- beh

        phase_loop_i : entity work.phase_loop(alg)
                port map (
                        clk => clk_s,
                        rst => rst_s,
                        run => run_s,
                        norm_input => norm_input_s,
                        phase => phase_s,
                        norm_sin => norm_s,
                        done => done_s);

        clock : process
        begin
            clk_s <= '0';
            wait for CLOCK_PERIOD / 2;
            clk_s <= '1';
            wait for CLOCK_PERIOD / 2;
        end process clock;

        signal_gen : process
        begin
                norm_input_s <= (others => '0');
                run_s <= '0';
                rst_s <= '1';
                wait on clk_s until rising_edge(clk_s);
                wait for 10 ns;
                rst_s <= '0';
                run_s <= '1';
                wait;
        end process signal_gen;

end beh;
