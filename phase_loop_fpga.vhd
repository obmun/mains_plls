-- *** Description ***
-- This is the WRAPPER around spll entity for the real FPGA.
-- Idea and sample implementation was originally developed for the dac_adc
-- test. That's when the idea of full FPGA separation appeared.
-- * Internally, spll uses only 1 / 0 logic. This file adds the 3rd state
-- output pins.
-- * Allows for usage of a DCM, without messing Xilinx details inside spll.vhd file
-- * Allows the definition of debug lines, that duplicate the ouput of
-- internal or input signals
--
-- *** CHANGELOG ***
-- Revision 0.01: first version, created from the original dac_adc implementation

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
-- use WORK.COMMON.ALL;

entity phase_loop_fpga is	
        generic (
                width : natural := 16; -- PIPELINE_WIDTH; -- prec < width
                prec : natural := 13 -- PIPELINE_PREC
                );

        port (
-- SPI related
-- This lines should be Hi-Z (SPI bus is shared). To avoid problems
-- during synthesis, JUST THE FINAL real ports should have hi-Z
-- state.
            spi_mosi, spi_sck : out std_logic;
            spi_miso : in std_logic;

-- SPI slaves CS
            dac_ncs, amp_ncs, amp_shdn : out std_logic;
            adc_conv : out std_logic; -- Quite a special CS. See ADC datasheet for details. Active on high.
            isf_ce0 : out std_logic; -- Intel StrataFlash Flash: disabled with 1
            xpf_init_b : out std_logic; -- Xilinx Platform Flash PROM: disabled with 1
            stsf_b : out std_logic; -- ST Serial Flash: disabled with 1
-- Other DAC signals
            dac_clr : out std_logic;

-- Interface with internal logic
            clk : in std_logic;

-- Temporal
            debug_d7, debug_c7, debug_f8, debug_e8 : out std_logic;
            led : out std_logic);
end phase_loop_fpga;

architecture beh of phase_loop_fpga is
        -- **************
        -- * COMMON!!!! *
        -- **************
        
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

	constant AC_FREQ_SAMPLE_SCALED_FX316 : pipeline_integer := 41; -- 50*Ts*2^PIPELINE_PREC
	constant AC_FREQ_SAMPLE_SCALED_FX316_S : signed(PIPELINE_WIDTH - 1 downto 0) := B"0_00_00000_00101001";

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
	constant MINUS_HALF_PI_FX316 : pipeline_integer := -12868;
	constant MINUS_HALF_PI_FX316_V : std_logic_vector(PIPELINE_WIDTH - 1 downto 0) := X"CDBC";
	constant PI_FX316 : pipeline_integer := 25736;
	constant PI_FX316_V : std_logic_vector(PIPELINE_WIDTH - 1 downto 0) := X"6488";
	constant MINUS_PI_FX316 : pipeline_integer := -25736;
	constant MINUS_TWO_PI_FX417_V : std_logic_vector(PIPELINE_WIDTH downto 0) := B"0_110_01001_00010000"; -- TODO: REVIEW LAST BIT

	-- Filter constants
	-- constant PHASE_LOOP_PI_I_CONST_FX316 : pipeline_integer := xxx; OVERFLOW!!!
	constant PHASE_LOOP_PI_I_CONST_SAMPLE_SCALED : pipeline_integer := 122;
	constant PHASE_LOOP_PI_P_CONST : pipeline_integer := 32767; -- OVERFLOW!!!
        component platform is
                port (
                        CLKIN_IN : in std_logic; -- Input clock
                        RST_IN : in std_logic; -- Input RST
                        CLKDV_OUT : out std_logic; -- Main clock / 16
                        CLKIN_IBUFG_OUT : out std_logic; -- Input raw clock, buffered
                        CLK0_OUT : out std_logic; -- Main output clock
                        LOCKED_OUT : out std_logic);
        end component platform;

        component dac_adc is
                generic (
                        width : natural := PIPELINE_WIDTH;
-- prec < width
                        prec : natural := PIPELINE_PREC);
                
                port (
-- SPI related
-- This lines should be Hi-Z (SPI bus is shared). To avoid problems
-- during synthesis, JUST THE FINAL real ports should have hi-Z
-- state. Internaly all should be done thru logic. See spi_owned
-- ports below.
                        spi_mosi, spi_sck : out std_logic;
                        spi_miso : in std_logic;

-- SPI slaves CS
                        dac_ncs, amp_ncs : out std_logic;
                        adc_conv : out std_logic; -- Quite a special CS. See ADC datasheet for details. Active on high.
                        isf_ce0 : out std_logic; -- Intel StrataFlash Flash: disabled with 1
                        xpf_init_b : out std_logic; -- Xilinx Platform Flash PROM: disabled with 1
                        stsf_b : out std_logic; -- ST Serial Flash: disabled with 1
-- Other DAC signals
                        dac_clr : out std_logic;

-- Interface with internal logic
                        in_sample : out std_logic_vector(width - 1 downto 0);
                        have_sample : out std_logic;
                        out_sample : in std_logic_vector(width - 1 downto 0);
                        need_sample : out std_logic;
                        clk : in std_logic;
                        rst : in std_logic; -- Async reset
                        run : in std_logic; -- Tell this to run
                        spi_owned_out : out std_logic;
                        spi_owned_in : in std_logic -- Daisy chaining
                        );
        end component dac_adc;

        signal spi_mosi_s, spi_sck_s : std_logic;
