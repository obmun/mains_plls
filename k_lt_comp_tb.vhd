library IEEE;
library WORK;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use work.common.all;

entity k_lt_comp_tb is
end entity;

architecture alg of k_lt_comp_tb is
	component k_lt_comp is
		generic (
			width : natural := PIPELINE_WIDTH;
			k : pipeline_integer := 0
		);
		port (
			a : in std_logic_vector(width - 1 downto 0);
			a_lt_k : out std_logic
		);
	end component;

	signal a_s : std_logic_vector(15 downto 0);
	signal a_lt_k_s : std_logic;
begin
	k_lt_comp_i : k_lt_comp
		generic map (
			width => 16,
			k => MINUS_HALF_PI_FX316
		)
		port map (
			a => a_s,
			a_lt_k => a_lt_k_s
		);

	signal_gen : process
	begin
	    wait for 25 ns;
	    a_s <= HALF_PI_FX316_V;
		wait for 50 ns;
		a_s <= ZERO_FX316_V;
		wait for 50 ns;
		a_s <= MINUS_HALF_PI_FX316_V;
		wait for 50 ns;
		a_s <= std_logic_vector(to_signed(-30000, 16));
		wait;	
	end process;
end architecture;
