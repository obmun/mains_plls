--------------------------------------------------------------------------------
-- *** Brief description ***
--
-- Xilinx Spartan 3E and Digilent development board specific config and code
--
-- SOME OF THE CODE, specifically the DCM one, has been generated with Xilinx Architecture Wizard
-- tool, part of the ISE suite
--
-- *** Description ***
--
-- Takes care of configuring Xilinx specific clock management (DCM) inside the FPGA.
-- Conditions:
-- 1) Input clock 50 MHz (uses default Digilent board internal clock)
-- 2) Usa un divisor de reloj de 8, para generar un reloj interno de baja velocidad de 6.25 MHz (ver
-- puerto CLKDV_OUT)
--
-- ** Port description **
--
-- CLKDV_OUT: Main clock / 8 -> 6.25 MHz clock
-- CLKIN_IBUFG_OUT: raw input clock, buffered
-- CLK0_OUT: main clock output -> 50 MHz clock
-- CLKFX_OUT: processed (fx) clock output, that is, main clock / 5 -> 10 MHz clock
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- synopsys translate_off
library UNISIM;
use UNISIM.Vcomponents.ALL;
-- synopsys translate_on

entity platform is
     port (
          CLKIN_IN : in std_logic; -- Input clock
          RST_IN : in std_logic; -- Input RST
          CLKDV_OUT : out std_logic;
          CLKIN_IBUFG_OUT : out std_logic;
          CLK0_OUT : out std_logic;
          CLKFX_OUT : out std_logic;
          LOCKED_OUT : out std_logic);
end platform;

architecture beh of platform is
	signal CLKDV_BUF : std_logic;
	signal CLKFB_IN : std_logic;
	signal CLKIN_IBUFG : std_logic;
	signal CLK0_BUF : std_logic;
        signal CLKFX_BUF : std_logic;
	signal GND : std_logic;

	component BUFG
		port (
			I : in std_logic;
			O : out std_logic);
	end component;

	component IBUFG
		port (
			I : in std_logic;
			O : out std_logic);
	end component;

	-- Period Jitter (Peak-to-Peak) for block DCM_INST = 6.54 ns
	component DCM
		generic (
			CLK_FEEDBACK : string := "1X";
			CLKDV_DIVIDE : real := 2.000000;
			CLKFX_DIVIDE : integer := 1;
			CLKFX_MULTIPLY : integer := 4;
			CLKIN_DIVIDE_BY_2 : boolean :=  FALSE;
			CLKIN_PERIOD : real := 0.000000;
			CLKOUT_PHASE_SHIFT : string := "NONE";
			DESKEW_ADJUST : string := "SYSTEM_SYNCHRONOUS";
			DFS_FREQUENCY_MODE : string := "LOW";
			DLL_FREQUENCY_MODE : string := "LOW";
			DUTY_CYCLE_CORRECTION : boolean := TRUE;
			FACTORY_JF : bit_vector := x"C080";
			PHASE_SHIFT : integer := 0;
			STARTUP_WAIT : boolean := FALSE;
			DSS_MODE : string := "NONE"
		);
		port (
			CLKIN    : in    std_logic; 
			CLKFB    : in    std_logic; 
			RST      : in    std_logic; 
			PSEN     : in    std_logic; 
			PSINCDEC : in    std_logic; 
			PSCLK    : in    std_logic; 
			DSSEN    : in    std_logic; 
			CLK0     : out   std_logic; 
			CLK90    : out   std_logic; 
			CLK180   : out   std_logic; 
			CLK270   : out   std_logic; 
			CLKDV    : out   std_logic; 
			CLK2X    : out   std_logic; 
			CLK2X180 : out   std_logic; 
			CLKFX    : out   std_logic; 
			CLKFX180 : out   std_logic; 
			STATUS   : out   std_logic_vector (7 downto 0); 
			LOCKED   : out   std_logic; 
			PSDONE   : out   std_logic
		);
   end component;
begin
	GND <= '0';
	CLKIN_IBUFG_OUT <= CLKIN_IBUFG;
	CLK0_OUT <= CLKFB_IN;

	CLKDV_BUFG_INST : BUFG
		port map (
			I => CLKDV_BUF,
			O => CLKDV_OUT
		);

	CLKIN_IBUFG_INST : IBUFG
		port map (
			I => CLKIN_IN,
			O => CLKIN_IBUFG
		);

	-- Buffer for MAIN clock
	CLK0_BUFG_INST : BUFG
		port map (
			I => CLK0_BUF,
			O => CLKFB_IN
		);
        
        CLKFX_BUFG_INST : BUFG
		port map (
			I => CLKFX_BUF,
			O => CLKFX_OUT
		);

	DCM_INST : DCM
		generic map (
			CLK_FEEDBACK => "1X",
			CLKDV_DIVIDE => 8.000000,
			CLKFX_DIVIDE => 10,
			CLKFX_MULTIPLY => 2,
			CLKIN_DIVIDE_BY_2 => FALSE,
			CLKIN_PERIOD => 20.000000,  -- 20 ns => 50 MHz
			CLKOUT_PHASE_SHIFT => "NONE",
			DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS",
			DFS_FREQUENCY_MODE => "LOW",
			DLL_FREQUENCY_MODE => "LOW",
			DUTY_CYCLE_CORRECTION => TRUE,
			FACTORY_JF => x"C080",
			PHASE_SHIFT => 0,
			STARTUP_WAIT => FALSE
		)
		port map (
			CLKFB => CLKFB_IN,
			CLKIN => CLKIN_IBUFG, -- Input clock for the DCM
			DSSEN => GND,
			PSCLK => GND,
			PSEN => GND,
			PSINCDEC => GND,
			RST => RST_IN,
			CLKDV => CLKDV_BUF,
			CLKFX => CLKFX_BUF, -- DCM synth is not used
			CLKFX180 => open, -- ^^^^
			CLK0 => CLK0_BUF, -- MAIN clock output, 0 phase
			CLK2X => open,
			CLK2X180 => open,
			CLK90 => open, -- Phased clocks not used
			CLK180 => open, -- ^^^^
			CLK270 => open, -- ^^^^
			LOCKED => LOCKED_OUT,
			PSDONE => open,
			STATUS => open
		);
end beh;
