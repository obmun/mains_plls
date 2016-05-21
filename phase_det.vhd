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
use WORK.COMMON.ALL;
use IEEE.STD_LOGIC_1164.ALL;


--! @brief Phase detector based on Cordic seq engine.
--!
--! Control interface is identical to the Cordic engine one (run\_done iface). See iface doc.
--!
--! Class: sequential iterative.
--!
--! *** DESCRIPTION ***
--!
--! This phase detector multiplies input signal by a cos with current internal
--! detected phase to identify phase jumps. But due to the used method, a second
--! order harmonic in normal situation is generated and must be removed.
--!
--! sin(theta_input) * cos(theta_internal) = sin(theta_input - theta_internal) *
--! 1/2 + sin(theta_input + theta_internal) * 1/2 <<-- (this second term is a
--! 2nd harmonic).
--!
--! Therefore second harmonic substraction is also implemented inside this block.
--!
--! This is just a wrapper around Cordic based cos / sin engine + some extra
--! combinational glue logic. Therefore no internal "state" machine apart of
--! the one from the Cordic engine is needed.
entity phase_det is
    port (
        -- Input value signals
        norm_input, curr_phase : in std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
        -- Input control signals
        run, rst, clk : in std_logic;
        -- Out value signals
        phase_error : out std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
        norm_output : out std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
        -- Out control signals
        done : out std_logic);
end phase_det;

architecture alg of phase_det is
	signal cos_out, sin_2_out : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
	signal mul_out, k_div_out, angle_doubler_out_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
        signal doubler_reg_out_s : std_logic_vector(PIPELINE_WIDTH downto 0);
	signal c_done, c_2_done : std_logic;
        signal input_reg_we_s : std_logic;
        signal norm_input_reg_out_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
begin

	-- INSTANTIATIONS
        norm_input_reg_i : entity work.reg(alg)
                generic map (
                        width => PIPELINE_WIDTH)

                port map (
                        clk => clk,
                        rst => rst,
                        we  => input_reg_we_s,
                        i => norm_input,
                        o => norm_input_reg_out_s);

        input_reg_we_s <= run and c_done and c_2_done;

	cordic_i : entity work.cordic(structural)
		port map (
			-- ENTRADAS
			clk => clk, rst => rst,
                        run => run,
			angle => curr_phase,
			-- SALIDAS
			sin => norm_output,
			cos => cos_out,
			done => c_done
		);

	cordic_2_i : entity work.cordic(structural)
		port map (
			-- ENTRADAS
			clk => clk, rst => rst,
                        run => doubler_reg_out_s(PIPELINE_WIDTH),
			angle => doubler_reg_out_s(PIPELINE_WIDTH - 1 downto 0),
			-- SALIDAS
			sin => sin_2_out,
                        cos => open,
			done => c_2_done
		);

	mul_i : entity work.mul(beh)
		port map (
			-- ENTRADAS
			a => norm_input_reg_out_s,
			b => cos_out,
			-- SALIDAS
			o => mul_out);

	subsor_i : entity work.subsor(alg)
		port map (
			-- ENTRADAS
			a => mul_out,
			b => k_div_out,
			-- SALIDAS
			o => phase_error,
                        -- Unused
                        f_ov => open,
                        f_z => open);

	k_2_div_i : entity work.k_2_div(alg)
		port map (
			i => sin_2_out,
			o => k_div_out);

        angle_doubler_i : entity work.angle_doubler(beh)
                port map (
                        i => curr_phase,
                        o => angle_doubler_out_s);

        -- Speedup register... MMM... is this really needed?
        doubler_reg_i : entity work.reg(alg)
                generic map (
                        width => PIPELINE_WIDTH + 1)
                port map (
                        clk => clk,
                        we => '1',
                        rst => '0',
                        i(PIPELINE_WIDTH) => run,
                        i(PIPELINE_WIDTH - 1 downto 0) => angle_doubler_out_s,
                        o => doubler_reg_out_s);

	done <= c_done and c_2_done;
end alg;
