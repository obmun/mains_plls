library IEEE;
use WORK.COMMON.all;
use IEEE.STD_LOGIC_1164.all;

entity filter_2nd_order_iir_cosim_tb is
end filter_2nd_order_iir_cosim_tb;

architecture beh of filter_2nd_order_iir_cosim_tb is
        signal clk_s : std_logic;
        signal rst_s : std_logic;
        signal i_s, o_s : std_logic_vector(EXT_PIPELINE_WIDTH - 1 downto 0);
        signal run_s, done_s : std_logic;
begin  -- beh
        iir_i : entity work.filter_2nd_order_iir(beh)
                generic map (
                        width => EXT_PIPELINE_WIDTH, prec => EXT_PIPELINE_PREC,
                        b0 => 0.9755, b1 => -1.947, b2 => 0.9755,
                        a1 => -1.947, a2 => 0.951,
                        delayer_width => 1)
                port map (
                        clk => clk_s,
                        rst => rst_s,
                        run_en => run_s,
                        run_passthru => done_s,
                        i => i_s,
                        o => o_s,
                        delayer_in => b"0",
                        delayer_out => open);

end beh;

