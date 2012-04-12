library ieee;
use ieee.std_logic_1164.all;

entity pulsed_done_and_tb is
end entity;

architecture alg of pulsed_done_and_tb is
    signal clk_s, rst_s : std_logic;
    signal i_s : std_logic_vector(1 downto 0);
    signal o_s : std_logic;

    constant CLOCK_PERIOD : time := 20 ns;
begin
     pulsed_done_and_i : entity work.pulsed_done_and(beh)
          generic map (
               width => 2)
          port map (
               clk => clk_s, rst => rst_s,
               i => i_s,
               o => o_s);
     
     signal_gen : process
     begin
          -- Clk starts at 0, so I already have half cycle in advance
          rst_s <= '0';
          i_s(0) <= '0';
          i_s(1) <= '0';
          wait for CLOCK_PERIOD;
          -- ** 2nd cycle: RESET
          rst_s <= '1';
          i_s(0) <= '0';
          i_s(1) <= '0';
          wait for CLOCK_PERIOD;
          -- (instantaneous output test)
          -- ** 3rd cycle: Both inputs up -> instantaneous output
          rst_s <= '0';
          -- 1) Check reset
          assert o_s = '0' report "RESET failed" severity failure;
          -- 2) Set both inputs to 1
          i_s(0) <= '1';
          i_s(1) <= '1';
          -- 3) Check result
          wait for CLOCK_PERIOD/4;
          assert o_s = '1' report "INSTANTANEOUS SET failed" severity failure;
          wait on clk_s until clk_s = '0';
          -- ** 4th cycle: both inputs down, output should not change
          -- 1) Check that previous instantenous set left the output to 0 (pulse should have been
          -- generated only on that cycle)
          assert o_s = '0' report "INSTANTENOUS SET left output up (pulse of more than 1 clk cycle width)!" severity failure;
          -- 2) Keep signals at 0;
          i_s(0) <= '0';
          i_s(1) <= '0';
          wait for CLOCK_PERIOD;
          -- (consecutive inputs up, first input left at '1')
          -- ** 5th cycle: put one input up
          -- 1) Check previous cycle: output must not have changed from '0'
          assert o_s = '0' report "OUTPUT RISED with both inputs to 0!" severity failure;
          -- 2) Set inputs
          i_s(0) <= '1';
          i_s(1) <= '0';
          wait for CLOCK_PERIOD;
          -- ** 6th cycle: put the other input up, on the inmediate next cycle
          -- 1) Check that output has not gone to '1'
          assert o_s = '0' report "OUTPUT RISED without reason!" severity failure;
          -- 2) Manage inputs
          i_s(0) <= '1';
          i_s(1) <= '1';
          -- 3) Check result
          wait for CLOCK_PERIOD/4;
          assert o_s = '1' report "INSTANTANEOUS SET failed" severity failure;
          wait on clk_s until clk_s = '0';
          -- (consecutive inputs up, first input returns to '0')
          -- ** Put the first input up
          -- 1) Check that output has returned to 0 from last test
          assert o_s = '0' report "OUTPUT DID not return to 0!" severity failure;
          -- 2) Manage inputs
          i_s(0) <= '1';
          i_s(1) <= '0';
          wait for CLOCK_PERIOD;
          -- ** 6th cycle: put the other input up, on the inmediate next cycle
          -- 1) Check that output has not gone to '1'
          assert o_s = '0' report "OUTPUT RISED without reason!" severity failure;
          -- 2) Manage inputs
          i_s(0) <= '0';
          i_s(1) <= '1';
          -- 3) Check result
          wait for CLOCK_PERIOD/4;
          assert o_s = '1' report "SET failed" severity failure;
          wait on clk_s until clk_s = '0';
          -- (inputs up with an intermediate clk cycle. Previous up-ed input is left to '1')
          -- ** Put the first input up
          -- 1) Verify that output has returned to 0 from last test
          assert o_s = '0' report "OUTPUT DID not return to 0!" severity failure;
          -- 2) Manage inputs
          i_s(0) <= '1';
          i_s(1) <= '0';
          wait for CLOCK_PERIOD;
          -- ** Wait 1 clk cycle
          -- 1) Verify that output has not moved
          assert o_s = '0' report "OUTPUT DID not stay at 0!" severity failure;
          -- 2) Manage inputs
          i_s(0) <= '1';
          i_s(1) <= '0';
          wait for CLOCK_PERIOD;          
          -- ** Put the other input up
          -- 1) Check that output has not gone to '1'
          assert o_s = '0' report "OUTPUT did not stay at 0!" severity failure;
          -- 2) Manage inputs
          i_s(0) <= '1';
          i_s(1) <= '1';
          -- 3) Check result
          wait for CLOCK_PERIOD/4;
          assert o_s = '1' report "SET failed" severity failure;
          wait on clk_s until clk_s = '0';
          -- (inputs up with an intermediate clk cycle. Previous up-ed input is left to '0')
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
