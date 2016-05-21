--------------------------------------------------------------------------------
-- *** Brief description ***
--
-- Block which encapsulates all the logic for interfacing the Digilent Spartan-3E board Linear SPI
-- ADC and DAC ICs.
--
-- *** Description ***
--
-- Digilent board includes a quad DAC and dual channel ADC, connected thru a shared SPI bus,
-- between them and between other components.
--
-- This is the Interface to the Digilent LT SPI ADC and DAC ICs. Digilent board includes a quad DAC
-- and ADC, connected thru a shared SPI bus. ADC input stage includes a programmable gain amp, which
-- we don't use.
--
-- ** ICs (ADC/DAC) basic specs **
--
-- * DAC specs *
-- -> -3 db freq: 180 KHz. At 100 KHz response is still at 0 dB.
-- -> 12 bit resolution (32 bit instruction size)
-- -> Channels A & B: voltage reference = 3.3 V (max voltage)
-- -> Channels C & D: voltage reference = 2.5 V (max voltage)
--
-- * ADC specs *
-- -> 14 bit resolution
-- -> Bipolar input range, representation of value in 2s complement (1 bit for
-- magnitude)
-- -> max(f_s) = 1.5 MHz!
-- -> Período de reloj mínimo: 19.6 ns 
--
-- With the FPGA board input stage, dynamic range is +- 1.25 V, centered in
-- 1.65 V
--  
-- 
-- ** SPI driving **
--
-- To simplify implementation and avoid carefull checking of Linear Tech devices timings (DAC and
-- ADC chips), we're gonna drive the SPI bus at half sys clk => 25 MHz. It's fast enough for our app
-- and allows design simplification.
--
-- * Delay between DAC and ADC *
--
-- One basic problem arises: both devices cannot be driven simultaneously, as
-- both share the SPI bus. Ideally, on a sampling (discreete time) system:
--     ^
--     |
-- In -| old  - new
--     |      |
-- Out-| old  - new
--     |      |
--     -------|------> t
--
-- New input sample and new ouput sample should be captured at the same moment. Here our decision is
-- to first set the new value with the DAC and after the minimum possible delay (1 / 25 MHz * 32
-- bits, plus a little more) get the new [old :)] input.
-- 
-- ** Sample frequency **
--
-- We set the INPUT and OUPUT sampling freq. to 10 KHz, so we have enough room. Also, higher
-- sampling freq is not needed in our app. Input clock signal must have a certain _specific_
-- frequency. Check 'clk' in port documentation.
-- 
-- * How to set DAC fs *
--
-- Sampling freq depends on the signals sent by the FPGA (esentially last SPI SCK 
-- rising edge). We must be carefull and get a steady SCK signal clock
-- 
-- ** PORT DESCRIPTION **
--
-- * [in] clk: input clock. Entity expects a hardcoded clock freq of 12.5 MHz
--
-- * [out] have_sample: sube a 1 durante 1 ciclo: el siguiente a recibir el nuevo valor del adc
--                      Justo durante ese ciclo ya está el nuevo valor de entrada en in_sample.
--
-- * [out] in_sample: la muestra recibida desde el canal 1 (VINA en la placa) del ADC. Permanece
-- _estable_ (no es necesario que sea registrado fuera de este bloque)
--
-- * [out] need_sample: sube a 1 durante 1 ciclo, el anterior a tener q usar el nuevo valor para el DAC.
--                      Justo en el siguiente rising edge, el valor en out_sample es leído
--
-- ** HOW TO CONTROL ME **
--
-- Tell me to run (run = 1). I have my own "internal reference" of timings, as this block takes care
-- of maintaining a CONSTANT fs (sampling period).
-- 
-- *** Todo ***
--
-- * This block should exclusively MANAGE CS signals for the DAC and ADC, not the rest of the
-- elements in the SPI chain. Should be changed!
--
-- * (DONE) Check what problems can arise if interface with internal logic is driven by the half
--   speed clock
--   THERE WAS NOT half speed interfacing with the rest of the world at all
--
-- * Study fusion of dac and adc st control. They're not the same but quite similar.
--
-- * Study posibility of reducing global cntr size at least by 1 by using a reduced input clock
--
-- *** Revision ***
--
-- Revision 0.07 - REVERT last BUG CORRECTION (adc_shift_reg we signal). IT WAS OK (remember once WE
-- is up, it's in next cycle when storing takes place!!).  Also, revert one of the assert, which was
-- incorrect (the one on run_dac and global st DAC_LAST)
--
-- Revision 0.06 - Added some more asserts missing in some elses in signal generation
-- procedures. CORRECTED adc shift register WE signal generation: it was being generating in the
-- first data sub state; in this substate, spi_clk is being rised, and we have to wait till it's
-- stable, in the next substate.
--
-- Revision 0.05 - Some minor changes. adc_spi_miso (specific miso ADC) was not being used, as input
-- shit reg was being driven directly with global miso signal. In global_st FSM signal generation
-- process, some drivings for global_cnt_d were missing, making synthesizer think it was a register
-- and not "logic". adc_shift_reg_load was not being used, as in adc shift reg port map, load port
-- was being directly tied to 0 value
--
-- Revision 0.04 - Final corrections: corrected total clock count (to get a fixed 20 KHz signal), I
-- was not waiting between ADC transfers, and have_sample signal implementation was missing
--
-- Revision 0.03 - Removed Z output on dac_spi_sck, adc_spi_sck and dac_spi_mosi on respective
-- signal gen processes. We're not being as "optimal" as we could, as in reality thru the use of
-- spi_owned we're wasting more SPI cycles (two or three as much) as the real ones needed to finish
-- the communication with ADC and DAC. But this way, it's easier.
--
-- Revision 0.02 - First edited thru Emacs! Long life to Emacs! (and vhdl-mode)
--
-- Revision 0.01 - File Created
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use WORK.COMMON.ALL;

entity dac_adc is
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
	  in_sample : out std_logic_vector(ADC_VAL_SIZE - 1 downto 0);
	  have_sample : out std_logic;
	  out_sample : in std_logic_vector(DAC_VAL_SIZE - 1 downto 0);
	  need_sample : out std_logic;
	  clk : in std_logic;
	  rst : in std_logic; -- Async reset
	  run : in std_logic; -- Tell this to run
	  spi_owned_out : out std_logic;
	  spi_owned_in : in std_logic -- Daisy chaining
	  );
