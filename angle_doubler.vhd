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

--! @brief Doubles a given input angle theta (out = 2 * theta), folding the result into -pi < out < pi limits.
--!
--! This entity was designed for doubling an input angle taking into account the magnitude limits of
--! our usual pipeline width (16 bits) [also known as the 'good old' principal determination of the arg
--! function]
--!
--! During debugging of phase_det, I realized that we were getting precision problems because
--! angle duplication was not being done carefully. When input angle was near Pi, the angle
--! duplication was overloading the pipeline, and corresponding sin() for harmonic correction was
--! incorrect and phase_det phase error result was incorrect.
--!
--! This block takes care of correcly duplicating input angle.
--!
--! Input angle must: -pi < in_theta < pi
--! Ouput angle is going to be: -pi < in_theta < pi
--!
--! THIS BLOCK takes care of returning the "inverse" angle in case of input_theta * 2 is a > pi
--! angle. The same for the negative ones.
--!
--! IT's specifically designed taking into acount the magnitude limits of a 16 bits wide
--! pipeline. That's the reason no generics are found. IT cannot be directly "parametrized", but
--! makes use of common library pipeline description constants
entity angle_doubler is
     port(
          i : in std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
          o : out std_logic_vector(PIPELINE_WIDTH - 1 downto 0));
end angle_doubler;


architecture beh of angle_doubler is
        signal i_angle_EXT_s, angle_EXT_s : std_logic_vector(EXT_PIPELINE_WIDTH - 1 downto 0);
        signal gt_half_pi_s, lt_minus_half_pi_s, need_correction_s : std_logic;
        signal correction_const_EXT_s : std_logic_vector(EXT_PIPELINE_WIDTH - 1 downto 0);
        signal corrected_angle_EXT_s, doubler_out_EXT_s : std_logic_vector(EXT_PIPELINE_WIDTH - 1 downto 0);
begin

        i_angle_conv : entity work.pipeline_conv(alg)
                generic map (
                        in_width => PIPELINE_WIDTH,
                        in_prec => PIPELINE_PREC,
                        out_width => EXT_PIPELINE_WIDTH,
                        out_prec => EXT_PIPELINE_PREC)
                port map (
                        i => i,
                        o => i_angle_EXT_s);

        gt_half_pi : entity work.k_gt_comp(beh)
                generic map (
                        width => PIPELINE_WIDTH,
                        k => HALF_PI)
                port map (
                        a => i,
                        a_gt_k => gt_half_pi_s);

        lt_minus_half_pi : entity work.k_lt_comp(beh)
                generic map (
                        width => PIPELINE_WIDTH,
                        k => MINUS_HALF_PI)
                port map (
                        a => i,
                        a_lt_k => lt_minus_half_pi_s);

        need_correction_s <= gt_half_pi_s or lt_minus_half_pi_s;

        correction_const_val : process(gt_half_pi_s, lt_minus_half_pi_s)
        begin
                if (gt_half_pi_s = '1') then
                        correction_const_EXT_s <= to_ext_pipeline_vector(MINUS_PI);
                elsif (lt_minus_half_pi_s = '1') then
                        correction_const_EXT_s <= to_ext_pipeline_vector(PI);
                else
                        correction_const_EXT_s <= to_ext_pipeline_vector(PI);  -- En realidad, me
                                                                               -- da igual!
                end if;
        end process correction_const_val;

        adder_i : entity work.adder(alg)
                generic map (
                        width => EXT_PIPELINE_WIDTH)
                port map (
                        a => i_angle_EXT_s,
                        b => correction_const_EXT_s,
                        o => corrected_angle_EXT_s,
                        f_ov => open,
                        f_z => open);

        angle_EXT_s <= i_angle_EXT_s when (need_correction_s = '0')
                       else corrected_angle_EXT_s;

        doubler : entity work.k_2_mul(alg)
                generic map (
                        width => EXT_PIPELINE_WIDTH)
                port map (
                        i => angle_EXT_s,
                        o => doubler_out_EXT_s);

        doubler_conv : entity work.pipeline_conv(alg)
                generic map (
                        in_width => EXT_PIPELINE_WIDTH,
                        in_prec => EXT_PIPELINE_PREC,
                        out_width => PIPELINE_WIDTH,
                        out_prec => PIPELINE_PREC)
                port map (
                        i => doubler_out_EXT_s,
                        o => o);
end beh;
