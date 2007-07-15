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
use WORK.COMMON.ALL;

entity spll_fpga is
    generic (
            width : natural := PIPELINE_WIDTH; -- prec < width
            prec : natural := PIPELINE_PREC);

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
end spll_fpga;

architecture beh of spll_fpga is
        component platform is
                port (
                        CLKIN_IN : in std_logic; -- Input clock
                        RST_IN : in std_logic; -- Input RST
                        CLKDV_OUT : out std_logic; -- Main clock / 16
                        CLKIN_IBUFG_OUT : out std_logic; -- Input raw clock, buffered
                        CLK0_OUT : out std_logic; -- Main output clock
                        LOCKED_OUT : out std_logic);
        end component platform;

        component spll is
                -- rev 0.01
                port (
                        clk, sample, rst : in std_logic;
                        in_signal : in std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
                        phase, out_signal : out std_logic_vector(PIPELINE_WIDTH -1 downto 0);
                        done : out std_logic);
        end component spll;
begin
        platform_i : platform
                port map (
                        CLKIN_IN => clk,
                        RST_IN => '0',
                        CLKDV_OUT => clk_div_16_s,
                        CLKIN_IBUFG_OUT => open,
                        CLK0_OUT => clk_50_s,
                        LOCKED_OUT => open);

        spll_i : spll
                port map (
                        clk => clk_50_s,
                        sample => ,
                        rst => ,
                        in_signal => , 
                        phase => ,
                        out_signal => ,
                        done => );
end architecture beh;
