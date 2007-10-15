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
-- === CHANGELOG ===
-- Revision 0.01: first version, created from the original dac_adc implementation

library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use WORK.COMMON.ALL;

entity phase_loop_fpga is	
        generic (
                width : natural := PIPELINE_WIDTH;
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
end phase_loop_fpga;

architecture beh of phase_loop_fpga is
        component platform is
                port (
                        CLKIN_IN : in std_logic; -- Input clock
                        RST_IN : in std_logic; -- Input RST
                        CLKDV_OUT : out std_logic; -- Main clock / 16
                        CLKIN_IBUFG_OUT : out std_logic; -- Input raw clock, buffered
                        CLK0_OUT : out std_logic; -- Main output clock
                        LOCKED_OUT : out std_logic);
        end component platform;

        signal spi_mosi_s, spi_sck_s : std_logic;
-- spi_miso_s -> unneeded,
-- input signal is directly used

        signal clk_div_8_s, clk_50_s : std_logic;
        
        signal have_sample_s, need_sample_s : std_logic;
        signal in_sample_s : std_logic_vector(ADC_VAL_SIZE - 1 downto 0);
        signal out_sample_s : std_logic_vector(DAC_VAL_SIZE - 1 downto 0);
        signal in_sample_procesado_s : std_logic_vector(width -1 downto 0);
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

        dac_adc_i : entity work.dac_adc(beh)
                port map (
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
                        in_sample => in_sample_s, -- Sample received from ADC
                        have_sample => have_sample_s,
                        out_sample => out_sample_s,
                        need_sample => need_sample_s,
                        clk => clk_div_8_s,              -- clk_50_s is TOO FAST!!!
                        rst => '0',
                        run => '1',
                        spi_owned_out => spi_owned_out_s,
                        spi_owned_in => spi_owned_in_s);

        -- Transformation of input sample.
        -- We know:
        -- * It's 14 bits wide
        -- * It's in twos complement.
        -- * We want input value, right now, normalized
        adc_raw_to_pipe_i : entity work.pipeline_conv(alg)
             generic map (
                     in_width  => ADC_VAL_SIZE,
                     in_prec   => ADC_VAL_SIZE - 1,
                     out_width => width,
                     out_prec  => prec)
             port map (
                     i => in_sample_s,
                     o => in_sample_procesado_s);
        
        phase_loop_i : entity phase_loop(alg)
                port map (
                        clk => clk_div_8_s,
                        run => have_sample_s,
                        rst => '0',
                        norm_input => in_sample_procesado_s,
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
        led <= out_signal_s(8);

        -- El pkt IEEE.NUMERIC_STD tiene definido un tipo Signed, en el que el
        -- valor se representa en CA2. Por lo tanto:
        -- * Para cambiar de signo (CA2)
        -- std_logic_vector(- signed(type of std_logic_vector))
        -- * Para sumar:
        -- std_logic_vector(signed(type of std_logic_vector) + INTEGER) -- :) Tirao
        -- * Para hacer desplazamientos, teniendo en cuenta el signo
        -- (interesante), en este mismo paquete disponemos de SHIFT_LEFT y SHIFT_RIGHT
        -- Ejemplo de cómo usar la función shift
        -- out_sample_s <= std_logic_vector(shift_left(-(signed(in_sample_s)), 1));

        -- Para sacar un valor NORMALIZADO en CA2 y que se vea bien a la salida:
        -- * + d"1" = + b"001.000...."
        out_sample_s <= std_logic_vector(signed(out_signal_s) + signed(to_vector(1.0, width, prec)));
        -- En su momento, con 8192 (1.0 para 13 bits de precisión) no llega, ya que aparentemente el ruido del Cordic
        -- nos hace superar "parcialmente" el -1.0 => no nos llega con sumarle
        -- 8192. Le estoy sumando oun poquito más (16)        
        -- Se debería también escalar, multiplicándolo por 2:
        -- shift_left(unsigned(bla bla bla), 1)
        
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
