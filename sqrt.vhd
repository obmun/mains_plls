--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    
-- Design Name:    
-- Module Name:    sqrt - alg
-- Project Name:   
-- Target Device:  
-- Tool versions:
-- 
-- *** Description ***
-- Non restoring iterative SQRT implementation.
-- Achieves low precision (just 9 bits => 9 + 1 cycles, taking into
-- account precision + magnitude bits) but an analysis of the app
-- (input signal normalization) shows that 7 precision bits are more
-- than enough.
--
-- Dependencies:
-- 
-- Revision:
-- Revision 0.03 - Better parametrization
-- Revision 0.02 - Some corrections (one bit negated) were making tests results fail. Test is passed now
-- Revision 0.01 - Original implementation
-- Additional Comments:
-- 
--------------------------------------------------------------------------------
library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use WORK.COMMON.all;

entity sqrt is
        -- rev 0.02
        generic (
                width : natural := PIPELINE_WIDTH;
                prec  : natural := PIPELINE_PREC);
	port (
		clk, rst, run : in std_logic;
		i : in std_logic_vector(18 - 1 downto 0); -- In RADIANS!
		o : out std_logic_vector(18 - 1 downto 0);
		done, error_p : out std_logic);
end sqrt;

architecture alg of sqrt is
	-- Types
	type state_t is (
		ST_DONE, ST_INIT, ST_RUNNING, ST_LAST, ST_ERROR
	);

	-- Constants
	constant width : natural := 18; -- Hardcoded extended pipeline width

	-- Component declaration
	component shift_reg is
		generic (
			width : natural := PIPELINE_WIDTH;
			dir : shift_dir_t := SD_LEFT;
			step_s : natural := 1
		);
		port (
			clk, load, we : in std_logic;
			s_in : in std_logic_vector(step_s - 1 downto 0);
			p_in : in std_logic_vector(width - 1 downto 0);
			o : out std_logic_vector(width - 1 downto 0)
		);
	end component;

	-- **** WORKAROUND FOR XILINX XST PROBLEM (7.1i) **** --
	component d_shift_reg is
		generic (
			width : natural := PIPELINE_WIDTH;
			dir : shift_dir_t := SD_LEFT
		);
		port (
			clk, load, we : in std_logic;
			p_in : in std_logic_vector(width - 1 downto 0);
			o : out std_logic_vector(width - 1 downto 0)
		);
	end component;

	component reg is
		generic (
			width : natural := PIPELINE_WIDTH
		);
		port (
			clk, we, rst : in std_logic;
			i : in std_logic_vector (width - 1 downto 0);
			o : out std_logic_vector (width - 1 downto 0)
		);
	end component;

	component add_sub is
		generic (
			width : natural := PIPELINE_WIDTH
		);
		port (
			a, b: in std_logic_vector(width - 1 downto 0);
			add_nsub : in std_logic;
			o: out std_logic_vector(width - 1 downto 0);
			f_ov, f_z: out std_logic
		);
	end component;

	-- Internal control signals
	signal step : std_logic_vector(3 downto 0);
	signal save, init : std_logic;
	signal st : state_t;
	signal r_reg_rst : std_logic;

	-- Internal data signals and aliases
	signal adder_out, r_reg_out : std_logic_vector(10 downto 0);
	signal q_reg_out, res_reg_out : std_logic_vector(8 downto 0);
	signal d_reg_out_hi : std_logic_vector(1 downto 0);
	signal n_adder_msb : std_logic;
	alias r_msb : std_logic is r_reg_out(10);
	alias adder_msb : std_logic is adder_out(10);
	
	-- Garbage
	signal garbage_16 : std_logic_vector(15 downto 0);
	
	-- Other
	alias i_msb : std_logic is i(18 - 1);
