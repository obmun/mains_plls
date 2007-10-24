library WORK;
use WORK.COMMON.all;
library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity kcm_tb is
end kcm_tb;

architecture beh of kcm_tb is
        signal i_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
        signal kcm_1_o_s, kcm_m1_o_s, kcm_2_o_s, kcm_m2_o_s, kcm_3_o_s, kcm_m3_o_s, kcm_4_o_s, kcm_m4_o_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
begin 
        kcm_1_i : entity work.kcm(structural_mm)
                generic map (
                        width => PIPELINE_WIDTH,
                        prec  => PIPELINE_PREC,
                        k     => 5.8712)
                port map (
                        i => i_s,
                        o => kcm_1_o_s);

        kcm_m1_i : entity work.kcm(beh)
                generic map (
                        width => PIPELINE_WIDTH,
                        prec  => PIPELINE_PREC,
                        k     => -5.8712)
                port map (
                        i => i_s,
                        o => kcm_m1_o_s);

        kcm_2_i : entity work.kcm(beh)
                generic map (
                        width => PIPELINE_WIDTH,
                        prec  => PIPELINE_PREC,
                        k     => 2.0)
                port map (
                        i => i_s,
                        o => kcm_2_o_s);
        
        kcm_m2_i : entity work.kcm(beh)
                generic map (
                        width => PIPELINE_WIDTH,
                        prec  => PIPELINE_PREC,
                        k     => -2.0)
                port map (
                        i => i_s,
                        o => kcm_m2_o_s);

        kcm_3_i : entity work.kcm(beh)
                generic map (
                        width => PIPELINE_WIDTH,
                        prec  => PIPELINE_PREC,
                        k     => 0.5)
                port map (
                        i => i_s,
                        o => kcm_3_o_s);

        kcm_m3_i : entity work.kcm(beh)
                generic map (
                        width => PIPELINE_WIDTH,
                        prec  => PIPELINE_PREC,
                        k     => -0.5)
                port map (
                        i => i_s,
                        o => kcm_m3_o_s);

        kcm_4_i : entity work.kcm(beh)
                generic map (
                        width => PIPELINE_WIDTH,
                        prec  => PIPELINE_PREC,
                        k     => 0.1366)
                port map (
                        i => i_s,
                        o => kcm_4_o_s);

        kcm_m4_i : entity work.kcm(beh)
                generic map (
                        width => PIPELINE_WIDTH,
                        prec  => PIPELINE_PREC,
                        k     => -0.1366)
                port map (
                        i => i_s,
                        o => kcm_m4_o_s);

        i_s <= (others => '0') after 0 ns,
               to_pipeline_vector(2.0) after 10 ns,
               to_pipeline_vector(4.0) after 10 ns,
               to_pipeline_vector(8.0) after 10 ns,
               to_pipeline_vector(16.0) after 10 ns,
               to_pipeline_vector(32.0) after 10 ns,
               to_pipeline_vector(1.0) after 10 ns,
               to_pipeline_vector(3.0) after 10 ns,
               to_pipeline_vector(7.0) after 10 ns,
               to_pipeline_vector(15.0) after 10 ns,
               to_pipeline_vector(31.0) after 10 ns;
end beh;
