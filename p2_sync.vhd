--------------------------------------------------------------------------------
-- Company: Universidade de Vigo
-- Engineer: Jacobo Cabaleiro
--
-- Create Date: 13:17:04 06/29/06
-- Design Name:    
-- Module Name: p2_sync - structural
-- Project Name: PFC
-- Target Device: 
-- Tool versions:  
-- Description:
--
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.common.all;

entity p2_sync is
        port (
		clk, sample, rst : in std_logic;
		in_signal : in std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
		phase, out_signal, ampl : out std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
		done : out std_logic);
end p2_sync;

architecture structural of p2_sync is
        constant FA_PREC : natural := EXT_IIR_FILTERS_PREC;
        
        signal first_run_s, first_run_pulsed_s, freq2phase_delayed_run_s : std_logic;
        signal sincos_cordic_done_s, sincos_cordic_done_pulsed_s, sin_fa_delayed_run_s, cos_fa_delayed_run_s, fa_delayed_run_s : std_logic;
        signal atan_cordic_done_s : std_logic;

        signal in_signal_reg_out_s, freq2phase_out_s, sin_s, cos_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
        signal in_sin_mul_out_s, in_sin_doubler_out_s, in_cos_mul_out_s, in_cos_doubler_out_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
        signal sin_speedup_reg_out_s : std_logic_vector(PIPELINE_WIDTH downto 0);
        signal cos_speedup_reg_out_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
        signal in_sin_doubler_out_E_s, in_cos_doubler_out_E_s, sin_fa_out_E_s, cos_fa_out_E_s : std_logic_vector(EXT_PIPELINE_WIDTH - 1 downto 0);
        signal sin_fa_out_s, cos_fa_out_s, sin_sin_mul_out_s, cos_cos_mul_out_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
