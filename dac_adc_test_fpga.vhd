-----------------------------------------------------------------------------------
-- *** Description ***
--
-- Test on the real FPGA for the dac_adc component.
--
-- We capture the ADC input signal on 1st channel and put it identical on the 1st DAC channel
--
-- *** CHANGELOG ***
--
-- Revision 0.01
-----------------------------------------------------------------------------------

-- **** DEBUG DE ESTA ENTIDAD ****
--
-- 1) Verifico la frecuencia del reloj clk_div_16_s, sac�ndolo por debug_d7
--    MIDO unos 6.25 MHz
--    La frecuencia es distinta de la que se esperaba dentro del bloque dac_adc, que ten�a los contadores configurados para generar los timings correctos para un reloj de 12.5 Mhz. Por ahora no cambio nada.
--    ---
--    El reloj est� correcto, m�s o menos. El hecho de tener una frecuencia mitad _no_ deber�a ser un problema, ya que el propio reloj del SPI se genera dentro de esta entidad.
-- 2) Vamos a intentar observar las se�ales de salida del SPI, utilizando los puertos de debug (debug_d7, debug_c7, ...)
--    M�s espec�ficamente:
--    d7 <= spi_miso
--    c7 <= spi_sck_s
--    f8 <= adc_conv_s
--    e8 <= dac_ncs_s
--
--   Veo efectivamente una orden de muestreo, utilizando adc_conv_s. Un poco antes, deshabilitamos el DAC, haciendo dac_ncs_s = '1'
--   Por supuesto, mientras se da la orden , se genera el reloj de driving del SPI correctamente.
--
--   En el flanco ascendente (comienzo de ciclo de reloj) en el que el ADC coge la orden, correctamente esperamos 2 ciclos y a partir de ah�, viendo la se�al de MISO, observamos como efectivamente el ADC comienza a enviar datos.
--   Pasados los 14 bits del primer valor, espera 2 ciclos y vemos como comienza la transferencia del segundo canal. Todo parece estar correcto!
--   Para finalizar, esperamos dos o 3 ciclos.
--
--   Los valores que veo en el MOSI parecen indicar que efectivamente los bits est�n mayoritariamente a 1, indicando un valor negativo.
--
--   La transferencia a trav�s del SPI parece ser correcta. �Qu� puede fallar?
--
-----
--
-- Una inspecci�n el�ctrica mediante el osciloscopio muestra que el PGA previo al ADC no est�
-- funcionando correctamente. Su salida parece estar en 3er estado! El �nico posible motivo es que
-- el PGA est� en modo shutdown o deshabilitado.
--
-- Una lectura del datasheet del PGA muestra que efectivamente, tras un reseteo, �ste entra en un
-- modo de soft-shutdown en el que sus salidas est�n en tercer estado. ES NECESARIO PROGRAMAR EL
-- PGA, algo que no estaba implementado hasta el momento.
-- 
-- 3) PREPARO programaci�n del PGA.
--    1) Se prepara una primera versi�n del prog_amp.
--    2) Se testea en ModelSim. Parece funcionar.
--    3) Tendo dudas de que el funcionamiento sea correcto: estaba usando un esquema sin control a semi ciclo (el reloj SPI para el PGA era el mismo reloj que el que uso para la entidad prog_amp).
--       El DAC_ADC no segu�a este esquema, si no que en la m�quina de estados, ten�a ciertos estados duplicados, para que cada semi ciclo del SPI_SCK fuese realmente un ciclo del reloj de entrada del bloque y tener un control completo sobre el estado del reloj de salida.
--    4) Modifico para asegurarme de que la carga y configuraci�n del PGA es correcta.
--    5) COMPRUEBO que efectivamente la configuraci�n del PGA est� funcionando bien
--       * La comprobaci�n la hice de la siguiente manera
--         - Integr� el prog_amp en el test del dac_adc para la FPGA
--         - Mantuve el test global del DAC_ADC en el estado que se encarga de configurar el PGA,
--         PERO LO TUVE QUE PONER EN BUCLE!
--         - Verifiqu� que la tensi�n a la entrada del ADC cambiaba y que el valor era correcto.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use WORK.COMMON.ALL;

