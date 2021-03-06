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
library WORK;
use IEEE.STD_LOGIC_1164.all;
use WORK.COMMON.all;

--! @brief p2-spll (Notch-PLL) entity, integrating the phase-loop and the amplitude loop.
entity p2_spll is
        -- rev 0.01
	port (
		clk, sample, rst : in std_logic;
		in_signal : in std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
		phase, out_signal, ampl : out std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
		done : out std_logic);
end p2_spll;

architecture structural of p2_spll is
        constant FA_PREC : natural := EXT_IIR_FILTERS_PREC;

	signal first_run_s, first_run_pulsed_s : std_logic;

        signal phase_done_s, phase_done_pulsed_s, fa_delayed_done_s : std_logic;
        signal fa_REG_delayed_done_s, fa_done_pulsed_s : std_logic;

	signal in_signal_reg_out_s, our_signal_s, ampl_mul_out_s, ampl_fa_out_s, ampl_kcm_out_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
        signal ampl_mul_out_E_s, ampl_fa_out_E_s : std_logic_vector(EXT_PIPELINE_WIDTH - 1 downto 0);
        signal garbage_1_s : std_logic;
begin

        first_run_s <= fa_delayed_done_s and sample;
        first_run_pulser : entity work.done_pulser(beh)
                port map (
                        clk => clk,
                        en  => '1',
                        rst => rst,
                        i   => first_run_s,
                        o   => first_run_pulsed_s);

        -- Ok ... phase_det already has a register for input ... so I could
        -- make a "short", go inside phase_det and get directly from there the
        -- stored input sample. But ... I REALLY LIKE the TOP - BOTTOM
        -- abstraction, and I don't wanna make this dirtier just for saving 16
        -- flip-flops
        in_signal_reg : entity work.reg(alg)
                port map (
                        clk => clk,
                        we => first_run_pulsed_s,
                        rst => rst,
                        i => in_signal,
                        o => in_signal_reg_out_s);
        
	phase_loop_i : entity work.p2_phase_loop(beh)
		port map (
			clk => clk, run => first_run_s,
                        rst => rst,
			input => in_signal,
			phase => phase, norm_sin => our_signal_s,
			done => phase_done_s);

        phase_done_pulser : entity work.done_pulser(beh)
                port map (
                        clk => clk,
                        en  => '1',
                        rst => rst,
                        i   => phase_done_s,
                        o   => phase_done_pulsed_s);

        ampl_mul : entity work.mul(beh)
                port map (
                        a => our_signal_s,
                        b => in_signal_reg_out_s,
                        o => ampl_mul_out_s);

        fa_input_conv : entity work.pipeline_conv(alg)
                generic map (
                        in_width  => PIPELINE_WIDTH,
                        in_prec   => PIPELINE_PREC,
                        out_width => EXT_PIPELINE_WIDTH,
                        out_prec  => FA_PREC)
                port map (
                        i => ampl_mul_out_s,
                        o => ampl_mul_out_E_s);

        -- Latency: 0 clks
        -- Throughput: 1 clk/value
        ampl_fa : entity work.fa(beh)
                generic map (
                        width         => EXT_PIPELINE_WIDTH,
                        prec          => FA_PREC,
                        delay         => 100,
                        delayer_width => 2)
                port map (
                        clk            => clk,
                        rst            => rst,
                        i              => ampl_mul_out_E_s,
                        o              => ampl_fa_out_E_s,
                        run_en         => phase_done_pulsed_s,
                        run_passthru   => fa_done_pulsed_s,
                        delayer_in(0)  => '-',
                        delayer_in(1)  => phase_done_s,
                        delayer_out(0) => garbage_1_s,
                        delayer_out(1) => fa_delayed_done_s);

        fa_output_conv : entity work.pipeline_conv(alg)
                generic map (
                        out_width => PIPELINE_WIDTH,
                        out_prec  => PIPELINE_PREC,
                        in_width  => EXT_PIPELINE_WIDTH,
                        in_prec   => FA_PREC)
                port map (
                        i => ampl_fa_out_E_s,
                        o => ampl_fa_out_s);
        
        ampl_kcm : entity work.k_2_mul(alg)
                port map (
                        i => ampl_fa_out_s,
                        o => ampl_kcm_out_s);

        -- Output from the MVA (MAF) + kcm _must be registered_, as once clk is given to FA, this
        -- element is going to update its internal state and output value is no longer going to be correct

        fa_delayed_done_delayer : entity work.reg(alg)
             generic map (
                  width => 1)
             port map (
                  clk  => clk,
                  rst  => rst,
                  we   => '1',
                  i(0) => fa_delayed_done_s,
                  o(0) => fa_REG_delayed_done_s);
        
        amp_reg_i : entity work.reg(alg)
             generic map (
                  width => PIPELINE_WIDTH)
             port map (
                  clk => clk,
                  rst => rst,
                  we => fa_done_pulsed_s,
                  i => ampl_kcm_out_s,
                  o => ampl);

	done <= phase_done_s and fa_REG_delayed_done_s;  -- fa_delayed_done_s is not enough, as when
                                                         -- receiving a run order, fa_delayed_done is
                                                         -- going to receive the falling edge on done
                                                         -- from the phase detector a few cycles after
                                                         -- the actual edge happened.
        out_signal <= our_signal_s;
end structural;
