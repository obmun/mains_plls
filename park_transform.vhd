--------------------------------------------------------------------------------
-- Company: UVigo
-- Engineer: Jacobo Cabaleiro
--
-- Create Date:    
-- Design Name:    
-- Module Name:  park_transform - structural
-- Project Name:   
-- Target Device:  
-- Tool versions:
--
-- *** Brief desc ***
-- Class: combinational
-- Implements the Park transform, converting positive sequence ABC inputs into
-- dq values
--
-- *** Description ***
-- abc -> dq transform is given by the equations:
-- d = \[a \cdot cos \theta + b \cdot cos(\theta - {2 \cdot \pi} \over 3) + c
-- \cdot cos(\theta + {2 \cdot \ò} \over 3) \] \cdot 2/3
-- q = [- a \cdot sin \theta - b \cdot sin(\theta - {2 \cdot \pi} \over 3) - c
-- \cdot sin(\theta + {2 \cdot \ò} \over 3)] * 2/3
--
-- cos(\theta + 2*pi/3), cos(\theta - 2*pi/3) and equivalent sines are expanded
-- thru the angle summation trigonometric equivalents. That way those values
-- can be easily implemented already 2/3 prescaled by means of 4 kcms
-- (cos(theta) and sin(theta) multiplied by alfa and beta) and 4 add / subs
-- (combinations of two of the previous values)
-- 
-- ** PORT DESCRIPTION **
-- rst -> Synchronous reset port. A reset ONLY initializes some seq elements to a initial known state, but does not reset some big internal storage elements as buffers (see FA). It's stupid as the presence of a FA will always mean that a big initial # of samples are needed to obtain stable output.
--
-- Dependencies:
-- 
-- *** Changelog ***
-- Revision 0.01 - File Created
-- 
--------------------------------------------------------------------------------

library WORK;
use WORK.COMMON.all;
library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity park_transform is
        generic (
                width : natural := PIPELINE_WIDTH;
                prec : natural := PIPELINE_PREC);
        port (
                a,b,c : in std_logic_vector(width - 1 downto 0);
                cos, sin : in std_logic_vector(width - 1 downto 0);
                d,q : out std_logic_vector(width - 1 downto 0));
end park_transform;

architecture structural of park_transform is
        constant sin_2_pi_3 : real := 0.86602540378444;
        constant cos_2_pi_3 : real := -0.50000000000000;
        constant alfa : real := (2.0/3.0) * sin_2_pi_3;
        constant beta : real := (2.0/3.0) * cos_2_pi_3;

        signal alfa_cos_s, beta_cos_s, m_alfa_sin_s, beta_sin_s : std_logic_vector(width - 1 downto 0);
        signal m_sin_p_2pi_3_s, m_sin_m_2pi_3_s, cos_p_2pi_3_s, cos_m_2pi_3_s : std_logic_vector(width - 1 downto 0);
        signal scaled_cos_s, scaled_sin_s : std_logic_vector(width - 1 downto 0);
        signal d_comp_1_s, d_comp_2_s, d_comp_3_s, q_comp_1_s, q_comp_2_s, q_comp_3_s : std_logic_vector(width - 1 downto 0);
        
begin  -- structural
        kcm_1_i : entity work.kcm(beh)
                generic map (
                        width => width,
                        prec  => prec,
                        k     => alfa)
                port map (
                        i => cos,
                        o => alfa_cos_s);

        kcm_2_i : entity work.kcm(beh)
                generic map (
                        width => width,
                        prec  => prec,
                        k     => beta)
                port map (
                        i => cos,
                        o => beta_cos_s);

        kcm_3_i : entity work.kcm(beh)
                generic map (
                        width => width,
                        prec  => prec,
                        k     => -alfa)
                port map (
                        i => sin,
                        o => m_alfa_sin_s);

        kcm_4_i : entity work.kcm(beh)
                generic map (
                        width => width,
                        prec  => prec,
                        k     => beta)
                port map (
                        i => sin,
                        o => beta_sin_s);

        add_1_i : entity work.subsor(alg)
                generic map (
                        width => width)
                port map (
                        a => m_alfa_sin_s,
                        b => beta_cos_s,
                        o => m_sin_p_2pi_3_s,
                        f_ov => open, f_z => open);

        add_2_i : entity work.adder(alg)
                generic map (
                        width => width)
                port map (
                        a => m_alfa_sin_s,
                        b => beta_cos_s,
                        o => m_sin_m_2pi_3_s,
                        f_ov => open, f_z => open);

        add_3_i : entity work.subsor(alg)
                generic map (
                        width => width)
                port map (
                        a => alfa_cos_s,
                        b => beta_sin_s,
                        o => cos_p_2pi_3_s,
                        f_ov => open, f_z => open);

        add_4_i : entity work.adder(alg)
                generic map (
                        width => width)
                port map (
                        a => alfa_cos_s,
                        b => beta_sin_s,
                        o => cos_m_2pi_3_s,
                        f_ov => open, f_z => open);
        
        kcm_5_i : entity work.kcm(beh)
                generic map (
                        width => width,
                        prec  => prec,
                        k     => 2.0/3.0)
                port map (
                        i => cos,
                        o => scaled_cos_s);

        kcm_6_i : entity work.kcm(beh)
                generic map (
                        width => width,
                        prec  => prec,
                        k     => -2.0/3.0)
                port map (
                        i => sin,
                        o => scaled_sin_s);

        d_mul_1_i : entity work.mul(beh)
                generic map (
                        width => width,
                        prec  => prec)
                port map (
                        a => a,
                        b => scaled_cos_s,
                        o => d_comp_1_s);
        
        d_mul_2_i : entity work.mul(beh)
                generic map (
                        width => width,
                        prec  => prec)
                port map (
                        a => b,
                        b => cos_m_2pi_3_s,
                        o => d_comp_2_s);

        d_mul_3_i : entity work.mul(beh)
                generic map (
                        width => width,
                        prec  => prec)
                port map (
                        a => c,
                        b => cos_p_2pi_3_s,
                        o => d_comp_3_s);

        d_tri_adder : entity work.tri_adder(beh)
                generic map (
                        width => width)
                port map (
                        a    => d_comp_1_s,
                        b    => d_comp_2_s,
                        c    => d_comp_3_s,
                        o    => d,
                        f_ov => open,
                        f_z  => open);

        q_mul_1_i : entity work.mul(beh)
                generic map (
                        width => width,
                        prec  => prec)
                port map (
                        a => a,
                        b => scaled_sin_s,
                        o => q_comp_1_s);
        
        q_mul_2_i : entity work.mul(beh)
                generic map (
                        width => width,
                        prec  => prec)
                port map (
                        a => b,
                        b => m_sin_m_2pi_3_s,
                        o => q_comp_2_s);

        q_mul_3_i : entity work.mul(beh)
                generic map (
                        width => width,
                        prec  => prec)
                port map (
                        a => c,
                        b => m_sin_p_2pi_3_s,
                        o => q_comp_3_s);

        q_tri_adder : entity work.tri_adder(beh)
                generic map (
                        width => width)
                port map (
                        a    => q_comp_1_s,
                        b    => q_comp_2_s,
                        c    => q_comp_3_s,
                        o    => q,
                        f_ov => open,
                        f_z  => open);
end structural;
