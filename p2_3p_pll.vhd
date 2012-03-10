--------------------------------------------------------------------------------
-- === DESCRIPTION ===
--
-- == IMPORTANT NOTES ==
--
-- The following supposition is made: phase_loop n_iters > fa + reg n_iters
-- Otherwise, design DOES NOT WORK
--------------------------------------------------------------------------------

library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use WORK.COMMON.all;


entity p2_3p_pll is
     -- rev 0.01
     port (
          clk, sample, rst : in std_logic;
          a, b, c: in std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
          phase, ampl : out std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
          done : out std_logic);
end p2_3p_pll;


architecture structural of p2_3p_pll is
     constant FA_PREC : natural := EXT_IIR_FILTERS_PREC;
     signal first_run_s, first_run_pulsed_s, first_run_pulsed_delayed_s, fa_done_s : std_logic;
     signal phase_loop_done_s : std_logic;
     signal d_s, q_s, d_reg_out_s, sin_s, cos_s, ampl_fa_out_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
     signal d_reg_out_E_s, ampl_fa_out_E_s : std_logic_vector(EXT_PIPELINE_WIDTH - 1 downto 0);
     signal garbage_1_s : std_logic;
begin

     first_run_s <= phase_loop_done_s and sample;
     first_run_pulser : entity work.done_pulser(beh)
          port map (
               clk => clk,
               en  => '1',
               rst => rst,
               i   => first_run_s,
               o   => first_run_pulsed_s);

     park_transform_i : entity work.park_transform(structural)
          port map (
               a   => a,
               b   => b,
               c   => c,
               cos => cos_s,
               sin => sin_s,
               d   => d_s,
               q   => q_s);

     -- A q signal register is not needed. Phase loop has already registers
     -- very close to its inputs, so neither combinational delay nor
     -- withstanding of variable pll block inputs after run order should be
     -- a problem. At the same time, we're able to inmediately launch the
     -- phase_loop calculation stage.
     -- problem.
     -- => q_reg : entity work.reg(alg) <=

     d_reg : entity work.reg(alg)
          port map (
               clk => clk,
               we => first_run_pulsed_s,
               rst => rst,
               i => d_s,
               o => d_reg_out_s);

     first_run_pulsed_delayer : entity work.reg(alg)
          generic map (
               width => 1)
          port map (
               clk  => clk,
               we   => '1',
               rst  => rst,
               i(0) => first_run_pulsed_s,
               o(0) => first_run_pulsed_delayed_s);

     fa_input_conv : entity work.pipeline_conv(alg)
          generic map (
               in_width  => PIPELINE_WIDTH,
               in_prec   => PIPELINE_PREC,
               out_width => EXT_PIPELINE_WIDTH,
               out_prec  => FA_PREC)
          port map (
               i => d_reg_out_s,
               o => d_reg_out_E_s);
     
     ampl_fa : entity work.fa(beh)
          generic map (
               width         => EXT_PIPELINE_WIDTH,
               prec          => FA_PREC,
               delay         => 100,
               delayer_width => 1)
          port map (
               clk            => clk,
               rst            => rst,
               i              => d_reg_out_E_s,
               o              => ampl_fa_out_E_s,
               run_en         => first_run_pulsed_delayed_s,
               run_passthru   => fa_done_s,
               delayer_in(0)  => '-',
               delayer_out(0) => garbage_1_s);

     fa_output_conv : entity work.pipeline_conv(alg)
          generic map (
               out_width => PIPELINE_WIDTH,
               out_prec  => PIPELINE_PREC,
               in_width  => EXT_PIPELINE_WIDTH,
               in_prec   => FA_PREC)
          port map (
               i => ampl_fa_out_E_s,
               o => ampl_fa_out_s);

     phase_loop_i : entity work.p2_3p_phase_loop(structural)
          port map (
               clk => clk, run => first_run_s,
               rst => rst,
               q_input => q_s,
               phase => phase, freq => open,
               sin => sin_s, cos => cos_s,
               done => phase_loop_done_s);

     done <= phase_loop_done_s;
     
     ampl <= ampl_fa_out_s;
end structural;
