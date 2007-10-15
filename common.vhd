library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;                 -- round function, ** (power), and ...
                                        -- others?

package common is

	type shift_dir_t is (SD_LEFT, SD_RIGHT);

	-- *
	-- * Very first constants
	-- *
	constant PIPELINE_WIDTH : natural := 16;
	constant EXT_PIPELINE_WIDTH : natural := 18;
	constant PIPELINE_PREC : natural := 12;
        constant PIPELINE_PREC_WEIGHT : natural := 4096;
	constant EXT_PIPELINE_PREC : natural := PIPELINE_PREC;
        constant EXT_PIPELINE_PREC_WEIGHT : natural := PIPELINE_PREC_WEIGHT;
	constant PIPELINE_MAGN : natural := PIPELINE_WIDTH - PIPELINE_PREC;
	constant EXT_PIPELINE_MAGN : natural := EXT_PIPELINE_WIDTH - EXT_PIPELINE_PREC;
	constant PIPELINE_WIDTH_DIR_BITS : natural := 4; -- natural(ceil(log2(real(PIPELINE_WIDTH))));

        -- *
	-- * My pipeline types
	-- *
	subtype pipeline_integer is integer range -32768 to 32767;
        subtype ext_pipeline_integer is integer range -131073 to 131072;
        subtype pipeline_vector is std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
        subtype ext_pipeline_vector is std_logic_vector(EXT_PIPELINE_WIDTH - 1 downto 0);

        --
        -- MORE constants
        --
	-- CURRENT CONFIG:
	-- >> SAMPLE RATE: 10 KHz
        constant SAMPLING_FREQ : real := 10000.0;
        constant SAMPLING_PERIOD : real := 0.0001;

        constant AC_FREQ : real := 314.1592653589793;  -- rad / s
        constant AC_FREQ_SAMPLE_SCALED : real := 0.03141593; -- 2*Pi*50*Ts

	-- Math constants
	constant EXAMPLE_VAL_FX316 : pipeline_integer := 26312;
        constant EXAMPLE_VAL_FX416 : pipeline_integer := 26312;
	constant ZERO_FX316_V : std_logic_vector(PIPELINE_WIDTH - 1 downto 0) := (others => '0');
        constant ZERO_FX416_V : std_logic_vector(PIPELINE_WIDTH - 1 downto 0) := (others => '0');
	constant CORDIC_GAIN : real := 1.64672851562500;  -- RECALCULATE ME
	constant INV_CORDIC_GAIN : real := 0.60729980468750;  -- RECALCULATE ME
	constant MINUS_INV_CORDIC_GAIN : real := -0.60729980468750;  -- RECALC
        constant PI : real := 3.14159265358979;
        constant MINUS_PI : real := -3.14159265358979;
        constant HALF_PI : real := 1.57079632679490;
        constant MINUS_HALF_PI : real := -1.57079632679490;
        constant TWO_PI : real := 6.28318530717959;
        constant MINUS_TWO_PI : real := -6.28318530717959;

	-- Filter constants
        constant PHASE_LOOP_PI_I_CONST : real := 1000.0;
        constant PHASE_LOOP_PI_P_CONST : real := 100.0;

        pure function to_integer ( val : real; width : natural; prec : natural ) return integer;
        pure function to_vector ( val : real; width : natural; prec : natural ) return std_logic_vector;
        
        pure function to_pipeline_integer ( val : real ) return integer;
        pure function to_pipeline_vector ( val : real ) return pipeline_vector;
        pure function to_ext_pipeline_integer ( val : real ) return integer;
        pure function to_ext_pipeline_vector ( val : real ) return ext_pipeline_vector;

        pure function min_magn_size ( val : real ) return natural;
end common;


package body common is
        pure function to_integer ( val : real; width : natural; prec : natural ) return integer is
                variable tmp_val : integer;
                variable max_integer, min_integer : integer;
        begin
                tmp_val := integer(round(val * (2.0 ** real(prec))));
                max_integer := integer(round(2.0 ** real(width - 1)));
                min_integer := -max_integer - 1;
                if (tmp_val > max_integer) then
                        assert false report "saturating pipeline(w: " & integer'image(width) & ", p: " & integer'image(prec) & ") with value " & real'image(val) severity warning;
                        return max_integer;
                elsif (tmp_val < min_integer) then
                        assert false report "neg. saturating pipeline(w: " & integer'image(width) & ", p: " & integer'image(prec) & ") with value " & real'image(val) severity warning;
                        return min_integer;
                else
                        if (tmp_val = 0) then
                                assert false report "not enough precision, returning 0!" severity warning;
                        end if;
                        return tmp_val;
                end if;
        end;

        pure function to_vector ( val : real; width : natural; prec : natural ) return std_logic_vector is
        begin
                return std_logic_vector(to_signed(to_integer(val, width, prec), width));
        end;
                
        pure function to_pipeline_integer ( val : real ) return integer is
        begin
                return to_integer(val, PIPELINE_WIDTH, PIPELINE_PREC);
        end;

        pure function to_pipeline_vector ( val : real ) return pipeline_vector is
        begin
                return to_vector(val, PIPELINE_WIDTH, PIPELINE_PREC);
        end;

        pure function to_ext_pipeline_integer ( val : real ) return integer is
        begin
                return to_integer(val, EXT_PIPELINE_WIDTH, EXT_PIPELINE_PREC);
        end;

        pure function to_ext_pipeline_vector ( val : real ) return ext_pipeline_vector is
        begin
                return to_vector(val, EXT_PIPELINE_WIDTH, EXT_PIPELINE_PREC);
        end;

        pure function min_magn_size ( val : real ) return natural is
        begin
                return natural(round(ceil(log2(abs(val)))));
        end;

end common;
