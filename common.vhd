library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;                 -- round function, and others?

package common is
	-- *
	-- * My types
	-- *
	subtype pipeline_integer is integer range -32768 to 32767;
	type shift_dir_t is (SD_LEFT, SD_RIGHT);

	-- *
	-- * Constants
	-- *
	-- Non math constants
	constant PIPELINE_WIDTH : natural := 16;
	constant EXT_PIPELINE_WIDTH : natural := 18;
	constant PIPELINE_PREC : natural := 12;
        constant PIPELINE_PREC_WEIGHT : natural := 4096;
	constant EXT_PIPELINE_PREC : natural := PIPELINE_PREC;
	constant PIPELINE_MAGN : natural := PIPELINE_WIDTH - PIPELINE_PREC;
	constant EXT_PIPELINE_MAGN : natural := EXT_PIPELINE_WIDTH - EXT_PIPELINE_PREC;
	constant PIPELINE_WIDTH_DIR_BITS : natural := 4; -- natural(ceil(log2(real(PIPELINE_WIDTH))));
	-- CURRENT CONFIG:
	-- >> SAMPLE RATE: 10 KHz
	constant SAMPLE_PERIOD_FX316 : pipeline_integer := 1; -- NOT ENOUGH PRECISION: 0.8192!! BE CAREFULL!!
	constant SAMPLE_PERIOD_FX316_S : signed(PIPELINE_WIDTH - 1 downto 0) := B"0_00_00000_00000001";
        constant SAMPLE_PERIOD_FX416 : pipeline_integer := 0; -- NOT ENOUGH PRECISION: 0.4096!! BE CAREFULL!!
	constant SAMPLE_PERIOD_FX416_S : signed(PIPELINE_WIDTH - 1 downto 0) := B"0_00_00000_00000000";

        constant AC_FREQ_SAMPLE_SCALED : real := 0.031416; -- 2*Pi*50*Ts

	-- Math constants
	constant EXAMPLE_VAL_FX316 : pipeline_integer := 26312;
        constant EXAMPLE_VAL_FX416 : pipeline_integer := 26312;
	constant ZERO_FX316_V : std_logic_vector(PIPELINE_WIDTH - 1 downto 0) := (others => '0');
        constant ZERO_FX416_V : std_logic_vector(PIPELINE_WIDTH - 1 downto 0) := (others => '0');
	constant CORDIC_GAIN : pipeline_integer := 13490;
	constant CORDIC_GAIN_V : std_logic_vector(PIPELINE_WIDTH - 1 downto 0) := X"34B2";
        -- constant CORDIC_GAIN : pipeline_integer := 13490;
	-- constant CORDIC_GAIN_V : std_logic_vector(PIPELINE_WIDTH - 1 downto 0) := X"34B2";
	constant INV_CORDIC_GAIN : pipeline_integer := 4975;
	constant INV_CORDIC_GAIN_V : std_logic_vector(PIPELINE_WIDTH - 1 downto 0) := X"136F";
	constant MINUS_INV_CORDIC_GAIN : pipeline_integer := -4975;
	constant MINUS_INV_CORDIC_GAIN_V : std_logic_vector(PIPELINE_WIDTH -1 downto 0) := X"EC91";
	constant HALF_PI_FX316 : pipeline_integer := 12868;
	constant HALF_PI_FX316_V : std_logic_vector(PIPELINE_WIDTH - 1 downto 0) := X"3244";
        constant HALF_PI_FX416 : pipeline_integer := 6434;
	constant HALF_PI_FX416_V : std_logic_vector(PIPELINE_WIDTH - 1 downto 0) := X"1922";
        constant HALF_PI_FX318_V : std_logic_vector(EXT_PIPELINE_WIDTH - 1 downto 0) := "000011001001000100";
	constant MINUS_HALF_PI_FX316 : pipeline_integer := -12868;
	constant MINUS_HALF_PI_FX316_V : std_logic_vector(PIPELINE_WIDTH - 1 downto 0) := X"CDBC";
        constant MINUS_HALF_PI_FX416 : pipeline_integer := -6434;
	constant MINUS_HALF_PI_FX416_V : std_logic_vector(PIPELINE_WIDTH - 1 downto 0) := X"E6DE";
        constant MINUS_HALF_PI_FX318_V : std_logic_vector(EXT_PIPELINE_WIDTH - 1 downto 0) := "111100110110111100";
	constant PI_FX316 : pipeline_integer := 25736;
	constant PI_FX316_V : std_logic_vector(PIPELINE_WIDTH - 1 downto 0) := X"6488";
        constant PI_FX416 : pipeline_integer := 12868;
	constant PI_FX416_V : std_logic_vector(PIPELINE_WIDTH - 1 downto 0) := X"3244";
        constant PI_FX318_V : std_logic_vector(EXT_PIPELINE_WIDTH - 1 downto 0) := "000110010010001000";
	constant MINUS_PI_FX316 : pipeline_integer := -25736;
        constant MINUS_PI_FX318_V : std_logic_vector(EXT_PIPELINE_WIDTH - 1 downto 0) := "111001101101111000";
	constant MINUS_TWO_PI_FX417_V : std_logic_vector(PIPELINE_WIDTH downto 0) := B"1_001_10110_11110000";

	-- Filter constants
        constant PHASE_LOOP_PI_I_CONST : real := 1000.0;
        constant PHASE_LOOP_PI_P_CONST : real := 100.0;

        function to_pipeline_integer ( val : real ) return integer;
        function to_pipeline_vector ( val : real ) return std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
end common;


package body common is
        function to_pipeline_integer ( val : real ) return integer is
                variable tmp_val : integer;
        begin
                tmp_val := integer(round(val * real(PIPELINE_PREC_WEIGHT)));
                if (tmp_val > pipeline_integer'high) then
                        return pipeline_integer'high;
                elsif (tmp_val < pipeline_integer'low) then
                        return pipeline_integer'low;
                else
                        return tmp_val;
                end if;
        end;

        function to_pipeline_vector ( val : real ) return std_logic_vector(PIPELINE_WIDTH - 1 downto 0) is
        begin
                return std_logic_vector(to_signed(to_pipeline_integer(val, PIPELINE_WIDTH)));
        end;
end common;