-- spi_miso_s -> unneeded,
-- input signal is directly used

        signal clk_div_8_s, clk_50_s : std_logic;
        
        signal have_sample_s, need_sample_s : std_logic;
        signal in_sample_s, out_sample_s : std_logic_vector(15 downto 0);
        signal spi_owned_out_s, spi_owned_in_s : std_logic;

        signal out_signal_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
    
        -- DEBUG helper signals
        signal dac_ncs_s : std_logic;       -- dac_ncs could be directly connected
                                            -- from dac_adc to dac_adc_fpga port.
        signal adc_conv_s : std_logic;      -- Same as with dac_ncs signal
        signal counter_s : std_logic_vector(11 downto 0);

        signal debug_signal_1 : std_logic;

begin
        platform_i : platform
                port map (
                        CLKIN_IN => clk,
                        RST_IN => '0',
                        CLKDV_OUT => clk_div_8_s,
                        CLKIN_IBUFG_OUT => open,
                        CLK0_OUT => clk_50_s,
                        LOCKED_OUT => open);

        dac_adc_i : dac_adc
                port map(
                        spi_mosi => spi_mosi_s,
                        spi_sck => spi_sck_s,
                        spi_miso => spi_miso,
                        
                        dac_ncs => dac_ncs_s,
                        amp_ncs => amp_ncs,
                        adc_conv => adc_conv_s,
                        isf_ce0 => isf_ce0,
                        xpf_init_b => xpf_init_b,
                        stsf_b => stsf_b,
                        dac_clr => dac_clr,

-- Interface with internal logic
                        in_sample => in_sample_s,         -- Sample received from ADC
                        have_sample => have_sample_s,
                        out_sample => out_sample_s,
                        need_sample => need_sample_s,
                        clk => clk_div_8_s,              -- clk_50_s is TOO FAST!!!
                        rst => '0',
                        run => '1',
                        spi_owned_out => spi_owned_out_s,
                        spi_owned_in => spi_owned_in_s);
        
        phase_loop_i : entity phase_loop(alg)
                port map (
                        clk => clk_div_8_s,
                        run => need_sample_s,
                        rst => '0',
                        norm_input => (others => '0'), -- in_sample_s, 
                        phase => open,
                        norm_sin => out_signal_s,
                        done => debug_signal_1);

        -- The only important signal that is not being generated by adc_dac
        amp_shdn <= '0';
        dac_ncs <= dac_ncs_s;
        adc_conv <= adc_conv_s;
        spi_owned_in_s <= '0';

        -- Connect debug signals
        debug_d7 <= debug_signal_1;
        debug_c7 <= '0';
        debug_f8 <= '0';
        debug_e8 <= '0';
        
        led <= out_signal_s(8); -- in_sample_s MUST BE connected to somewhere.
        -- Otherwise, full adc input control logic is
        -- completely deleted from design.

        -- Ejemplo de cómo usar la función shift
        -- out_sample_s <= std_logic_vector(shift_left(-(signed(in_sample_s)), 1));

        -- EL AMPLIFICADOR DE ENTRADA INVIERTE :)
--        out_sample_unfold : process(in_sample_s)
--        begin
--                if in_sample_s(15) = '1' then
--                        out_sample_s(15) <= '1'; -- std_logic_vector(not(shift_left(unsigned(in_sample_s), 1)));
--                        out_sample_s(14 downto 0) <= not(in_sample_s(14 downto 0));
--                else
--                        out_sample_s(14 downto 0) <= not(in_sample_s(14 downto 0));
--                        out_sample_s(15) <= '0';
--                end if;
--        end process out_sample_unfold;
        out_sample_s <= out_signal_s;
        
        spi_gen : process(spi_owned_out_s, spi_mosi_s, spi_sck_s)
        begin
                if (spi_owned_out_s = '1') then
                        spi_mosi <= spi_mosi_s;
                        spi_sck <= spi_sck_s;
                else
                        spi_mosi <= 'Z';
                        spi_sck <= 'Z';
                end if;
        end process spi_gen;
end architecture beh;
