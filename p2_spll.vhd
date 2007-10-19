--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    13:17:04 06/29/06
-- Design Name:    
-- Module Name:    spll - alg
-- Project Name:   
-- Target Device:  
-- Tool versions:  
-- Description:
--
-- Dependencies:
-- 
-- Revision:
-- Revision 0.02 - 2nd paper simple SPLL (this one) doesn't really have a
-- complex Ampl loop. Removed and added necesary logic right here.
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
--------------------------------------------------------------------------------
library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use WORK.COMMON.all;

entity p2_spll is
        -- rev 0.01
	port (
		clk, sample, rst : in std_logic;
		in_signal : in std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
		phase, out_signal, ampl : out std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
		done : out std_logic);
end p2_spll;

architecture structural of p2_spll is
        constant FA_PREC : natural := 14;
	signal first_run_s, first_run_pulsed_s : std_logic;
        signal phase_done_s, phase_done_pulsed_s, fa_delayed_done_s : std_logic;
	signal in_signal_reg_out_s, our_signal_s, ampl_mul_out_s, ampl_fa_out_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
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
                        run_passthru   => open,
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
                        o => ampl);

	done <= fa_delayed_done_s;
        out_signal <= our_signal_s;
end structural;
