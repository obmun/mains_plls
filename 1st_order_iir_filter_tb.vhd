-- Copyright (c) 2012-2016 Jacobo Cabaleiro Cayetano
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

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