end dac_adc;


architecture beh of dac_adc is
     constant TOTAL_CYCLES : natural := 624;
     -- Cycles needed for 20 KHz sampling rate:
     -- f_clk = 50 MHz -> calculated: 2500; measured with ModelSim: 2499
     -- f_clk / 4 = 12.5 MHz -> 624
     -- f_clk / 8 = 6.25 MHz -> 312
     -- Cycles needed for 10 KHz sampling rate:
     -- f_clk = 50 MHz -> calculated: 5000; measured with ModelSim: 4998
     -- f_clk / 8 = 6.25 MHz -> 624

     constant DAC_INS_SIZE : natural := 32;
     constant DAC_REAL_INS_SIZE : natural := 20;
     constant DAC_CMD_SIZE : natural := 4;
     constant DAC_ADDR_SIZE : natural := 4;
     -- constant DAC_VAL_SIZE : natural := 12; -- Already defined in common,
     -- as it's needed for some of the input port widths
     constant DAC_PREAMBLE_SIZE : natural := 8;
     constant DAC_POSTDATA_SIZE : natural := 4;

     type dac_state_t is (
	  DAC_ST_IDLE, DAC_ST_WAKE_UP,
	  DAC_ST_PREAMBLE_0, DAC_ST_PREAMBLE_1,
	  DAC_ST_DATA_0, DAC_ST_DATA_1,
	  DAC_ST_POSTDATA_0, DAC_ST_POSTDATA_1
	  );
     signal dac_st : dac_state_t;
     -- DAC cntr related signals
     constant DAC_CNTR_SIZE : natural := 5;
     signal dac_cnt : std_logic_vector(DAC_CNTR_SIZE - 1 downto 0); -- 5 bit counter
     signal dac_cntr_en, dac_cntr_load : std_logic;
     signal dac_cntr_d : std_logic_vector(DAC_CNTR_SIZE - 1 downto 0);
     -- DAC shifter related signals
     signal dac_ins_s : std_logic_vector(DAC_REAL_INS_SIZE - 1 downto 0);
     alias dac_cmd_s : std_logic_vector(DAC_CMD_SIZE - 1 downto 0) is dac_ins_s(DAC_REAL_INS_SIZE - 1 downto DAC_REAL_INS_SIZE - DAC_CMD_SIZE);
     alias dac_addr_s : std_logic_vector(DAC_ADDR_SIZE - 1 downto 0) is dac_ins_s(DAC_REAL_INS_SIZE - DAC_CMD_SIZE - 1 downto DAC_REAL_INS_SIZE - DAC_CMD_SIZE - DAC_ADDR_SIZE);
     alias dac_val_s : std_logic_vector(DAC_VAL_SIZE - 1 downto 0) is dac_ins_s(DAC_REAL_INS_SIZE - DAC_CMD_SIZE - DAC_ADDR_SIZE - 1 downto 0);
     signal dac_shift_reg_o : std_logic_vector(DAC_REAL_INS_SIZE - 1 downto 0);
     alias dac_ins_bitstream_s : std_logic is dac_shift_reg_o(DAC_REAL_INS_SIZE - 1);
     signal dac_shift_reg_load, dac_shift_reg_we : std_logic;

     -- constant ADC_VAL_SIZE : natural := 14; -- Already in common, as
     -- it's needed by some ports to define its width
     constant ADC_PREAMBLE_SIZE : natural := 2; -- # of SCK cycles to wait before reading ADC data
     constant ADC_POSTDATA_SIZE : natural := 4; -- # of cycles to wait sending SCK cycles yet after ADC data reception

     type adc_state_t is (
	  ADC_ST_IDLE, ADC_ST_WAKE_UP,
	  ADC_ST_PREAMBLE_0, ADC_ST_PREAMBLE_1,
	  ADC_ST_DATA_0, ADC_ST_DATA_1,
	  ADC_ST_GARBAGE_0, ADC_ST_GARBAGE_1,
	  ADC_ST_POSTDATA_0, ADC_ST_POSTDATA_1
	  );
     signal adc_st : adc_state_t;
     -- ADC cntr related signals
     constant ADC_CNTR_SIZE : natural := 4; -- Max value to be stored: 16 - 1
                                            -- (for 14 bits + 2 Z bits data count)
     signal adc_cnt : std_logic_vector(ADC_CNTR_SIZE - 1 downto 0); -- 4 bit counter
     signal adc_cntr_load, adc_cntr_en : std_logic;
     signal adc_cntr_d : std_logic_vector(ADC_CNTR_SIZE - 1 downto 0);
     -- ADC shifter related signals
     signal adc_val_s : std_logic_vector(ADC_VAL_SIZE - 1 downto 0);
     signal adc_shift_reg_we : std_logic;

     signal adc_spi_sck, dac_spi_sck, dac_spi_mosi : std_logic;
     signal run_dac : std_logic; -- 1 => is dac turn | 0 => dac off.
     signal run_adc : std_logic; -- 1 => is adc turn | 0 => adc off.
     signal dac_ended, adc_ended : std_logic;

     type global_state_t is (
	  GLOBAL_ST_IDLE, GLOBAL_ST_INIT, GLOBAL_ST_DAC, GLOBAL_ST_DAC_LAST, GLOBAL_ST_ADC, GLOBAL_ST_WAIT
	  );
     signal global_st : global_state_t;
     -- GLOBAL cntr related signals
     constant GLOBAL_CNTR_SIZE : natural := 12; -- Max value: 2.5e3
     signal global_cnt : std_logic_vector(GLOBAL_CNTR_SIZE - 1 downto 0);
     signal global_cntr_load : std_logic;
     signal global_cntr_d : std_logic_vector(GLOBAL_CNTR_SIZE - 1 downto 0);
