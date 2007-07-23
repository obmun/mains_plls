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

        phase_loop_i : entity work.phase_loop(Alg)
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
                variable i : natural := 0;
        begin
                norm_input_s <= (others => '0');
                run_s <= '0';
                rst_s <= '1';
                wait on clk_s until rising_edge(clk_s);
                wait for 10 ns;
                rst_s <= '0';
                run_s <= '1';
                wait for 30 us;

                for i in 1000 downto 0 loop
                        run_s <= '1';
                        wait on clk_s until rising_edge(clk_s);
                        wait on clk_s until clk_s = '0';
                        run_s <= '0';
                        wait for 1 us;
                end loop;  -- i
        end process signal_gen;

end beh;
