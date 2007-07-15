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
-- Description:
--
-- Dependencies:
-- 
-- Todo:
-- | > Check if alfa^-1 and -beta / alfa values can be automatically calculated from Kp. Right now user has to precalc them.
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
--------------------------------------------------------------------------------
library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use WORK.COMMON.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity first_order_lpf is
	generic (
		width : natural := PIPELINE_WIDTH
	);
	port (
		clk, we, rst : in std_logic;
		i_port : in std_logic_vector(width - 1 downto 0);
		o_port : out std_logic_vector(width - 1 downto 0)
	);
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

	component reg is
		generic (
			width : natural := PIPELINE_WIDTH
		);
		port (
			clk, we, rst : in std_logic;
			i : in std_logic_vector(width - 1 downto 0);
			o : out std_logic_vector(width - 1 downto 0)
		);
	end component;

	signal i_kcm_out, fb_adder_out, reg_adder_out, delay_out, fb_kcm_out : std_logic_vector(width - 1 downto 0);
begin
	i_kcm : kcm
		generic map (
			k => 390 -- 0,047619047
		)
		port map (
			i => i_port,
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
			f_ov => open, f_z => open
		);

	reg_adder : adder
		port map (
			a => fb_adder_out, b => i_port,
			o => reg_adder_out,
			f_ov => open, f_z => open
		);

	delay : reg
		port map (
			clk => clk, we => we, rst => rst,
			i => reg_adder_out,
			o => delay_out
		);

	o_port <= fb_adder_out;
end alg;