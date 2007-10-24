library IEEE;
library WORK;
use WORK.COMMON.all;
use IEEE.STD_LOGIC_1164.all;

entity kcm_cosim_tb is
end kcm_cosim_tb;

architecture beh of kcm_cosim_tb is
        signal i_2_s, o_2_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
        signal i_05_s, o_05_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
        signal i_001_s, o_001_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
        signal i_100_s, o_100_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
        signal i_m233_s, o_m233_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
begin  -- beh
        kcm_2_i : entity work.kcm(structural_mm)
                generic map (
                        width => PIPELINE_WIDTH, prec => PIPELINE_PREC,
                        k => 2.0)
                port map (
                        i => i_2_s,
                        o => o_2_s);
        kcm_05_i : entity work.kcm(structural_mm)
                generic map (
                        width => PIPELINE_WIDTH, prec => PIPELINE_PREC,
                        k => 0.5)
                port map (
                        i => i_05_s,
                        o => o_05_s);
        kcm_001_i : entity work.kcm(structural_mm)
                generic map (
                        width => PIPELINE_WIDTH, prec => PIPELINE_PREC,
                        k => 0.01)
                port map (
                        i => i_001_s,
                        o => o_001_s);
        kcm_100_i : entity work.kcm(structural_mm)
                generic map (
                        width => PIPELINE_WIDTH, prec => PIPELINE_PREC,
                        k => 100.0)
                port map (
                        i => i_100_s,
                        o => o_100_s);
        kcm_m233_i : entity work.kcm(structural_mm)
                generic map (
                        width => PIPELINE_WIDTH, prec => PIPELINE_PREC,
                        k => -2.333)
                port map (
                        i => i_m233_s,
                        o => o_m233_s);

end beh;