begin
     dac_cmd_s <= "0011"; -- Always the same command: write and update
     dac_addr_s <= "0000"; -- Output thru DAC a

     -- Sample logic => DAC (out to the real world)
     --
     -- As the pipeline has an idea about prec and magnitude, some care could be taken when
     -- converting the DAC and ADC word widths to the pipeline (16 bis). But we don't do that here.
     --
     -- We DON'T HAVE width as a generic of this block.
     --
     -- We're not gonna do here suppositions about DAC input voltage range or how it converts it (2s
     -- complement, sign + magnitude ...). We only have to know that this is a 12 bits DAC, and the
     -- RAW value is passed to the block using us. That's all.
     dac_val_s <= out_sample;

     -- Sample ADC => logic (in from the real world). See comment in DAC transformation above.
     in_sample <= adc_val_s;
     
     dac_shift_reg : entity work.shift_reg(alg)
	  generic map (
	       width => DAC_REAL_INS_SIZE
           -- Rest default are OK
	       )
	  port map (
	       clk => clk,
	       load => dac_shift_reg_load,
	       we => dac_shift_reg_we,
	       s_in => "0",
	       p_in => dac_ins_s,
	       o => dac_shift_reg_o
	       );

     adc_shift_reg : entity work.shift_reg(alg)
	  generic map (
	       width => ADC_VAL_SIZE
	   -- Rest defaults are OK (ADC sends first MSB => must shift left)
	       )
	  port map (
	       clk => clk,
	       load => '0',
	       we => adc_shift_reg_we,
	       s_in(0) => spi_miso,
	       p_in => std_logic_vector(to_unsigned(0, ADC_VAL_SIZE)),
	       o => adc_val_s);

     global_state_ctrl : process(clk, rst)
     begin
	  if (rst = '1') then
	       global_st <= GLOBAL_ST_IDLE;
	  else
	       if (rising_edge(clk)) then
		    case global_st is
			 when GLOBAL_ST_IDLE =>
			      if (run = '0') then
				   global_st <= GLOBAL_ST_IDLE;
			      else
				   global_st <= GLOBAL_ST_INIT;
			      end if;
			 when GLOBAL_ST_INIT =>
			      global_st <= GLOBAL_ST_DAC;
			 when GLOBAL_ST_DAC =>
			      if (dac_ended = '1') then
				   global_st <= GLOBAL_ST_DAC_LAST;
			      else
				   global_st <= GLOBAL_ST_DAC;
			      end if;
			 when GLOBAL_ST_DAC_LAST =>
			      global_st <= GLOBAL_ST_ADC;
			 when GLOBAL_ST_ADC =>
			      if (adc_ended = '1') then
				   global_st <= GLOBAL_ST_WAIT;
			      else
				   global_st <= GLOBAL_ST_ADC;
			      end if;
			 when GLOBAL_ST_WAIT =>
			      if (to_integer(unsigned(global_cnt)) = 0) then
				   if (run = '1') then
					global_st <= GLOBAL_ST_INIT;
				   else
					global_st <= GLOBAL_ST_IDLE;
				   end if;
			      else
				   global_st <= GLOBAL_ST_WAIT;
			      end if;
			 when others =>
			      global_st <= global_st;
			      report "Unknown global state! Should not happen!" severity error; --
		    end case;
	       end if;
	  end if;
     end process global_state_ctrl;

     -- Takes care of:
     -- External signals:
     -- spi_owned_out
     -- Internal signals:
     -- run_dac, run_adc
     -- global_cntr_load, global_cntr_d
     -- 
     global_signal : process(global_st)
     begin
	  case global_st is
	       when GLOBAL_ST_IDLE =>
                    spi_owned_out <= '0';
		    run_dac <= '0';
		    run_adc <= '0';
		    global_cntr_load <= '0';
                    global_cntr_d <= (others => '0');  -- Should be '-', but
                                                       -- Xilinx ISE is stupid
                                                       -- during synthesis
	       when GLOBAL_ST_INIT =>
                    spi_owned_out <= '1';
		    run_dac <= '1';
		    run_adc <= '0';
		    global_cntr_load <= '1';
		    global_cntr_d <= std_logic_vector(to_unsigned(TOTAL_CYCLES - 1, GLOBAL_CNTR_SIZE));
	       when GLOBAL_ST_DAC =>
                    spi_owned_out <= '1';
		    run_dac <= '1';
		    run_adc <= '0';
		    global_cntr_load <= '0';
                    global_cntr_d <= (others => '0');  -- See note above
	       when GLOBAL_ST_DAC_LAST =>
                    spi_owned_out <= '1';
		    run_dac <= '0';
		    run_adc <= '1';
		    global_cntr_load <= '0';
                    global_cntr_d <= (others => '0');
	       when GLOBAL_ST_ADC =>
                    spi_owned_out <= '1';
		    run_dac <= '0';
		    run_adc <= '1';
		    global_cntr_load <= '0';
                    global_cntr_d <= (others => '0');
	       when GLOBAL_ST_WAIT =>
                    spi_owned_out <= '0';
		    run_dac <= '0';
		    run_adc <= '0';
		    global_cntr_load <= '0';
                    global_cntr_d <= (others => '0');
	       when others =>
                    spi_owned_out <= '-';
		    run_dac <= '-';
		    run_adc <= '-';
		    global_cntr_load <= '-';
                    global_cntr_d <= (others => '0');
                    report "Unknown global state!!! Should not happen!!!"
			 severity error;
	  end case;
     end process global_signal;

     -- Global cntr: measures the exact time to sample at 20 KHz, given the 50 MHz clock
     global_cntr : process(clk)
     begin
	  if (rising_edge(clk)) then
	       if (global_cntr_load = '1') then
		    global_cnt <= global_cntr_d;
	       else
		    global_cnt <= std_logic_vector(to_unsigned(to_integer(unsigned(global_cnt)) - 1, GLOBAL_CNTR_SIZE));
	       end if;
	  end if;
     end process global_cntr;

     dac_state_ctrl : process(clk, rst)
     begin
	  if (rst = '1') then
	       dac_st <= DAC_ST_IDLE;
	  else
	       if (rising_edge(clk)) then
		    case dac_st is
			 when DAC_ST_IDLE =>
			      if (run_dac = '1') then
				   dac_st <= DAC_ST_WAKE_UP;
			      else
				   dac_st <= DAC_ST_IDLE;
			      end if;
			 when DAC_ST_WAKE_UP =>
			      if (run_dac = '1') then
				   dac_st <= DAC_ST_PREAMBLE_0;
			      else
                                   report "DAC comm internally interrupted. Should not happen!!!"
					severity error;
				   dac_st <= DAC_ST_IDLE;
			      end if;
			 when DAC_ST_PREAMBLE_0 =>
			      if (run_dac = '1') then
				   dac_st <= DAC_ST_PREAMBLE_1;
			      else
                                   report "DAC comm internally interrupted. Shuold not happen!!!"
					severity error;
				   dac_st <= DAC_ST_IDLE;
			      end if;
			 when DAC_ST_PREAMBLE_1 =>
			      if (run_dac = '1') then
				   if (to_integer(unsigned(dac_cnt)) = 0) then
					dac_st <= DAC_ST_DATA_0;
				   else
					dac_st <= DAC_ST_PREAMBLE_0;
				   end if;
			      else
                                   report "DAC comm internally interrupted. Shuold not happen!!!"
					severity error;
				   dac_st <= DAC_ST_IDLE;
			      end if;
			 when DAC_ST_DATA_0 =>
			      if (run_dac = '1') then
				   dac_st <= DAC_ST_DATA_1;
			      else
                                   report "DAC comm internally interrupted. Shuold not happen!!!"
					severity error;
				   dac_st <= DAC_ST_IDLE;
			      end if;
			 when DAC_ST_DATA_1 =>
			      if (run_dac = '1') then
				   if (to_integer(unsigned(dac_cnt)) = 0) then
					dac_st <= DAC_ST_POSTDATA_0;
				   else
					dac_st <= DAC_ST_DATA_0;
				   end if;
			      else
                                   report "DAC comm internally interrupted. Shuold not happen!!!"
					severity error;
				   dac_st <= DAC_ST_IDLE;
			      end if;
			 when DAC_ST_POSTDATA_0 =>
			      if (run_dac = '1') then
				   dac_st <= DAC_ST_POSTDATA_1;
			      else
                                   report "DAC comm internally interrupted. Shuold not happen!!!"
                                      severity error;
                                  dac_st <= DAC_ST_IDLE;                                  
			      end if;
			 when DAC_ST_POSTDATA_1 =>
			      if (run_dac ='1') then
				   if (to_integer(unsigned(dac_cnt)) = 0) then
                                       dac_st <= DAC_ST_IDLE;
				   else
                                       dac_st <= DAC_ST_POSTDATA_0;
				   end if;
			      else
                                  -- This should not happen.
                                  -- Global control detects THIS CYCLE it's last dac
                                  -- iteration, and next cycle, DAC_LAST global
                                  -- state is set and run_dac is lowered. But
                                  -- NOT NOW
                                  assert run_dac = '1' report "DAC comm 'almost' internally interrupted. Should not happen" severity warning;
                                  dac_st <= DAC_ST_IDLE;
			      end if;
			 when others =>
                              report "Unknown DAC state!!! Should not happen!!!"
				   severity error;
			      dac_st <= dac_st;
		    end case;
	       end if;
	  end if;
     end process dac_state_ctrl;

     -- Takes care of the DAC counter.
     -- Inputs: dac_cntr_load, dac_cntr_d
     -- Outputs: dac_cnt
     dac_cntr : process(clk)
     begin
	  if (rising_edge(clk)) then
	       if (dac_cntr_en = '1') then
		    if (dac_cntr_load = '1') then
			 dac_cnt <= dac_cntr_d;
		    else
			 dac_cnt <= std_logic_vector(to_unsigned(to_integer(unsigned(dac_cnt)) - 1, DAC_CNTR_SIZE));
		    end if;
	       end if;
	  end if;
     end process dac_cntr;

     -- This process takes care of following signals:
     -- * dac_ncs
     -- * SPI_CLK [dac_spi_sck], SPI_MOSI [dac_spi_mosi] (when DAC on)
     -- * dac_cntr_en, dac_cntr_load, dac_cntr_d
     -- * dac_shift_reg_load, dac_shift_reg_we
     -- * dac_ended
     -- In reality, ideal process should just need dac-st and dac_cnt signals
     -- in its sensitivity list. As I don't want strange synthesis behaviour
     -- with this peace of combinational logic, let's just add all the "input"
     -- signals to this process (dac_ins_bitstream_s - ISE complaints about
     -- signal missing in proc. sens. list, as this is an alias; we just add
     -- the whole signal)
     dac_signal : process(dac_st, dac_cnt, dac_shift_reg_o)
     begin
	  case dac_st is
	       when DAC_ST_IDLE =>
		    -- External
		    dac_ncs <= '1';
		    dac_spi_sck <= '0';
		    dac_spi_mosi <= '0';
		    -- Internal
                    dac_ended <= '0';
		    dac_shift_reg_we <= '0';
		    dac_shift_reg_load <= '0';
		    dac_cntr_en <= '0';
		    dac_cntr_load <= '-';
                    dac_cntr_d <= (others => '0');  -- Should be '-'
                    
	       when DAC_ST_WAKE_UP =>
		    -- * External *
		    dac_ncs <= '0';
		    dac_spi_sck <= '0';
		    dac_spi_mosi <= '0';
		    -- * Internal *
		    dac_ended <= '0';
		    -- Load sample to be output
		    dac_shift_reg_we <= '1';
		    dac_shift_reg_load <= '1';
		    -- Load preamble size in counter
		    dac_cntr_en <= '1';
		    dac_cntr_load <= '1';
		    dac_cntr_d <= std_logic_vector(to_unsigned(DAC_PREAMBLE_SIZE - 1, DAC_CNTR_SIZE));
                    
	       when DAC_ST_PREAMBLE_0 =>
                 -- STATE DESCRIPTION:
                 -- DAC_ST_PREAMBLE sends the first 8 bits block of "don't
                 -- care" bits on the DAC SPI packet format (see LTC datasheet).
                 -- As always, it's formed by two sub states, 0 and 1, for the
                 -- rising and falling edge of spi clk signal
                 
		    -- *External *
		    dac_ncs <= '0';
		    dac_spi_sck <= '0';
		    dac_spi_mosi <= '-'; -- Indiferent. See DAC_ST_PREAMBLE_1 comment
		    -- * Internal *
		    dac_ended <= '0';
		    dac_shift_reg_we <= '0';
		    dac_shift_reg_load <= '0';
		    dac_cntr_en <= '0';
		    dac_cntr_load <= '-';
                    dac_cntr_d <= (others => '0');
                    
	       when DAC_ST_PREAMBLE_1 =>
		    -- * External *
		    dac_ncs <= '0';
		    dac_spi_sck <= '1';
		    dac_spi_mosi <= '-'; -- Should be '-' so it can optimize it; but ModelSim simulates "strange" output :)
		    -- * Internal *
		    dac_ended <= '0';
		    dac_shift_reg_we <= '0';
		    dac_shift_reg_load <= '-';
		    dac_cntr_en <= '1';
		    if (to_integer(unsigned(dac_cnt)) = 0) then
					-- Load data size in counter
			 dac_cntr_load <= '1';
			 dac_cntr_d <= std_logic_vector(to_unsigned(DAC_REAL_INS_SIZE - 1, DAC_CNTR_SIZE));
		    else
			 dac_cntr_load <= '0';
                         dac_cntr_d <= (others => '0');
		    end if;
                    
	       when DAC_ST_DATA_0 =>
                 -- STATE DESCRIPTION:
                 -- Takes care of sending the real data. DAC command is stores
                 -- in a shift register and send using the same 2 substates scheme.
		    -- External
		    dac_ncs <= '0';
		    dac_spi_sck <= '0';
		    dac_spi_mosi <= dac_ins_bitstream_s;
		    -- Internal
		    dac_ended <= '0';
		    dac_shift_reg_we <= '0';
		    dac_shift_reg_load <= '-';
		    dac_cntr_en <= '0';
		    dac_cntr_load <= '-';
                    dac_cntr_d <= (others => '0');
                    
	       when DAC_ST_DATA_1 =>
		    -- External
		    dac_ncs <= '0';
		    dac_spi_sck <= '1';
		    dac_spi_mosi <= dac_ins_bitstream_s;
		    -- Internal
		    dac_ended <= '0';
		    dac_shift_reg_we <= '1';
		    dac_shift_reg_load <= '0';
		    dac_cntr_en <= '1';
		    if (to_integer(unsigned(dac_cnt)) = 0) then
					-- Load postdata size in counter
			 dac_cntr_load <= '1';
			 dac_cntr_d <= std_logic_vector(to_unsigned(DAC_POSTDATA_SIZE - 1, DAC_CNTR_SIZE));
		    else
			 dac_cntr_load <= '0';
                         dac_cntr_d <= (others => '0');  -- Should be '-'
		    end if;
                    
	       when DAC_ST_POSTDATA_0 =>
                 -- STATE DESCRIPTION:
                 -- Takes care of sending the stupid "don't care" 4 least significant bits
                 -- of packet
                                  -- External
		    dac_ncs <= '0';
		    dac_spi_sck <= '0';
		    dac_spi_mosi <= '-';
		    -- Internal
		    dac_ended <= '0';
		    dac_shift_reg_we <= '0';
		    dac_shift_reg_load <= '0';
		    dac_cntr_en <= '0';
		    dac_cntr_load <= '-';
                    dac_cntr_d <= (others => '0');  -- Should be '-'
	       when DAC_ST_POSTDATA_1 =>
		    -- External
		    dac_ncs <= '0';
		    dac_spi_sck <= '1';
		    dac_spi_mosi <= '-';
		    -- Internal
		    if (to_integer(unsigned(dac_cnt)) = 0) then
			 dac_ended <= '1';
		    else
			 dac_ended <= '0';
		    end if;
		    dac_shift_reg_we <= '0';
		    dac_shift_reg_load <= '0';
		    dac_cntr_en <= '1';
		    dac_cntr_load <= '0';
                    dac_cntr_d <= (others => '0');  -- Should be '-'
                    
	       when others =>
		    -- External
		    dac_ncs <= '-';
		    dac_spi_sck <= '-';
		    dac_spi_mosi <= '-';
		    -- Internal
		    dac_ended <= '-';
		    dac_shift_reg_we <= '-';
		    dac_shift_reg_load <= '-';
		    dac_cntr_en <= '-';
		    dac_cntr_load <= '-';
                    dac_cntr_d <= (others => '-');
                    report "Unknown DAC state!!! Should not happen!!!"
			 severity error;
	  end case;
     end process dac_signal;

     -- State ctrl for the ADC comm part.
     -- It's very similar to the DAC one! Only difference is with GARBAGE state
     -- Fusion effort shuold be considered
     adc_state_ctrl : process(clk, rst)
     begin
	  if (rst = '1') then
	       adc_st <= ADC_ST_IDLE;
	  else
	       if (rising_edge(clk)) then
		    case adc_st is
			 when ADC_ST_IDLE =>
			      if (run_adc = '1') then
				   adc_st <= ADC_ST_WAKE_UP;
			      else
				   adc_st <= ADC_ST_IDLE;
			      end if;
			 when ADC_ST_WAKE_UP =>
			      if (run_adc = '1') then
				   adc_st <= ADC_ST_PREAMBLE_0;
			      else
                                   report "ADC comm internally interrupted. Should not happen!!!"
					severity error;
				   adc_st <= ADC_ST_IDLE;
			      end if;
			 when ADC_ST_PREAMBLE_0 =>
			      if (run_adc = '1') then
				   adc_st <= ADC_ST_PREAMBLE_1;
			      else
                                   report "ADC comm internally interrupted. Shuold not happen!!!"
					severity error;
				   adc_st <= ADC_ST_IDLE;
			      end if;
			 when ADC_ST_PREAMBLE_1 =>
			      if (run_adc = '1') then
				   if (to_integer(unsigned(adc_cnt)) = 0) then
					adc_st <= ADC_ST_DATA_0;
				   else
					adc_st <= ADC_ST_PREAMBLE_0;
				   end if;
			      else
                                   report "ADC comm internally interrupted. Shuold not happen!!!"
					severity error;
				   adc_st <= ADC_ST_IDLE;
			      end if;
			 when ADC_ST_DATA_0 =>
			      if (run_adc = '1') then
				   adc_st <= ADC_ST_DATA_1;
			      else
                                   report "ADC comm internally interrupted. Shuold not happen!!!"
					severity error;
				   adc_st <= ADC_ST_IDLE;
			      end if;
			 when ADC_ST_DATA_1 =>
			      if (run_adc = '1') then
				   if (to_integer(unsigned(adc_cnt)) = 0) then
					adc_st <= ADC_ST_GARBAGE_0;
				   else
					adc_st <= ADC_ST_DATA_0;
				   end if;
			      else
                                   report "DAC comm internally interrupted. Shuold not happen!!!"
					severity error;
				   adc_st <= ADC_ST_IDLE;
			      end if;
			 when ADC_ST_GARBAGE_0 =>
			      if (run_adc = '1') then
				   adc_st <= ADC_ST_GARBAGE_1;
			      else
                                   report "ADC comm internally interrupted. Shuold not happen!!!"
					severity error;
				   adc_st <= ADC_ST_IDLE;
			      end if;
			 when ADC_ST_GARBAGE_1 =>
			      if (run_adc = '1') then
				   if (to_integer(unsigned(adc_cnt)) = 0) then
					adc_st <= ADC_ST_POSTDATA_0;
				   else
					adc_st <= ADC_ST_GARBAGE_0;
				   end if;
			      else
                                   report "DAC comm internally interrupted. Shuold not happen!!!"
					severity error;
				   adc_st <= ADC_ST_IDLE;
			      end if;
			 when ADC_ST_POSTDATA_0 =>
			      if (run_adc = '1') then
				   adc_st <= ADC_ST_POSTDATA_1;
			      else
			      end if;
			 when ADC_ST_POSTDATA_1 =>
			      if (run_adc ='1') then
				   if (to_integer(unsigned(adc_cnt)) = 0) then
					adc_st <= ADC_ST_IDLE;
				   else
					adc_st <= ADC_ST_POSTDATA_0;
				   end if;
			      else
			      end if;
			 when others =>
                              report "Unknown DAC state!!! Should not happen!!!"
				   severity error;
			      adc_st <= adc_st;
		    end case;
	       end if;
	  end if;
     end process adc_state_ctrl;

     -- Takes care of the DAC counter.
     -- Inputs: dac_cntr_load, dac_cntr_d
     -- Outputs: dac_cnt
     adc_cntr : process(clk)
     begin
	  if (rising_edge(clk)) then
	       if (adc_cntr_en = '1') then
		    if (adc_cntr_load = '1') then
			 adc_cnt <= adc_cntr_d;
		    else
			 adc_cnt <= std_logic_vector(to_unsigned(to_integer(unsigned(adc_cnt)) - 1, ADC_CNTR_SIZE));
		    end if;
	       end if;
	  end if;
     end process adc_cntr;

     -- This process takes care of following signals:
     -- * ADC_CONV
     -- * SPI_SCK [adc_spi_sck] (when ADC on)
     -- * adc_cntr_load, adc_cntr_en, adc_cntr_d
     -- * adc_shift_reg_we
     -- * adc_ended
     adc_signal : process(adc_st, adc_cnt)
     begin
	  case adc_st is
	       when ADC_ST_IDLE =>
		    -- External
		    adc_conv <= '0';
		    adc_spi_sck <= '0';
		    -- Internal
		    adc_ended <= '0';
		    adc_shift_reg_we <= '0';
		    adc_cntr_en <= '0';
		    adc_cntr_load <= '-';
                    adc_cntr_d <= (others => '0');  -- Should be -
	       when ADC_ST_WAKE_UP =>
		    -- * External *
		    adc_conv <= '1';
		    adc_spi_sck <= '0';
		    -- * Internal *
		    adc_ended <= '0';
		    adc_shift_reg_we <= '0';
		    -- Load preamble size in counter
		    adc_cntr_en <= '1';
		    adc_cntr_load <= '1';
		    adc_cntr_d <= std_logic_vector(to_unsigned(ADC_PREAMBLE_SIZE - 1, ADC_CNTR_SIZE));
	       when ADC_ST_PREAMBLE_0 =>
		    -- *External *
		    adc_conv <= '0';
		    adc_spi_sck <= '1';
		    -- * Internal *
		    adc_ended <= '0';
		    adc_shift_reg_we <= '0';
		    adc_cntr_en <= '0';
		    adc_cntr_load <= '-';
                    adc_cntr_d <= (others => '0');  -- Should be -
	       when ADC_ST_PREAMBLE_1 =>
		    -- * External *
		    adc_conv <= '0';
		    adc_spi_sck <= '0';
		    -- * Internal *
		    adc_ended <= '0';
		    adc_shift_reg_we <= '0';
		    if (to_integer(unsigned(adc_cnt)) = 0) then
					-- Load data size in counter
			 adc_cntr_en <= '1';
			 adc_cntr_load <= '1';
			 adc_cntr_d <= std_logic_vector(to_unsigned(ADC_VAL_SIZE - 1, ADC_CNTR_SIZE));
		    else
			 adc_cntr_en <= '1';
			 adc_cntr_load <= '0';
                         adc_cntr_d <= (others => '0');  -- Should be -                            
		    end if;
	       when ADC_ST_DATA_0 =>
		    -- External
		    adc_conv <= '0';
		    adc_spi_sck <= '1';
		    -- Internal
		    adc_ended <= '0';
		    adc_shift_reg_we <= '1';
		    adc_cntr_en <= '0';
		    adc_cntr_load <= '-';
                    adc_cntr_d <= (others => '0');  -- Should be -
	       when ADC_ST_DATA_1 =>
		    -- External
		    adc_conv <= '0';
		    adc_spi_sck <= '0';
		    -- Internal
		    adc_ended <= '0';
		    adc_shift_reg_we <= '0';
		    if (to_integer(unsigned(adc_cnt)) = 0) then
                         -- Load again val size in counter, for reading second
                         -- word; this time we'll be reading garbage
			 adc_cntr_en <= '1';
			 adc_cntr_load <= '1';
                         -- We add 2 cycles because the ADC turns into Z state
                         -- for 2 cycles each time a 14 bit transmission is finished
			 adc_cntr_d <= std_logic_vector(to_unsigned(ADC_VAL_SIZE + 2 - 1, ADC_CNTR_SIZE));
		    else
			 adc_cntr_en <= '1';
			 adc_cntr_load <= '0';
                         adc_cntr_d <= (others => '0');  -- Should be -
		    end if;
	       when ADC_ST_GARBAGE_0 =>
		    -- External
		    adc_conv <= '0';
		    adc_spi_sck <= '1';
		    -- Internal
		    adc_ended <= '0';
		    adc_shift_reg_we <= '0';
		    adc_cntr_en <= '0';
		    adc_cntr_load <= '-';
                    adc_cntr_d <= (others => '0');  -- Should be -
	       when ADC_ST_GARBAGE_1 =>
		    -- External
		    adc_conv <= '0';
		    adc_spi_sck <= '0';
		    -- Internal
		    adc_ended <= '0';
		    adc_shift_reg_we <= '0';
		    if (to_integer(unsigned(adc_cnt)) = 0) then
					-- Load postdata size in counter
			 adc_cntr_en <= '1';
			 adc_cntr_load <= '1';
			 adc_cntr_d <= std_logic_vector(to_unsigned(ADC_POSTDATA_SIZE - 1, ADC_CNTR_SIZE));
		    else
			 adc_cntr_en <= '1';
			 adc_cntr_load <= '0';
                         adc_cntr_d <= (others => '0');  -- Should be -
		    end if;
	       when ADC_ST_POSTDATA_0 =>
		    -- External
		    adc_conv <= '0';
		    adc_spi_sck <= '1';
		    -- Internal
		    adc_ended <= '0';
		    adc_shift_reg_we <= '0';
		    adc_cntr_en <= '0';
		    adc_cntr_load <= '-';
                    adc_cntr_d <= (others => '0');  -- Should be -
	       when ADC_ST_POSTDATA_1 =>
		    -- External
		    adc_conv <= '0';
		    adc_spi_sck <= '0';
		    -- Internal
		    if (to_integer(unsigned(adc_cnt)) = 0) then
			 adc_ended <= '1';
		    else
			 adc_ended <= '0';
		    end if;
		    adc_shift_reg_we <= '0';
		    adc_cntr_en <= '1';
		    adc_cntr_load <= '0';
                    adc_cntr_d <= (others => '0');  -- Should be -
	       when others =>
		    -- External
		    adc_conv <= '-';
		    adc_spi_sck <= '-';
		    -- Internal
                    adc_ended <= '-';
		    adc_shift_reg_we <= '-';
		    adc_cntr_en <= '-';
		    adc_cntr_load <= '-';
                    adc_cntr_d <= (others => '0');  -- Should be -
                    report "Unknown DAC state!!! Should not happen!!!"
			 severity error;
	  end case;
     end process adc_signal;

     have_sample <= '1' when (adc_st = ADC_ST_GARBAGE_0) and (to_integer(unsigned(adc_cnt)) = (ADC_VAL_SIZE + 2 - 1)) else
                   '0';
     need_sample <= dac_shift_reg_load and dac_shift_reg_we;

     -- As stated in the comments at the begining of the file, Hi-Z must be
     -- implemented OUT of this entity, using spi_owned_out signal
     spi_mosi <= dac_spi_mosi;

     -- Maybe dac_spi_sck and adc_spi_sck signals should be merged, and both adc and dac signal generation
     -- processes should use the same spi_sck signal. Some infimal
     -- combinatorial logic is probably being wasted
     -- Again, as in the dac_spi_mosi case, NO Hi-Z is gen here. Use
     -- spi_owned_out signal.
     spi_sck <= (dac_spi_sck and run_dac) or (adc_spi_sck and run_adc);

     -- Turn off ANY other component in the SPI bus
     isf_ce0 <= '1';
     xpf_init_b <= '1';
     stsf_b <= '1';
     amp_ncs <= '1';
     dac_clr <= '1';                    -- Disable DAC clr

end beh;
