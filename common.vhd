library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;

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
	constant PIPELINE_PREC : natural := 13;
	constant EXT_PIPELINE_PREC : natural := PIPELINE_PREC;
	constant PIPELINE_MAGN : natural := PIPELINE_WIDTH - PIPELINE_PREC;
	constant EXT_PIPELINE_MAGN : natural := EXT_PIPELINE_WIDTH - EXT_PIPELINE_PREC;
	constant PIPELINE_WIDTH_DIR_BITS : natural := 4; -- natural(ceil(log2(real(PIPELINE_WIDTH))));
	-- CURRENT CONFIG:
	-- >> SAMPLE RATE: 10 KHz
	constant SAMPLE_PERIOD_FX316 : pipeline_integer := 1; -- NOT ENOUGH PRECISION: 0.8192!! BE CAREFULL!!
	constant SAMPLE_PERIOD_FX316_S : signed(PIPELINE_WIDTH - 1 downto 0) := B"0_00_00000_00000001";

	constant AC_FREQ_SAMPLE_SCALED_FX316 : pipeline_integer := 257; -- 2*Pi*50*Ts*2^PIPELINE_PREC
                                                                        -- = 257.35
	constant AC_FREQ_SAMPLE_SCALED_FX316_S : signed(PIPELINE_WIDTH - 1 downto 0) := B"0_00_00001_00000001";

	-- Math constants
	constant EXAMPLE_VAL_FX316 : pipeline_integer := 26312;
	constant ZERO_FX316_V : std_logic_vector(PIPELINE_WIDTH - 1 downto 0) := (others => '0');
	constant CORDIC_GAIN : pipeline_integer := 13490;
	constant CORDIC_GAIN_V : std_logic_vector(PIPELINE_WIDTH - 1 downto 0) := X"34B2";
	constant INV_CORDIC_GAIN : pipeline_integer := 4975;
	constant INV_CORDIC_GAIN_V : std_logic_vector(PIPELINE_WIDTH - 1 downto 0) := X"136F";
	constant MINUS_INV_CORDIC_GAIN : pipeline_integer := -4975;
	constant MINUS_INV_CORDIC_GAIN_V : std_logic_vector(PIPELINE_WIDTH -1 downto 0) := X"EC91";
	constant HALF_PI_FX316 : pipeline_integer := 12868;
	constant HALF_PI_FX316_V : std_logic_vector(PIPELINE_WIDTH - 1 downto 0) := X"3244";
        constant HALF_PI_FX318_V : std_logic_vector(EXT_PIPELINE_WIDTH - 1 downto 0) := "000011001001000100";
	constant MINUS_HALF_PI_FX316 : pipeline_integer := -12868;
	constant MINUS_HALF_PI_FX316_V : std_logic_vector(PIPELINE_WIDTH - 1 downto 0) := X"CDBC";
        constant MINUS_HALF_PI_FX318_V : std_logic_vector(EXT_PIPELINE_WIDTH - 1 downto 0) := "111100110110111100";
	constant PI_FX316 : pipeline_integer := 25736;
	constant PI_FX316_V : std_logic_vector(PIPELINE_WIDTH - 1 downto 0) := X"6488";
        constant PI_FX318_V : std_logic_vector(EXT_PIPELINE_WIDTH - 1 downto 0) := "000110010010001000";
	constant MINUS_PI_FX316 : pipeline_integer := -25736;
        constant MINUS_PI_FX318_V : std_logic_vector(EXT_PIPELINE_WIDTH - 1 downto 0) := "111001101101111000";
	constant MINUS_TWO_PI_FX417_V : std_logic_vector(PIPELINE_WIDTH downto 0) := B"1_001_10110_11110000";

	-- Filter constants
	-- constant PHASE_LOOP_PI_I_CONST_FX316 : pipeline_integer := xxx; OVERFLOW!!!
	constant PHASE_LOOP_PI_I_CONST_SAMPLE_SCALED : pipeline_integer := 122;
	constant PHASE_LOOP_PI_P_CONST : pipeline_integer := 32767; -- OVERFLOW!!!
	
end common;


package body common is
end common;