begin
	q_reg : shift_reg
		generic map (
			width => 9,
			dir => SD_LEFT, step_s => 1
		)
		port map (
			clk => clk, load => init, we => '1',
			s_in(0) => n_adder_msb,
			-- Xilinx does not accept THIS: p_in => (others => '0'),
			p_in => std_logic_vector(to_unsigned(0, 9)),
			o => q_reg_out
		);

	d_reg : shift_reg
		generic map (
			width => width,
			dir => SD_LEFT, step_s => 2
		)
		port map (
			clk => clk, load => init, we => '1',
			s_in => B"00",
			p_in(17 downto 1) => i(16 downto 0), p_in(0) => '0',
			-- o(width - 1 downto width - 2) => d_reg_out_hi, o(width - 3 downto 0) => open || Incorrect LRM section 1.1.1.2
			o(width - 1 downto width - 2) => d_reg_out_hi, o(width - 3 downto 0) => garbage_16
		);

	adder : add_sub
		generic map (
			width => 11
		)
		port map (
			b(10 downto 2) => q_reg_out, b(1) => r_msb, b(0) => '1',
			a(1 downto 0) => d_reg_out_hi(1 downto 0), a(10 downto 2) => r_reg_out(8 downto 0),-- OR IT'S THE OTHER WAY (a <-> b)?
			add_nsub => r_msb,
			o => adder_out,
			f_ov => open, f_z => open
		);
			
	r_reg : reg
		generic map (
			width => 11
		)
		port map (
			clk => clk, we => '1', rst => r_reg_rst,
			i => adder_out,
			o => r_reg_out
		);

	res_reg : reg
		generic map (
			width => 9
		)
		port map (
			clk => clk, we => save, rst => rst,
			i(8 downto 1) => q_reg_out(7 downto 0), i(0) => n_adder_msb,
			o => res_reg_out
		);

	state_ctrl : process(clk, rst)
	begin
		if (rst = '1') then
			st <= ST_DONE;
		else
			if (rising_edge(clk)) then
				case st is
					when ST_DONE =>
						if (run = '1') then
							st <= ST_INIT;
						else
							st <= ST_DONE;
						end if;
					when ST_INIT =>
						if (i_msb = '0') then
							st <= ST_RUNNING;
						else
							st <= ST_ERROR;
						end if;
					when ST_RUNNING =>
						if (step = "0111") then
							st <= ST_LAST;
						else
							st <= ST_RUNNING;
						end if;
					when ST_LAST =>
						if (run = '1') then
							st <= ST_INIT;
						else
							st <= ST_DONE;
						end if;
					when ST_ERROR =>
						if (run = '1') then
							st <= ST_INIT;
						else
							st <= ST_ERROR;
						end if;
					when others =>
						report "Unkown state!!! Should not happen!!!"
						severity error;
						st <= st;
				end case;
			else
				null;
			end if;
		end if;
	end process state_ctrl;

	step_counter : process(clk)
		subtype step_counter_t is natural range 0 to 8;
		variable step_counter : step_counter_t;
	begin
		if (rising_edge(clk)) then
			if (init = '1') then
				step_counter := 0;
			else
				-- Just fold if I'm out of range
				if (step_counter = step_counter_t'high) then
					step_counter := 0;
				else
					step_counter := step_counter + 1;
				end if;
			end if;
		end if;
		step <= std_logic_vector(to_unsigned(step_counter,4));
	end process;

	signals_gen : process(st)
	begin
		case st is
			when ST_DONE =>
				init <= '0';
				save <= '0';
				done <= '1';
				error_p <= '0';
			when ST_INIT =>
				init <= '1';
				save <= '0';
				done <= '0';
				error_p <= '0';
			when ST_RUNNING =>
				init <= '0';
				save <= '0';
				done <= '0';
				error_p <= '0';
			when ST_LAST =>
				save <= '1';
				init <= '0';
				done <= '1';
				error_p <= '0';
			when ST_ERROR =>
				save <= '0';
				init <= '0';
				done <= '0';
				error_p <= '1';
		end case;
	end process signals_gen;

    r_reg_rst <= rst or init;
    n_adder_msb <= not adder_msb;

	o(17 downto 15) <= (others => '0');
	o(14 downto 6) <= res_reg_out;
	o(5 downto 0) <= (others => '0');
end alg;
