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
-- 1st order IIR filter, implemented with a Transposed-Form IIR filter
-- structure. Implementation is derived from 2nd_order_iir_filter, just with
-- some elements removed
--
-- === Description ===
-- See 2nd_order_iir_filter.vhd for more details.
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

entity filter_1st_order_iir is
        generic (
                width : natural := PIPELINE_WIDTH;
                prec  : natural := PIPELINE_PREC;
                b0 : real;
                b1 : real;
                a1 : real;
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
end filter_1st_order_iir;


architecture beh of filter_1st_order_iir is
        signal o_s : std_logic_vector(width - 1 downto 0);
        signal b0_mult_out_s, b1_mult_out_s : std_logic_vector(width - 1 downto 0);
        signal a1_mult_out_s : std_logic_vector(width - 1 downto 0);
        signal z1_out_s : std_logic_vector(width - 1 downto 0);
        signal z1_adder_out_s : std_logic_vector(width - 1 downto 0);
        
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

        z1_adder : entity work.adder(alg)
                generic map (
                        width => width)
                port map (
                        a => b1_mult_out_s,
                        b => a1_mult_out_s,
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
                    
