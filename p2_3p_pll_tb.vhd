entity p2_3p_pll_tb is
end p2_3p_pll_tb;

library IEEE;
use IEEE.STD_LOGIC_1164.all;
library WORK;
use WORK.COMMON.all;

architecture beh of p2_3p_pll_tb is
        signal clk_s, sample_s, rst_s, done_s : std_logic;
        signal a_s, b_s, c_s, phase_s, ampl_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
begin

        uut : entity work.p2_3p_pll(structural)
                port map (
                        clk    => clk_s,
                        sample => sample_s,
                        rst    => rst_s,
                        a      => a_s,
                        b      => b_s,
                        c      => c_s,
                        phase  => phase_s,
                        ampl   => ampl_s,
                        done   => done_s);

end beh;
