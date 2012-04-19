-- *** Description ***
--
-- This is the WRAPPER around phase_loop entity (phase loop for spll design) for implementation on
-- the Digilent board
--
-- Idea and sample implementation were originally developed for the dac_adc test. That's when the
-- idea of full FPGA separation appeared.
--
-- * Internally, phase_loop uses only 1/0 logic. This file adds the 3rd state output pins wherever
-- necessary.
--
-- * Allows for usage of a DCM, without messing with Xilinx details inside ampl_loop.vhd file
--
-- * Allows the definition of debug lines, which duplicate the ouput of internal or input signals
--
-- ** Clocks **
--
-- Internally, all clock signals are derived from the OSC clk / 8, that is, a 6.25 MHz clk
--
-- === CHANGELOG ===
--
-- Revision 0.xx: CHECK REVISION INFORMATION on Mercurial project repo
-- Revision 0.01: first version, created from the original dac_adc implementation

library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.all;
use WORK.COMMON.ALL;

entity phase_loop_fpga is	
     generic (
          width : natural := PIPELINE_WIDTH;
          prec : natural := PIPELINE_PREC);

     port (
          -- SPI related
          --
          -- This lines should be Hi-Z (SPI bus is shared). To avoid problems during synthesis, JUST
          -- THE FINAL real ports should have hi-Z state.
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
            led : out std_logic_vector(7 downto 0));
end phase_loop_fpga;


architecture beh of phase_loop_fpga is
     constant ADC_WAIT_TIME_S : real := 6.0;
     type state_t is (
          ST_WARMING, -- The FPGA is warming up, stabilizing clocks and similar. We should not do anything on this state
          ST_RST, -- Once the FPGA is ready to work, we reset the design during one cycle
          ST_START_AMP_PROG, -- Cycle for signaling start of pre-amp programming
          ST_AMP_PROG, -- ADC pre-amp programming
          ST_WAIT_AFTER_AMP_PROG, -- Special state for waiting for PGA stabilization (I think the
                                  -- necessity for this state is due to SPI bus timing)
          ST_ADC_WARM_UP, -- During ADC tests we detected that for the first 5 or 6 seconds we had
                          -- random input values. During this state, we inhibit the processing of
                          -- samples inside the PLL
          ST_RUNNING); -- Normal running state
     signal st : state_t;

     signal spi_owned_s : std_logic;
     signal spi_mosi_s, spi_sck_s : std_logic;
     -- spi_miso_s -> unneeded,
     -- input signal is directly used

     signal clk_div_8_s : std_logic; -- Input clock divided by 8 (6.25 MHz)
     signal locked_out_s : std_logic;

     signal rst_s, dac_adc_run_s : std_logic;
     signal have_sample_s, need_sample_s : std_logic;

     -- Pipeline
     signal in_sample_s : std_logic_vector(ADC_VAL_SIZE - 1 downto 0);
     signal in_signal_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
     signal out_signal_s, out_signal_scaled_s, out_signal_dac_ready_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
     signal out_sample_s : std_logic_vector(DAC_VAL_SIZE - 1 downto 0);

     -- SPI / peripherals
     signal spi_owned_in_s : std_logic;

     signal adc_conv_s, dac_ncs_s : std_logic;

     signal spi_dac_adc_owned_s : std_logic;
     signal dac_adc_spi_mosi_s, dac_adc_spi_sck_s : std_logic;

     --- Progammable Amp signals ---
     signal pga_wait_cnt_s : std_logic_vector(2 downto 0);
     signal pga_wait_ctr_last_s, pga_wait_ctr_rst_s : std_logic;
     
     signal amp_ncs_s : std_logic;
     signal set_gain_s, gain_done_s : std_logic;
     
     signal spi_prog_amp_owned_s : std_logic;
     signal prog_amp_spi_mosi_s, prog_amp_spi_sck_s : std_logic;

     --- Other ---
     signal adc_wait_ctr_last_s, adc_wait_ctr_rst_s, adc_wait_ctr_ce_s : std_logic;
     signal run_pll_s : std_logic;

