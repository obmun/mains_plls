--------------------------------------------------------------------------------
-- *** Description ***
--
-- This is the WRAPPER around spll entity for the real FPGA.
-- Idea and sample implementation was originally developed for the dac_adc
-- test. That's when the idea of full FPGA separation appeared.
--
-- * Internally, spll uses only 1 / 0 logic. This file adds the 3rd state
-- output pins.
-- * Allows for usage of a DCM, without messing with Xilinx specific details inside spll.vhd file
-- * Allows the definition of debug lines, that duplicate the ouput of
-- internal or input signals
--
-- *** CHANGELOG ***
-- Revision 0.01: first version, created from the original dac_adc implementation
--------------------------------------------------------------------------------

library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.all;
use WORK.COMMON.ALL;

entity p2_sync_fpga is	
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
end p2_sync_fpga;

architecture structural of p2_sync_fpga is
     signal spi_mosi_s, spi_sck_s : std_logic;
     -- spi_miso_s -> unneeded,
     -- input signal is directly used

     signal clk_div_16_s, clk_50_s, clk_10_s : std_logic;
     
     signal have_sample_s, need_sample_s : std_logic;
     signal in_sample_s, inv_in_sample_s : std_logic_vector(ADC_VAL_SIZE - 1 downto 0);
     signal in_signal_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
     signal tmp_out_sample_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
     signal out_sample_s : std_logic_vector(DAC_VAL_SIZE - 1 downto 0);
     signal spi_owned_out_s, spi_owned_in_s : std_logic;

     signal out_signal_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
     
     -- DEBUG helper signals
     signal dac_ncs_s : std_logic;       -- dac_ncs could be directly connected
                                         -- from dac_adc to dac_adc_fpga port.
     signal adc_conv_s : std_logic;      -- Same as with dac_ncs signal

begin
     platform_i : entity work.platform(beh)
          port map (
               CLKIN_IN => clk,
               RST_IN => '0',
               CLKDV_OUT => clk_div_16_s,
               CLKIN_IBUFG_OUT => open,
               CLK0_OUT => clk_50_s,
               CLKFX_OUT => clk_10_s,
               LOCKED_OUT => open);

     dac_adc_i : entity work.dac_adc(beh)
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
               in_sample => in_sample_s, -- Sample received from ADC
               have_sample => have_sample_s,
               out_sample => out_sample_s,
               need_sample => need_sample_s,
               clk => clk_div_16_s, -- clk_50_s is TOO FAST!!!
               rst => '0',
               run => '1',
               spi_owned_out => spi_owned_out_s,
               spi_owned_in => spi_owned_in_s);

     in_sample_inverter : entity work.inverter(beh)
          generic map (
               width => ADC_VAL_SIZE)
          port map (
               i => in_sample_s,
               o => inv_in_sample_s);
     
     in_sample_to_signal_conv : entity work.pipeline_conv(alg)
          generic map (
               in_width  => ADC_VAL_SIZE,
               in_prec   => ADC_VAL_SIZE - 1,
               out_width => PIPELINE_WIDTH,
               out_prec  => PIPELINE_PREC)
          port map (
               i => inv_in_sample_s,
               o => in_signal_s);

     spll_i : entity work.p2_sync(structural)
          port map (
               clk => clk_10_s,
               sample => have_sample_s,
               rst => '0',
               in_signal => in_signal_s, 
               phase => out_signal_s,
               out_signal => open,
               ampl => open,
               done => open);

     -- The only important signal that is not being generated by adc_dac
     amp_shdn <= '0';
     dac_ncs <= dac_ncs_s;
     adc_conv <= adc_conv_s;
     spi_owned_in_s <= '0';

     -- Connect debug signals
     debug_d7 <= '0';
     debug_c7 <= '0';
     debug_f8 <= '0';
     debug_e8 <= '0';
     led <= '0';

     -- ************************
     -- * CORRECTLY CONVERT ME *
     -- ************************
     -- Output for normalized sine
     -- tmp_out_sample_s <= std_logic_vector(shift_right(signed(out_signal_s), 0) + signed(to_pipeline_vector(1.4)));
     -- out_sample_s <= tmp_out_sample_s(PIPELINE_WIDTH - 2 - 1 downto PIPELINE_WIDTH - DAC_VAL_SIZE - 1 - 1);
     -- Output for phase
     tmp_out_sample_s <= std_logic_vector(shift_right(signed(out_signal_s), 1) + signed(to_pipeline_vector(1.6)));
     out_sample_s <= tmp_out_sample_s(PIPELINE_WIDTH - 2 - 0 downto PIPELINE_WIDTH - DAC_VAL_SIZE - 1 - 0);
     -- Output for amplitude
     -- tmp_out_sample_s <= std_logic_vector(shift_right(signed(out_signal_s), 0));
     -- out_sample_s <= tmp_out_sample_s(PIPELINE_WIDTH - 2 - 1 downto PIPELINE_WIDTH - DAC_VAL_SIZE - 1 - 1);

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
end architecture structural;