begin  -- structural

        first_run_s <= atan_cordic_done_s and sample;
        first_run_pulser : entity work.done_pulser(beh)
                port map (
                        clk => clk,
                        en  => '1',
                        rst => rst,
                        i   => first_run_s,
                        o   => first_run_pulsed_s);

        in_signal_reg : entity work.reg(alg)
                port map (
                        clk => clk,
                        we => first_run_pulsed_s,
                        rst => rst,
                        i => in_signal,
                        o => in_signal_reg_out_s);
        
        freq2phase_i : entity work.freq2phase(beh)
                generic map (
                        width         => PIPELINE_WIDTH,
                        prec          => PIPELINE_PREC,
                        gain          => 1.0,
                        delayer_width => 1)
                port map (
                        clk => clk,
                        rst => rst,
                        f => to_pipeline_vector(0.0),
                        p => freq2phase_out_s,
                        run_en => first_run_pulsed_s,
                        run_passthru => freq2phase_delayed_run_s,
                        delayer_in => "-",
                        delayer_out => open);

        sincos_cordic : entity work.cordic(structural)
                generic map (
                        width => PIPELINE_WIDTH,
                        prec  => PIPELINE_PREC)
                port map (
                        clk   => clk,
                        rst   => rst,
                        run   => freq2phase_delayed_run_s,
                        angle => freq2phase_out_s,
                        sin   => sin_s,
                        cos   => cos_s,
                        done  => sincos_cordic_done_s);

        sincos_cordic_done_pulser : entity work.done_pulser(beh)
                port map (
                        clk => clk,
                        en  => '1',
                        rst => rst,
                        i   => sincos_cordic_done_s,
                        o   => sincos_cordic_done_pulsed_s);

        in_sin_mul : entity work.mul(beh)
                generic map (
                        width => PIPELINE_WIDTH,
                        prec  => PIPELINE_PREC)
                port map (
                        a => in_signal_reg_out_s,
                        b => sin_s,
                        o => in_sin_mul_out_s);

        in_sin_doubler : entity work.k_2_mul(alg)
                generic map (
                        width => PIPELINE_WIDTH)
                port map (
                        i => in_sin_mul_out_s,
                        o => in_sin_doubler_out_s);

        sin_speedup_reg :  entity work.reg(alg)
                generic map (
                        width => PIPELINE_WIDTH + 1)
                port map (
                        clk => clk,
                        we => sincos_cordic_done_pulsed_s,
                        rst => rst,
                        i(PIPELINE_WIDTH - 1 downto 0) => in_sin_doubler_out_s,
                        i(PIPELINE_WIDTH) => sincos_cordic_done_pulsed_s,
                        o => sin_speedup_reg_out_s);

        in_cos_mul : entity work.mul(beh)
                generic map (
                        width => PIPELINE_WIDTH,
                        prec  => PIPELINE_PREC)
                port map (
                        a => in_signal_reg_out_s,
                        b => cos_s,
                        o => in_cos_mul_out_s);

        in_cos_doubler : entity work.k_2_mul(alg)
                generic map (
                        width => PIPELINE_WIDTH)
                port map (
                        i => in_cos_mul_out_s,
                        o => in_cos_doubler_out_s);

        cos_speedup_reg :  entity work.reg(alg)
                generic map (
                        width => PIPELINE_WIDTH)
                -- sincos_cordic_done_pulsed_s is already delayed by sin_speedup_reg
                port map (
                        clk => clk,
                        we => sincos_cordic_done_pulsed_s,
                        rst => rst,
                        i => in_cos_doubler_out_s,
                        o => cos_speedup_reg_out_s);

        sin_fa_input_conv : entity work.pipeline_conv(alg)
                generic map (
                        in_width  => PIPELINE_WIDTH,
                        in_prec   => PIPELINE_PREC,
                        out_width => EXT_PIPELINE_WIDTH,
                        out_prec  => FA_PREC)
                port map (
                        i => sin_speedup_reg_out_s(PIPELINE_WIDTH - 1 downto 0),
                        o => in_sin_doubler_out_E_s);
        
        sin_fa : entity work.fa(beh)
                generic map (
                        width         => EXT_PIPELINE_WIDTH,
                        prec          => FA_PREC,
                        delay         => 100,
                        delayer_width => 1)
                port map (
                        clk            => clk,
                        rst            => rst,
                        i              => in_sin_doubler_out_E_s,
                        o              => sin_fa_out_E_s,
                        run_en         => sin_speedup_reg_out_s(PIPELINE_WIDTH),
                        run_passthru   => sin_fa_delayed_run_s,
                        delayer_in => (others => '-'),
                        delayer_out => open);
        
        sin_fa_output_conv : entity work.pipeline_conv(alg)
                generic map (
                        out_width => PIPELINE_WIDTH,
                        out_prec  => PIPELINE_PREC,
                        in_width  => EXT_PIPELINE_WIDTH,
                        in_prec   => FA_PREC)
                port map (
                        i => sin_fa_out_E_s,
                        o => sin_fa_out_s);
        
        cos_fa_input_conv : entity work.pipeline_conv(alg)
                generic map (
                        in_width  => PIPELINE_WIDTH,
                        in_prec   => PIPELINE_PREC,
                        out_width => EXT_PIPELINE_WIDTH,
                        out_prec  => FA_PREC)
                port map (
                        i => in_cos_doubler_out_s,
                        o => in_cos_doubler_out_E_s);

        cos_fa : entity work.fa(beh)
                generic map (
                        width         => EXT_PIPELINE_WIDTH,
                        prec          => FA_PREC,
                        delay         => 100,
                        delayer_width => 1)
                port map (
                        clk            => clk,
                        rst            => rst,
                        i              => cos_speedup_reg_out_s,
                        o              => cos_fa_out_E_s,
                        run_en         => sin_speedup_reg_out_s(PIPELINE_WIDTH),
                        run_passthru   => cos_fa_delayed_run_s,
                        delayer_in => (others => '-'),
                        delayer_out => open);
        
        cos_fa_output_conv : entity work.pipeline_conv(alg)
                generic map (
                        out_width => PIPELINE_WIDTH,
                        out_prec  => PIPELINE_PREC,
                        in_width  => EXT_PIPELINE_WIDTH,
                        in_prec   => FA_PREC)
                port map (
                        i => cos_fa_out_E_s,
                        o => cos_fa_out_s);

        fa_delayed_run_s <= sin_fa_delayed_run_s and cos_fa_delayed_run_s;

        atan_cordic : entity work.cordic_atan(structural)
                generic map (
                        width => PIPELINE_WIDTH,
                        prec  => PIPELINE_PREC)
                port map (
                        clk   => clk,
                        rst   => rst,
                        run   => fa_delayed_run_s,
                        x => cos_fa_out_s,
                        y => sin_fa_out_s,
                        angle => phase,
                        modu => ampl,
                        done  => atan_cordic_done_s);

        done <= atan_cordic_done_s;
        
        sin_sin_mul : entity work.mul(beh)
                generic map (
                        width => PIPELINE_WIDTH,
                        prec  => PIPELINE_PREC)
                port map (
                        a => sin_s,
                        b => sin_fa_out_s,
                        o => sin_sin_mul_out_s);

        cos_cos_mul : entity work.mul(beh)
                generic map (
                        width => PIPELINE_WIDTH,
                        prec  => PIPELINE_PREC)
                port map (
                        a => cos_s,
                        b => cos_fa_out_s,
                        o => cos_cos_mul_out_s);

        adder_i : entity work.adder(alg)
                generic map (
                        width => PIPELINE_WIDTH)
                port map (
                        a => sin_sin_mul_out_s,
                        b => cos_cos_mul_out_s,
                        o => out_signal);
end structural;