begin
     platform_i : entity work.platform(beh)
          port map (
               CLKIN_IN => clk,
               RST_IN => '0',
               CLKDV_OUT => clk_div_8_s,
               CLKIN_IBUFG_OUT => open,
               CLK0_OUT => open,
               CLKFX_OUT => open,
               LOCKED_OUT => locked_out_s);
     
     dac_adc_i : entity work.dac_adc(beh)
          port map(
               spi_mosi => dac_adc_spi_mosi_s,
               spi_sck => dac_adc_spi_sck_s,
               spi_miso => spi_miso,

               dac_ncs => dac_ncs_s,
               amp_ncs => open,
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
               clk => clk_div_8_s,
               rst => rst_s,
               run => dac_adc_run_s,
               spi_owned_out => spi_dac_adc_owned_s,
               spi_owned_in => spi_owned_in_s);
     adc_conv <= adc_conv_s;
     dac_ncs <= dac_ncs_s;

     prog_amp_i : entity work.prog_amp(beh)
          port map (
               clk => clk_div_8_s,
               rst => rst_s,
               a_gain => b"0001",
               b_gain => b"0001",
               set_gain => set_gain_s,
               done => gain_done_s,
               spi_owned_out => open,
               spi_mosi => prog_amp_spi_mosi_s,
               spi_sck => prog_amp_spi_sck_s,
               spi_miso => '0',
               amp_ncs => amp_ncs_s);

     phase_loop: block is
          signal run_s : std_logic;
     begin
          run_s <= run_pll_s and have_sample_s;
          i : entity phase_loop(alg)
               port map (
                    clk => clk_div_8_s,
                    run => run_s,
                    rst => '0',
                    norm_input => in_signal_s,
                    phase => open,
                    norm_sin => out_signal_s,
                    done => open);
     end block;
     
     -- Remember:
     -- 1) ADC input
     --    1.65 v -> 0
     --    Signed (2s complement) input binary value
     --    1.65 + 1.25 -> 011...11 (max positive value)
     --    1.65 - 1.25 -> 100...00 (min negative value)
     --
     -- 2) DAC ouput
     --    Non binary value, 14 bits.
     --    Range: 0 - 3.3V (or 2.5 V)
     
     -- Converts the ADC input value into a PIPELINE format in the range (-1, 1).
     --
     in_sample_pipeline_conv : entity work.pipeline_conv(alg)
          generic map (
               in_width  => ADC_VAL_SIZE,
               in_prec   => ADC_VAL_SIZE - 1,
               out_width => PIPELINE_WIDTH,
               out_prec  => PIPELINE_PREC)
          port map (
               i => in_sample_s,
               o => in_signal_s);

     -- DAC output accepts only a 12 bits _unsigned_ integer
     -- => => WE WANT SOME MARGIN, so we can output (-2, 2) range on the DAC
     --
     -- We need to convert the desired input (from -2 to +2) to the (0, 1) range, and keep only the
     -- prec bits.
     
     -- Scale the output signal by 0.5*0.5 = 0.25
     --   That is: (-2, 2) input signal range is converted into (-0.5, 0.5).
     out_signal_scaler : entity work.k_4_div(structural)
          generic map (
               width => PIPELINE_WIDTH)
          port map (
               i => out_signal_s,
               o => out_signal_scaled_s);

     -- out_signal_s = in_signal_scaled_s + 0.5
     -- That is: add 0.5 to in_signal_scaled_s so out_signal_s range is (0, 1).
     in_signal_adder : entity work.adder(alg)
          generic map (
               width => PIPELINE_WIDTH)
          port map (
               a => out_signal_scaled_s,
               b => to_vector(0.5, PIPELINE_WIDTH, PIPELINE_PREC),
               o => out_signal_dac_ready_s,
               f_ov => open,
               f_z => open);


     -- **** **** **** Finite State Machine **** **** ****
     state_ctrl : process(clk_div_8_s, locked_out_s, gain_done_s, pga_wait_cnt_s, adc_wait_ctr_last_s)
          variable first_pga_prog : std_logic;
     begin
          if (rising_edge(clk_div_8_s)) then
               if (locked_out_s = '0') then
                    st <= ST_WARMING;
               else
                    case st is
                         when ST_WARMING =>
                              if (locked_out_s = '1') then
                                   st <= ST_RST;
                              else
                                   st <= ST_WARMING;
                              end if;
                         when ST_RST =>
                              first_pga_prog := '1';
                              st <= ST_START_AMP_PROG;
                         when ST_START_AMP_PROG =>
                              st <= ST_AMP_PROG;
                         when ST_AMP_PROG =>
                              if (gain_done_s = '1') then
                                   st <= ST_WAIT_AFTER_AMP_PROG;
                              else
                                   st <= ST_AMP_PROG;
                              end if;
                         when ST_WAIT_AFTER_AMP_PROG =>
                              -- This is just a small delay for waiting for the AMP nCS signal to
                              -- stabilize at high value before disturbing once more the SPI bus

                              if (pga_wait_ctr_last_s = '1') then
                                   if (first_pga_prog = '1') then
                                        st <= ST_START_AMP_PROG;
                                        first_pga_prog := '0';
                                   else
                                        st <= ST_ADC_WARM_UP;
                                   end if;
                              else
                                   st <= ST_WAIT_AFTER_AMP_PROG;
                              end if;
                         when ST_ADC_WARM_UP =>
                              if (adc_wait_ctr_last_s = '1') then
                                   st <= ST_RUNNING;
                              else
                                   st <= ST_ADC_WARM_UP;
                              end if;
                         when ST_RUNNING =>
                              st <= ST_RUNNING;
                         when others =>
                              report "Unkown spll state! Should not happen!"
                                   severity error;
                              st <= st;
                    end case;
               end if;
          end if;
     end process state_ctrl;

     state_signals_gen : process(st, have_sample_s)
     begin
          case st is
               when ST_WARMING =>
                    rst_s <= '0';
                    dac_adc_run_s <= '0';

                    set_gain_s <= '0';
                    pga_wait_ctr_rst_s <= '0';
                    spi_prog_amp_owned_s <= '0';

                    adc_wait_ctr_rst_s <= '0';
                    adc_wait_ctr_ce_s <= '0';
                    run_pll_s <= '0';
                    
                    led(0) <= '1';
                    led(1) <= '0';
                    led(2) <= '0';
                    
               when ST_RST =>
                    rst_s <= '1';
                    dac_adc_run_s <= '0';

                    set_gain_s <= '0';
                    pga_wait_ctr_rst_s <= '0';
                    spi_prog_amp_owned_s <= '0';

                    adc_wait_ctr_rst_s <= '0';
                    adc_wait_ctr_ce_s <= '0';
                    run_pll_s <= '0';

                    led(0) <= '0';
                    led(1) <= '1';
                    led(2) <= '0';
                    
               when ST_START_AMP_PROG =>
                    rst_s <= '0';
                    dac_adc_run_s <= '0';
                    
                    set_gain_s <= '1';
                    pga_wait_ctr_rst_s <= '0';
                    spi_prog_amp_owned_s <= '1';

                    adc_wait_ctr_rst_s <= '0';
                    adc_wait_ctr_ce_s <= '0';
                    run_pll_s <= '0';
                    
                    led(0) <= '1';
                    led(1) <= '1';
                    led(2) <= '0';
                    
               when ST_AMP_PROG =>
                    rst_s <= '0';
                    dac_adc_run_s <= '0';
                    
                    set_gain_s <= '0';
                    pga_wait_ctr_rst_s <= '1';
                    spi_prog_amp_owned_s <= '1';

                    adc_wait_ctr_rst_s <= '0';
                    run_pll_s <= '0';
                    
                    led(0) <= '0';
                    led(1) <= '0';
                    led(2) <= '1';

               when ST_WAIT_AFTER_AMP_PROG =>
                    rst_s <= '0';
                    dac_adc_run_s <= '0';
                    
                    set_gain_s <= '0';
                    pga_wait_ctr_rst_s <= '0';
                    spi_prog_amp_owned_s <= '1';

                    adc_wait_ctr_rst_s <= '1';
                    adc_wait_ctr_ce_s <= '1';
                    run_pll_s <= '0';
                    
                    led(0) <= '1';
                    led(1) <= '0';
                    led(2) <= '1';
                    
               when ST_ADC_WARM_UP =>
                    rst_s <= '0';
                    dac_adc_run_s <= '1';
                    
                    set_gain_s <= '0';
                    pga_wait_ctr_rst_s <= '0';
                    spi_prog_amp_owned_s <= '0';

                    adc_wait_ctr_rst_s <= '0';
                    adc_wait_ctr_ce_s <= have_sample_s;
                    run_pll_s <= '0';
                    
                    led(0) <= '0';
                    led(1) <= '1';
                    led(2) <= '1';

               when ST_RUNNING =>
                    rst_s <= '0';
                    dac_adc_run_s <= '1';
                    
                    set_gain_s <= '0';
                    pga_wait_ctr_rst_s <= '0';
                    spi_prog_amp_owned_s <= '0';

                    adc_wait_ctr_rst_s <= '0';
                    adc_wait_ctr_ce_s <= '0';
                    run_pll_s <= '1';
                    
                    led(0) <= '1';
                    led(1) <= '1';
                    led(2) <= '1';
                    
               when others =>
                    rst_s <= '0';
                    dac_adc_run_s <= '0';
                    
                    set_gain_s <= '0';
                    pga_wait_ctr_rst_s <= '0';
                    spi_prog_amp_owned_s <= '0';

                    adc_wait_ctr_rst_s <= '0';
                    adc_wait_ctr_ce_s <= '0';
                    run_pll_s <= '0';
                    
                    led(0) <= '0';
                    led(1) <= '0';
                    led(2) <= '0';
          end case;
     end process;


     -- Counter for waiting 8 cycles (3 bits) for PGA stabilization
     pga_wait_ctr : block is
          constant WIDTH : natural := 3;
          constant ONES : std_logic_vector(WIDTH - 1 downto 0) := std_logic_vector(to_unsigned(2**WIDTH - 1, WIDTH));
     begin
          cnt : process(clk_div_8_s, pga_wait_ctr_rst_s)
               variable val : natural;
          begin
               if (rising_edge(clk_div_8_s)) then
                    if (pga_wait_ctr_rst_s = '1') then
                         val := 0;
                    else
                         if (val = (2**width - 1)) then
                              val := 0;
                         else
                              val := val + 1;
                         end if;
                    end if;
                    pga_wait_cnt_s <= std_logic_vector(to_unsigned(val, WIDTH));
               end if;
          end process;
          
          pga_wait_ctr_last_s <= '1' when (pga_wait_cnt_s = ONES) else '0';
     end block;


     -- Counter for waiting the required ADC stabilization time
     mierda_mierda_adc_wait_ctr : block is
          constant N_SAMPLES : natural := natural(ceil(ADC_WAIT_TIME_S * SAMPLING_FREQ));
          constant WIDTH : natural := natural(ceil(log2(real(N_SAMPLES))));

          signal val_s : std_logic_vector(WIDTH - 1 downto 0);
     begin
          mierda_mierda_cnt : process(clk_div_8_s, adc_wait_ctr_ce_s, adc_wait_ctr_rst_s)
               variable val : natural;
          begin
               report "COUNTER WIDTH = " & natural'image(WIDTH) severity note;
               report "N_SAMPLES = " & natural'image(N_SAMPLES) severity note;
               if ((adc_wait_ctr_ce_s = '1') and rising_edge(clk_div_8_s)) then
                    if (adc_wait_ctr_rst_s = '1') then
                         val := 0;
                    else
                         if (val = (2**WIDTH - 1)) then
                              val := 0;
                         else
                              val := val + 1;
                         end if;
                    end if;
                    val_s <= std_logic_vector(to_unsigned(val, WIDTH));
               end if;
          end process;

          adc_wait_ctr_last_s <= '1' when (val_s = std_logic_vector(to_unsigned(N_SAMPLES, WIDTH))) else '0';
     end block;


     -- Keep the ADC pre-amp ON (shutdown = '0')
     amp_shdn <= '0';
     amp_ncs <= amp_ncs_s;
     
     spi_owned_in_s <= '0';

     spi_signals_gen: block is
     begin
          spi_mosi_s <= dac_adc_spi_mosi_s or prog_amp_spi_mosi_s;
          spi_sck_s <= dac_adc_spi_sck_s or prog_amp_spi_sck_s;
          spi_owned_s <= spi_dac_adc_owned_s or spi_prog_amp_owned_s;

          spi_mosi <= 'Z' when (spi_owned_s = '0') else spi_mosi_s;
          spi_sck <= 'Z' when (spi_owned_s = '0') else spi_sck_s;
     end block;

     led(3) <= in_sample_s(13);

     -- Convert out_signal_s to the correct DAC format
     assert PIPELINE_PREC = DAC_VAL_SIZE report "OOOPS. You have changed PIPELINE_PREC. Update this code, please" severity failure;
     out_sample_s <= out_signal_dac_ready_s(PIPELINE_PREC - 1 downto 0);     
     
     -- Other debug signals unused
     led(7 downto 4) <= (others => '0');
     debug_d7 <= spi_mosi_s;
     debug_c7 <= spi_sck_s; 
     debug_f8 <= amp_ncs_s;
     debug_e8 <= '0';
end architecture beh;
