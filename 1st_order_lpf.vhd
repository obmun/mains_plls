--------------------------------------------------------------------------------
-- Company: Universidad de Vigo
-- Engineer: Jacobo Cabaleiro
--
-- Create Date:    
-- Design Name:    
-- Module Name:    1st_order_lpf - alg
-- Project Name:   
-- Target Device:  
-- Tool versions:
--
-- *** Brief description ***
-- Class: sequential block
--
-- *** Description ***
-- ** Ports **
-- * Inputs *
--
-- Dependencies:
-- 
-- Todo:
-- > Check if alfa^(-1) and -beta / alfa values can be automatically calculated from Kp. Right now user has to precalc them.
--
-- *** ChangeLog ***
-- Revision 0.03 - Converted to new sequential block interface
-- Revision 0.02 - Added RUN/DONE interface
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
--------------------------------------------------------------------------------
library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use WORK.COMMON.all;

entity first_order_lpf is
        -- rev 0.03
	generic (
		width : natural := PIPELINE_WIDTH;
                delayer_width : natural := 1);
        
	port (
		clk, rst : in std_logic;
		i : in std_logic_vector(width - 1 downto 0);
		o : out std_logic_vector(width - 1 downto 0);
                run_en : in std_logic;
                run_passthru : out std_logic;
                delayer_in : in std_logic_vector(delayer_width - 1 downto 0);
                delayer_out : out std_logic_vector(delayer_width - 1 downto 0));
end first_order_lpf;

architecture alg of first_order_lpf is
	component kcm
		generic (
			width : natural := PIPELINE_WIDTH;
			prec : natural := PIPELINE_PREC;
			k : pipeline_integer := -23410 -- Cte de ejemplo. Una síntesis de esta cte infiere un multiplicador
		);
		port (
			i : in std_logic_vector(width - 1 downto 0);
			o : out std_logic_vector(width - 1 downto 0)
		);
	end component;

	component adder is
		generic (
			width : natural := PIPELINE_WIDTH
		);
		port (
			a, b: in std_logic_vector(width - 1 downto 0);
			o: out std_logic_vector(width - 1 downto 0);
			f_ov, f_z: out std_logic
		);
	end component;

	signal i_kcm_out, fb_adder_out, reg_adder_out, delay_out, fb_kcm_out : std_logic_vector(width - 1 downto 0);
        signal delayer_in_s, delayer_out_s : std_logic_vector(delayer_width - 1 downto 0);
begin
	i_kcm : kcm
		generic map (
			k => 390 -- 0,047619047
		)
		port map (
			i => i,
			o => i_kcm_out
		);

	fb_kcm : kcm
		generic map (
			k => 7412 -- 0,904761
		)
		port map (
			i => delay_out,
			o => fb_kcm_out
		);

	fb_adder : adder
		port map (
			a => i_kcm_out, b => fb_kcm_out,
			o => fb_adder_out,
			f_ov => open, f_z => open);

	reg_adder : adder
		port map (
			a => fb_adder_out, b => i,
			o => reg_adder_out,
			f_ov => open, f_z => open
		);

	delay : entity work.reg(alg)
                generic map (
                        width => width)
		port map (
			clk => clk, we => run_en, rst => rst,
			i => reg_adder_out,
			o => delay_out);

	o <= fb_adder_out;

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
end alg;
