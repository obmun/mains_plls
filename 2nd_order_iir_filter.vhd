--------------------------------------------------------------------------------
-- Company: UVigo
-- Engineer: Jacobo Cabaleiro
--
-- Create Date:    
-- Design Name:    
-- Module Name: filter - beh
-- Project Name:   
-- Target Device:  
-- Tool versions:  
--
-- === SPECS ===
-- Latency: 1 clk [when wake up] / 0 clks
-- Throughoutput: 1 sample / clk
-- 
-- === Brief DESCRIPTION ===
-- Class: sequential
-- 2nd order IIR filter, implemented with a Transposed-Form IIR filter
-- structure.
--
-- === Description ===
-- The IIR form which better stands coefficient quantization artifacts is the
-- IIR cascade form. We're implementing a Transposed-Form because it minimizes
-- the # of adders and memory elements to be used (see http://cnx.org/content/m11919/latest/)
--
-- Implements the following transfer function (in z):
--  b_0 + b_1 * z^-1 + b_2 * z^-2
-- -------------------------------
--   1 + a_1 * z^-1 + a_2 * z^-2
--
-- == Ports ==
-- See block_interfaces.txt for description of the digital block interface.
-- = Generics =
-- * width: ports and internal pipeline width
-- * prec: ports and internal pipeline precision
-- * b0, b1, b2, a1, a2: see previous transfer function. Self-explained.
-- = Inputs =
-- -> CLK
-- -> RST: synchronous reset
-- -> RUN: 
-- = Outputs =
-- -> 
-- 
-- === Changelog ===
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
--------------------------------------------------------------------------------
library IEEE;
use WORK.COMMON.all;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity filter_2nd_order_iir is
        generic (
                width : natural := PIPELINE_WIDTH;
                prec  : natural := PIPELINE_PREC;
                b0 : real;
                b1 : real;
                b2 : real;
                a1 : real;
                a2 : real;
                -- Seq. block iface
                delayer_width : natural := 1);
        port (
                clk, rst : in std_logic;
                i : in std_logic_vector(width - 1 downto 0);
                o : out std_logic_vector(width - 1 downto 0);
                run_en : in std_logic;
                run_passthru : out std_logic;
                delayer_in : in std_logic_vector(delayer_width - 1 downto 0);
                delayer_out : out std_logic_vector(delayer_width - 1 downto 0));
end filter_2nd_order_iir;


architecture beh of filter_2nd_order_iir is
        signal o_s : std_logic_vector(width - 1 downto 0);
        signal b0_mult_out_s, b1_mult_out_s, b2_mult_out_s : std_logic_vector(width - 1 downto 0);
        signal a1_mult_out_s, a2_mult_out_s : std_logic_vector(width - 1 downto 0);
        signal z1_out_s, z2_out_s : std_logic_vector(width - 1 downto 0);
        signal z1_adder_out_s, z2_adder_out_s : std_logic_vector(width - 1 downto 0);

        signal delayer_in_s, delayer_out_s : std_logic_vector(delayer_width - 1 downto 0);
begin  -- beh
        b0_mult : entity work.kcm(beh)
                generic map (
                        width => width,
                        prec => prec,
                        k => b0)
                port map (
                        i => i,
                        o => b0_mult_out_s);
        
        z0_adder : entity work.adder(alg)
                generic map (
                        width => width)
                port map (
                        a => b0_mult_out_s,
                        b => z1_out_s,
                        o => o_s,
                        f_ov => open,
                        f_z => open);

        z1 : entity work.reg(alg)
                generic map (
                        width => width)
                port map (
                        clk => clk,
                        we  => run_en,
                        rst => rst,
                        i   => z1_adder_out_s,
                        o   => z1_out_s);

        z1_adder : entity work.tri_adder(beh)
                generic map (
                        width => width)
                port map (
                        a => b1_mult_out_s,
                        b => a1_mult_out_s,
                        c => z2_out_s,
                        o => z1_adder_out_s,
                        f_ov => open,
                        f_z => open);

        b1_mult : entity work.kcm(beh)
                generic map (
                        width => width,
                        prec => prec,
                        k => b1)
                port map (
                        i => i,
                        o => b1_mult_out_s);

        a1_mult : entity work.kcm(beh)
                generic map (
                        width => width,
                        prec => prec,
                        k => -a1)
                port map (
                        i => o_s,
                        o => a1_mult_out_s);

        z2 : entity work.reg(alg)
                generic map (
                        width => width)
                port map (
                        clk => clk,
                        we  => run_en,
                        rst => rst,
                        i   => z2_adder_out_s,
                        o   => z2_out_s);

        z2_adder : entity work.adder(alg)
                generic map (
                        width => width)
                port map (
                        a => b2_mult_out_s,
                        b => a2_mult_out_s,
                        o => z2_adder_out_s,
                        f_ov => open,
                        f_z => open);

        b2_mult : entity work.kcm(beh)
                generic map (
                        width => width,
                        prec => prec,
                        k => b2)
                port map (
                        i => i,
                        o => b2_mult_out_s);

        a2_mult : entity work.kcm(beh)
                generic map (
                        width => width,
                        prec => prec,
                        k => -a2)
                port map (
                        i => o_s,
                        o => a2_mult_out_s);

        o <= o_s;

        delayer : entity work.reg(alg)
                generic map (
                        width => delayer_width)
		port map (
			clk => clk, we => '1', rst => rst,
			i => delayer_in_s,
			o => delayer_out_s);

        single_delayer_gen: if (delayer_width = 1) generate
                delayer_in_s(0) <= run_en;
                run_passthru <= std_logic(delayer_out_s(0));
                delayer_out(0) <= delayer_out_s(0);
        end generate single_delayer_gen;
        
        broad_delayer_gen: if (delayer_width > 1) generate
                delayer_in_s(0) <= run_en;
                delayer_in_s(delayer_width - 1 downto 1) <= delayer_in(delayer_width - 1 downto 1);
                run_passthru <= std_logic(delayer_out_s(0));
                delayer_out <= delayer_out_s;
        end generate broad_delayer_gen;
end beh;
                    
