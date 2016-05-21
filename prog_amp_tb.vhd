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

library ieee;
use ieee.std_logic_1164.all;

entity prog_amp_tb is
end entity;

architecture beh of prog_amp_tb is
    signal clk_s, rst_s : std_logic;
    signal set_gain_s, done_s : std_logic;
    signal a_gain_s, b_gain_s : std_logic_vector(3 downto 0);

    signal spi_owned_out_s : std_logic;
    signal spi_mosi_s, spi_sck_s, spi_miso_s, amp_ncs_s : std_logic;

    constant CLOCK_PERIOD : time := 20 ns;
begin
     prog_amp_i : entity work.prog_amp(beh)
          port map (
               clk => clk_s, rst => rst_s,
               a_gain => a_gain_s, b_gain => b_gain_s,
               set_gain => set_gain_s, done => done_s,
               spi_owned_out => spi_owned_out_s,
               spi_mosi => spi_mosi_s, spi_sck => spi_sck_s,
               spi_miso => spi_miso_s, amp_ncs => amp_ncs_s);

     signal_gen : process
     begin
          spi_miso_s <= '0'; -- Block does not need this
          a_gain_s <= b"1010";
          b_gain_s <= b"0101";

          -- Clk starts at 0, so I already have half cycle in advance
          rst_s <= '0';
          set_gain_s <= '0';
          wait for CLOCK_PERIOD;
          -- (reset)
          rst_s <= '1';
          set_gain_s <= '0';
          wait for CLOCK_PERIOD;
          -- (request run)
          rst_s <= '0';
          set_gain_s <= '1';
          wait for CLOCK_PERIOD;
          -- (verify done has gone down)
          set_gain_s <= '0';
          assert done_s = '0' report "DONE didn't go down!" severity error;
          -- (wait until process finishes)
          -- YES, I know I should check the bytes are correct but ... this is just a quick tb. It
          -- needs visual inspection :D
          wait on clk_s until done_s = '1';
          wait on clk_s until falling_edge(clk_s); -- Wait for one full cycle
          assert spi_owned_out_s = '0' report "SPI still owned by element!" severity error;
          -- (request run, new values
          a_gain_s <= b"1001";
          b_gain_s <= b"0110";
          rst_s <= '0';
          set_gain_s <= '1';
          wait for CLOCK_PERIOD;
          -- (verify done has gone down)
          set_gain_s <= '0';
          assert done_s = '0' report "DONE didn't go down!" severity error;
          -- (wait until process finishes)
          -- YES, I know I should check the bytes are correct but ... this is just a quick tb. It
          -- needs visual inspection :D
          wait on clk_s until done_s = '1';
          wait on clk_s until falling_edge(clk_s); -- Wait for one full cycle
          assert spi_owned_out_s = '0' report "SPI still owned by element!" severity error;
          wait;
     end process;
     
     clock : process
     begin
          clk_s <= '0';
          wait for CLOCK_PERIOD / 2;
          clk_s <= '1';
          wait for CLOCK_PERIOD / 2;
     end process clock;
end;
