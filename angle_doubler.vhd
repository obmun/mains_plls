--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    
-- Design Name:    
-- Module Name:    
-- Project Name:   
-- Target Device:  
-- Tool versions:  
--
-- *** BRIEF DESCRIPTION ***
-- Doubles a give angle (2*theta), taking into account the MAGNITUDE LIMITS of
-- our usual pipeline width :) [also known as the 'good old' principal
-- determination of the arg function]
--
-- *** DESCRIPTION ***
-- During debugging of phase_det, it was realized that we were getting
-- precision problems because angle duplication was not doing carefully. When
-- input angle was near Pi, duplicated angle was overloading pipeline,
-- corresponding sin for harmonic correction was incorrect and phase_det phase
-- error result was wrong.
--
-- This double_angle block takes care of correcly duplicating input angle.
-- Input angle must: -pi < in_theta < pi
-- Ouput angle is gonna be: -pi < in_theta < pi
--
-- THIS BLOCK takes of returning the "inverse" angle in case of input_theta * 2
-- is a > pi angle. The same for the negative ones.
--
-- IT's specifically designed taking into acount the magnitude limits of a 16
-- bits wide pipeline. That's the reason no generics are found. IT cannot be parametrized.
--
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- 
--------------------------------------------------------------------------------

library IEEE;
use WORK.COMMON.ALL;
use IEEE.STD_LOGIC_1164.ALL;

entity angle_doubler is
        port (
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
