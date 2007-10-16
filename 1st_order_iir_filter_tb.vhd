library IEEE;
use WORK.COMMON.all;
use IEEE.STD_LOGIC_1164.all;

entity filter_1st_order_iir_tb is
end filter_1st_order_iir_tb;

architecture beh of filter_1st_order_iir_tb is
        constant CLOCK_PERIOD : time := 20 ns;

        signal clk_s : std_logic;
        signal rst_s : std_logic;
        signal i_s, o_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
        signal run_s, done_s : std_logic;
begin  -- beh
        clock : process
        begin
                clk_s <= '0';
                wait for CLOCK_PERIOD / 2;
                clk_s <= '1';
                wait for CLOCK_PERIOD / 2;
        end process clock;

        iir_i : entity work.filter_1st_order_iir(beh)
                generic map (
                        width => PIPELINE_WIDTH, prec => PIPELINE_PREC,
                        b0 => 0, b1 => 0, a1 => 1,
                        delayer_width => 1);
                port map (
                        clk => clk_s,
                        rst => rst_s,
                        run_en => run_s,
                        run_passthru => done_s,
                        i => i_s,
                        o => o_s,
                        delayer_in => open,
                        delayer_out => open);

        signal_gen : process
        begin
                rst_s <= '0';
                run_s <= '1';
                i_s <= (others => '0');
                wait for 8 us;
                wait;
        end process signal_gen;
end beh;

