--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity sqrt_tb is
end sqrt_tb;

architecture alg of sqrt_tb is
        component sqrt is
                -- rev 0.02
		port (
			clk, rst, run : in std_logic;
			i : in std_logic_vector(18 - 1 downto 0);
			o : out std_logic_vector(18 - 1 downto 0);
			done, error_p : out std_logic
		);
	end component;

	signal clk_s, rst, run : std_logic;
	signal i, o : std_logic_vector(17 downto 0);
	signal done, error_s : std_logic;

        constant CLK_PERIOD : time := 20 ns;
begin

	sqrt_i : sqrt
		port map (
			clk_s, rst, run,
			i, o,
			done, error_s);

	signal_gen : process
	begin
		run <= '0';
		i <= (others => '0');
		rst <= '1';
		wait for 30 ns;
		rst <= '0';
		wait for 70 ns;
		-- 1st calc cycle
		run <= '1';
		i <= std_logic_vector(to_unsigned(0, 18));
                -- Output should be 0 FX5.18
		wait on done until to_x01(done) = '0';
		run <= '0';
		wait on done until to_x01(done) = '1';
		-- 2nd calc cycle
                run <= '1';
                i <= std_logic_vector(to_signed(4*8192, 18)); -- 4 FX5.18
                -- Output should be 2 FX5.18
                wait on done until to_x01(done) = '0';
                run <= '0';
                wait on done until to_x01(done) = '1';
                -- 3rd calc cycle
                run <= '1';
                i <= std_logic_vector(to_signed(124798, 18)); -- 15.2341 FX5.18
                -- Output should be 3.90308 FX5.18 =aprox 31974 
                wait on done until to_x01(done) = '0';
                run <= '0';
                wait on done until to_x01(done) = '1';
                -- 4th calc cycle
                run <= '1';
                i <= std_logic_vector(to_signed(131071, 18)); -- 15.99987793 FX5.18 (highest possible FX5.18 value)
                wait on done until to_x01(done) = '0';
                run <= '0';
                wait on done until to_x01(done) = '1';
                wait;
--        -- 5th calc cycle
--        run <= '1';
--        angle <= std_logic_vector(to_signed(MINUS_PI_FX316 + 1, 16));
--        wait on done until to_x01(done) = '0';
--        run <= '0';
--        wait on done until to_x01(done) = '1';                  
	end process;

        clock : process
        begin
                clk_s <= '0';
                wait for CLK_PERIOD / 2;
                clk_s <= '1';
                wait for CLK_PERIOD / 2;
        end process clock;
end alg;
