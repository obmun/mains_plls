-- Copyright (c) 2012-2016 Jacobo Cabaleiro Cayetano
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

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
	constant PIPELINE_WIDTH : natural := 16;  -- SHOULD REMAIN CONSTANT
	constant EXT_PIPELINE_WIDTH : natural := 18;  -- SHOULD REMAIN CONSTANT
	constant PIPELINE_PREC : natural := 12;
	constant EXT_PIPELINE_PREC : natural := PIPELINE_PREC;
	constant PIPELINE_MAGN : natural := PIPELINE_WIDTH - PIPELINE_PREC;
	constant EXT_PIPELINE_MAGN : natural := EXT_PIPELINE_WIDTH - EXT_PIPELINE_PREC;
	constant PIPELINE_WIDTH_DIR_BITS : natural := 4; -- natural(ceil(log2(real(PIPELINE_WIDTH))));

        constant EXT_IIR_FILTERS_PREC : natural := 15;

        -- *
	-- * My pipeline types
	-- *
	subtype pipeline_integer is integer range -32768 to 32767;
        subtype ext_pipeline_integer is integer range -131073 to 131072;
        subtype pipeline_vector is std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
        subtype ext_pipeline_vector is std_logic_vector(EXT_PIPELINE_WIDTH - 1 downto 0);

        -- *
        -- * Special types for some algorithms
        -- *
        -- Canonic Signed Digit representation
        type csd_logic is ( '0', -- No op needed
                            'p', -- plus -> Input must be added
                            'm' -- minus -> Input must be substracted
                            );
        type csd_logic_vector is array (integer range <>) of csd_logic;

        -- *
        -- * Constantes básicas del DAC / ADC necesarias por otros módulos.
        -- *
        constant DAC_VAL_SIZE : natural := 12;
        constant ADC_VAL_SIZE : natural := 14;

        -- *
        -- * MORE constants
        -- *
	-- CURRENT CONFIG:
	-- >> SAMPLE RATE: 10 KHz
        -- Be careful: changing this value does NOT automatically change the ADC sampling freq. That
        -- freq is _hardcoded_ inside dac_adc entity.
        constant SAMPLING_FREQ : real := 10000.0;
        constant SAMPLING_PERIOD : real := 1.0 / SAMPLING_FREQ;

        constant AC_FREQ : real := 314.1592653589793;  -- 2 * Pi * 50 - rad / s
        constant AC_FREQ_SAMPLE_SCALED : real := AC_FREQ * SAMPLING_PERIOD;

	-- Math constants
	constant EXAMPLE_VAL_FX316 : pipeline_integer := 26312;
        constant EXAMPLE_VAL_FX416 : pipeline_integer := 26312;
	constant ZERO_FX316_V : std_logic_vector(PIPELINE_WIDTH - 1 downto 0) := (others => '0');
        constant ZERO_FX416_V : std_logic_vector(PIPELINE_WIDTH - 1 downto 0) := (others => '0');
        constant PI : real := 3.14159265358979;
        constant MINUS_PI : real := -3.14159265358979;
        constant HALF_PI : real := 1.57079632679490;
        constant MINUS_HALF_PI : real := -1.57079632679490;
        constant TWO_PI : real := 6.28318530717959;
        constant MINUS_TWO_PI : real := -6.28318530717959;

        -- @brief Transforms a given real value into the nearest integer for the fixed point format
        -- defined by prec and width. Uses 2s complement binary representation
        pure function to_integer ( val : real; width : natural; prec : natural ) return integer;
        -- @brief Wrapper around to_integer function which returns directly a std_logic_vector
        pure function to_vector ( val : real; width : natural; prec : natural ) return std_logic_vector;

        -- @brief 'high like attribute in function form for unsigned type
        pure function high ( u : unsigned ) return natural;
        -- pure function high ( s : signed ) return integer;

        -- pure function low ( u : unsigned ) return natural;
        -- pure function low ( s : signed ) return integer;

        pure function to_pipeline_integer ( val : real ) return integer;
        pure function to_pipeline_vector ( val : real ) return pipeline_vector;
        pure function to_ext_pipeline_integer ( val : real ) return integer;
        pure function to_ext_pipeline_vector ( val : real ) return ext_pipeline_vector;

        pure function min_magn_size ( val : real ) return natural;

        pure function q_func ( v : std_logic_vector; i : natural; j : natural ) return integer;
        pure function vector_to_csd ( v : std_logic_vector ) return csd_logic_vector;
end common;


package body common is
        pure function to_integer ( val : real; width : natural; prec : natural ) return integer is
                variable tmp_val : integer;
                variable max_integer, min_integer : integer;
        begin
                tmp_val := integer(round(val * (2.0 ** real(prec))));
                max_integer := integer(round(2.0 ** real(width - 1))) - 1;
                min_integer := -max_integer - 1;
                if (tmp_val > max_integer) then
                        assert false report real'image(val) & "is saturating pipeline(w: " & integer'image(width) & ", p: " & integer'image(prec) & ") with value " & integer'image(max_integer) severity warning;
                        return max_integer;
                elsif (tmp_val < min_integer) then
                        assert false report "neg. saturating pipeline(w: " & integer'image(width) & ", p: " & integer'image(prec) & ") with value " & real'image(val) severity warning;
                        return min_integer;
                else
                        if ((tmp_val = 0) and (val /= 0.0)) then
                                assert false report "not enough precision, returning 0!" severity warning;
                        end if;
                        return tmp_val;
                end if;
        end;

        pure function to_vector ( val : real; width : natural; prec : natural ) return std_logic_vector is
        begin
                return std_logic_vector(to_signed(to_integer(val, width, prec), width));
        end;

        pure function high ( u : unsigned ) return natural is
        begin
             return 2**u'length - 1;
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

        pure function q_func ( v : std_logic_vector; i : natural; j : natural ) return integer is
        begin
                if (i = j) then
                        return 0;
                else
                        if (v(j) = '0') then
                                return q_func(v, i, j - 1) - 1;
                        else
                                return q_func(v, i, j - 1) + 1;
                        end if;
                end if;
        end;

        --! @brief Simplified 2s complement to CSD algorithm
        --
        -- Sólo funciona con VALORES DE ENTRADA POSITIVOS. Así que, no intentes
        -- meterle valores negativos.
        pure function vector_to_csd ( v : std_logic_vector ) return csd_logic_vector is
                -- v: la constante a convertir a csd
                variable i : natural := 0;
                variable j : natural;
                variable q_val : integer;
                variable carry : boolean := false;
                variable res : csd_logic_vector(v'length downto 0);
        begin
                while (i < v'length) loop
                        if (((v(i) = '1') and carry) or (v(i) = '0' and not carry)) then
                                res(i) := '0';
                        else
                                j := i + 1;
                                q_val := 1;
                                while (j < v'length and q_val = 1) loop
                                        q_val := q_func(v, i, j);
                                        j := j + 1;
                                end loop;
                                if (q_val < 2) then
                                        res(i) := 'p';
                                        carry := false;
                                else
                                        res(i) := 'm';
                                        carry := true;
                                end if;
                        end if;
                        i := i + 1;
                end loop;
                if (carry) then
                        res(i) := 'p';
                else
                        res(i) := '0';
                end if;
                return res;
        end;

        pure function min_magn_size ( val : real ) return natural is
        begin
                return natural(round(ceil(log2(abs(val)))));
        end;

end common;