entity dac_adc_test_fpga is
     port (
-- SPI related
-- This lines should be Hi-Z (SPI bus isshared). To avoid problems
-- during synthesis, JUST THE FINAL real ports should have hi-Z
-- state.
          spi_mosi, spi_sck : out std_logic;
          spi_miso : in std_logic;
          
-- SPI slaves CS
          dac_ncs, amp_ncs, amp_shdn : out std_logic;
          adc_conv : out std_logic; -- Quite a special CS. CS and order for start of conversion. See ADC datasheet for details. Active on high.
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
end dac_adc_test_fpga;


architecture beh of dac_adc_test_fpga is
     type state_t is (
          ST_WARMING, -- The FPGA is warming up, stabilizing clocks and similar. We should not do anything on this state
          ST_RST, -- Once the FPGA is ready to work, we reset the design during one cycle
          ST_START_AMP_PROG, -- Cycle for signaling start of pre-amp programming
          ST_AMP_PROG, -- ADC pre-amp programming
          ST_WAIT_AFTER_AMP_PROG, -- Special state for waiting for PGA stabilization (I think the
                                  -- necessity for this state is due to SPI bus timing)
          ST_RUNNING); -- Normal running state
     signal st : state_t;

     signal spi_owned_s : std_logic;
     signal spi_mosi_s, spi_sck_s : std_logic;
     -- spi_miso_s -> unneeded,
     -- input signal is directly used

     signal clk_div_8_s : std_logic; -- Input clock divided by 8 (6.25 MHz)
     signal clk_50_s, clk_10_s : std_logic; -- 50 and 10 MHz clocks
     signal locked_out_s : std_logic;

     signal rst_s, dac_adc_run_s : std_logic;
     signal have_sample_s, need_sample_s : std_logic;
     signal in_sample_s : std_logic_vector(ADC_VAL_SIZE - 1 downto 0);
     signal in_signal_s, in_signal_scaled_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
     signal tmp_out_sample_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
     signal out_sample_s : std_logic_vector(DAC_VAL_SIZE - 1 downto 0);
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

     --- Others ---
     signal out_signal_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
begin
     platform_i : entity work.platform(beh)
          port map (
               CLKIN_IN => clk,
               RST_IN => '0',
               CLKDV_OUT => clk_div_8_s,
               CLKIN_IBUFG_OUT => open,
               CLK0_OUT => clk_50_s,
               CLKFX_OUT => clk_10_s,
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
               clk => clk_div_8_s, -- clk_50_s is TOO FAST!!!
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

     -- Scale the input signal by 0.5
     -- That is: input signal range is (-0.5, 0.5).
     in_signal_scaler : entity work.k_2_div(alg)
          generic map (
               width => PIPELINE_WIDTH)
          port map (
               i => in_signal_s,
               o => in_signal_scaled_s);

     -- out_signal_s = in_signal_scaled_s + 0.5
     -- That is: add 0.5 to in_signal_scaled_s so out_signal_s range is (0, 1).
     in_signal_adder : entity work.adder(alg)
          generic map (
               width => PIPELINE_WIDTH)
          port map (
               a => in_signal_scaled_s,
               b => to_vector(0.5, PIPELINE_WIDTH, PIPELINE_PREC),
               o => out_signal_s,
               f_ov => open,
               f_z => open);
     
     state_ctrl : process(clk_10_s, locked_out_s, gain_done_s, pga_wait_cnt_s)
     begin
          if (rising_edge(clk_10_s)) then
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
                              st <= ST_START_AMP_PROG;
                         when ST_START_AMP_PROG =>
                              -- prog_amp_i uses a different clock. We must be careful, as we can be
                              -- _too_ fast and the signal requesting the amp programming be kept
                              -- not enough time. We must wait until the prog_amp instance tells us
                              -- that it's programming
                              if (gain_done_s = '0') then
                                   st <= ST_AMP_PROG;
                              else
                                   st <= ST_START_AMP_PROG;
                              end if;
                         when ST_AMP_PROG =>
                              if (gain_done_s = '1') then
                                   st <= ST_WAIT_AFTER_AMP_PROG;
                              else
                                   st <= ST_AMP_PROG;
                              end if;
                         when ST_WAIT_AFTER_AMP_PROG =>
                              -- This is just a 1 clk cycle for the AMP nCS signal to stabilize at
                              -- high value before disturbing once more the SPI bus
                              if (pga_wait_ctr_last_s = '1') then
                                   st <= ST_START_AMP_PROG;
                              else
                                   st <= ST_WAIT_AFTER_AMP_PROG;
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

     state_signals_gen : process(st)
     begin
          case st is
               when ST_WARMING =>
                    rst_s <= '0';
                    dac_adc_run_s <= '0';

                    set_gain_s <= '0';
                    pga_wait_ctr_rst_s <= '0';
                    spi_prog_amp_owned_s <= '0';
                    
                    led(0) <= '1';
                    led(1) <= '0';
                    led(2) <= '0';
                    
               when ST_RST =>
                    rst_s <= '1';
                    dac_adc_run_s <= '0';

                    set_gain_s <= '0';
                    pga_wait_ctr_rst_s <= '0';
                    spi_prog_amp_owned_s <= '0';
                    
                    led(0) <= '0';
                    led(1) <= '1';
                    led(2) <= '0';
                    
               when ST_START_AMP_PROG =>
                    rst_s <= '0';
                    dac_adc_run_s <= '0';
                    
                    set_gain_s <= '1';
                    pga_wait_ctr_rst_s <= '0';
                    spi_prog_amp_owned_s <= '1';
                    
                    led(0) <= '1';
                    led(1) <= '1';
                    led(2) <= '0';
                    
               when ST_AMP_PROG =>
                    rst_s <= '0';
                    dac_adc_run_s <= '0';
                    
                    set_gain_s <= '0';
                    pga_wait_ctr_rst_s <= '1';
                    spi_prog_amp_owned_s <= '1';
                    
                    led(0) <= '0';
                    led(1) <= '0';
                    led(2) <= '1';

               -- HASTA AQU� S� QUE EST� FUNCIONANDO!!!
                    -- M�s o menos. Lo estoy poniendo en bucle desde el comienzo de la programaci�n
                    -- hasta este punto y ...por lo menos veo que el PGA comienza a funcinoar. Sin
                    -- embargo, los niveles de salida NO SON CORRECTOS! Parece que puede haber algo
                    -- mal!!
                    -- Vamos a probar a DEJARLO QUIETO
               when ST_WAIT_AFTER_AMP_PROG =>
                    rst_s <= '0';
                    dac_adc_run_s <= '0';
                    
                    set_gain_s <= '0';
                    pga_wait_ctr_rst_s <= '0';
                    spi_prog_amp_owned_s <= '1';
                    
                    led(0) <= '1';
                    led(1) <= '0';
                    led(2) <= '1';
                    
               when ST_RUNNING =>
                    rst_s <= '0';
                    dac_adc_run_s <= '0';
                    
                    set_gain_s <= '0';
                    pga_wait_ctr_rst_s <= '0';
                    spi_prog_amp_owned_s <= '0';
                    
                    led(0) <= '0';
                    led(1) <= '1';
                    led(2) <= '1';
                    
               when others =>
                    rst_s <= '0';
                    dac_adc_run_s <= '0';
                    
                    set_gain_s <= '0';
                    pga_wait_ctr_rst_s <= '0';
                    spi_prog_amp_owned_s <= '0';
                    
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
          cnt : process(clk_10_s)
               variable val : natural;
          begin
               if (rising_edge(clk_10_s)) then
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
     

     -- Keep the ADC pre-amp ON (shutdown = '0')
     amp_shdn <= '0';
     amp_ncs <= amp_ncs_s;
     
     spi_owned_in_s <= '0';

     spi_signals_gen: block is
     begin
          spi_mosi_s <= dac_adc_spi_mosi_s or prog_amp_spi_mosi_s;
          spi_sck_s <= dac_adc_spi_sck_s or prog_amp_spi_sck_s;
          spi_owned_s <= spi_dac_adc_owned_s or spi_prog_amp_owned_s;

          -- spi_mosi <= spi_mosi_s;
          -- spi_mosi <= 'Z' when (spi_owned_s = '0') else spi_mosi_s;
          -- spi_sck <= 'Z' when (spi_owned_s = '0') else spi_sck_s;
     end block;
     spi_mosi <= spi_mosi_s;
     spi_sck <= spi_sck_s;
     

     led(3) <= in_sample_s(13);

     -- Convert out_signal_s to the correct DAC format
     assert PIPELINE_PREC = DAC_VAL_SIZE report "OOOPS. You have changed PIPELINE_PREC. Update this code, please" severity failure;
     out_sample_s <= out_signal_s(PIPELINE_PREC - 1 downto 0);     
     
     -- Other debug signals unused
     led(7 downto 4) <= (others => '0');
     debug_d7 <= spi_mosi_s;
     debug_c7 <= spi_sck_s; 
     debug_f8 <= amp_ncs_s;
     debug_e8 <= '0';

end architecture beh;
