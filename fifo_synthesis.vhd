--------------------------------------------------------------------------------
-- Copyright (c) 1995-2005 Xilinx, Inc.  All rights reserved.
--------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor: Xilinx
-- \   \   \/     Version: H.38
--  \   \         Application: netgen
--  /   /         Filename: fifo_synthesis.vhd
-- /___/   /\     Timestamp: Fri May 05 03:57:13 2006
-- \   \  /  \ 
--  \___\/\___\
--             
-- Command: -intstyle ise -ar Structure -w -ofmt vhdl -sim fifo.ngc fifo_synthesis.vhd 
-- Device: xc3s200-5-pq208
-- Design Name: fifo
--             
-- Purpose:    
--     This VHDL netlist is a verification model and uses simulation 
--     primitives which may not represent the true implementation of the 
--     device, however the netlist is functionally correct and should not 
--     be modified. This file cannot be synthesized and should only be used 
--     with supported simulation tools.
--             
-- Reference:  
--     Development System Reference Guide, Chapter 23
--     Synthesis and Verification Design Guide, Chapter 6
--             
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity fifo is
  port (
    clk : in STD_LOGIC := 'X'; 
    i : in STD_LOGIC_VECTOR ( 15 downto 0 ); 
    o : out STD_LOGIC_VECTOR ( 15 downto 0 ) 
  );
end fifo;

architecture Structure of fifo is
  signal clk_BUFGP : STD_LOGIC; 
  signal Q_n0002 : STD_LOGIC; 
  signal N0 : STD_LOGIC; 
  signal i_2_IBUF : STD_LOGIC; 
  signal i_1_IBUF : STD_LOGIC; 
  signal i_0_IBUF : STD_LOGIC; 
  signal o_15_OBUF : STD_LOGIC; 
  signal o_14_OBUF : STD_LOGIC; 
  signal o_13_OBUF : STD_LOGIC; 
  signal o_12_OBUF : STD_LOGIC; 
  signal o_11_OBUF : STD_LOGIC; 
  signal o_10_OBUF : STD_LOGIC; 
  signal o_9_OBUF : STD_LOGIC; 
  signal o_8_OBUF : STD_LOGIC; 
  signal o_7_OBUF : STD_LOGIC; 
  signal o_6_OBUF : STD_LOGIC; 
  signal o_5_OBUF : STD_LOGIC; 
  signal o_4_OBUF : STD_LOGIC; 
  signal o_3_OBUF : STD_LOGIC; 
  signal o_2_OBUF : STD_LOGIC; 
  signal o_1_OBUF : STD_LOGIC; 
  signal o_0_OBUF : STD_LOGIC; 
  signal i_15_IBUF : STD_LOGIC; 
  signal i_14_IBUF : STD_LOGIC; 
  signal i_13_IBUF : STD_LOGIC; 
  signal i_12_IBUF : STD_LOGIC; 
  signal i_11_IBUF : STD_LOGIC; 
  signal i_10_IBUF : STD_LOGIC; 
  signal i_9_IBUF : STD_LOGIC; 
  signal i_8_IBUF : STD_LOGIC; 
  signal i_7_IBUF : STD_LOGIC; 
  signal i_6_IBUF : STD_LOGIC; 
  signal i_5_IBUF : STD_LOGIC; 
  signal i_4_IBUF : STD_LOGIC; 
  signal i_3_IBUF : STD_LOGIC; 
  signal N1 : STD_LOGIC; 
  signal fifo_ptr_n0000_7_cyo : STD_LOGIC; 
  signal N3 : STD_LOGIC; 
  signal fifo_ptr_n0000_0_cyo : STD_LOGIC; 
  signal fifo_ptr_n0000_1_cyo : STD_LOGIC; 
  signal fifo_ptr_n0000_2_cyo : STD_LOGIC; 
  signal fifo_ptr_n0000_3_cyo : STD_LOGIC; 
  signal fifo_ptr_n0000_4_cyo : STD_LOGIC; 
  signal fifo_ptr_n0000_5_cyo : STD_LOGIC; 
  signal fifo_ptr_n0000_6_cyo : STD_LOGIC; 
  signal CHOICE30 : STD_LOGIC; 
  signal CHOICE26 : STD_LOGIC; 
  signal ptr_8_rt : STD_LOGIC; 
  signal ptr_1_rt : STD_LOGIC; 
  signal ptr_2_rt : STD_LOGIC; 
  signal ptr_3_rt : STD_LOGIC; 
  signal ptr_4_rt : STD_LOGIC; 
  signal ptr_5_rt : STD_LOGIC; 
  signal ptr_6_rt : STD_LOGIC; 
  signal ptr_7_rt : STD_LOGIC; 
  signal NLW_Mram_ram_inst_ramb_0_DO_31_UNCONNECTED : STD_LOGIC; 
  signal NLW_Mram_ram_inst_ramb_0_DO_30_UNCONNECTED : STD_LOGIC; 
  signal NLW_Mram_ram_inst_ramb_0_DO_29_UNCONNECTED : STD_LOGIC; 
  signal NLW_Mram_ram_inst_ramb_0_DO_28_UNCONNECTED : STD_LOGIC; 
  signal NLW_Mram_ram_inst_ramb_0_DO_27_UNCONNECTED : STD_LOGIC; 
  signal NLW_Mram_ram_inst_ramb_0_DO_26_UNCONNECTED : STD_LOGIC; 
  signal NLW_Mram_ram_inst_ramb_0_DO_25_UNCONNECTED : STD_LOGIC; 
  signal NLW_Mram_ram_inst_ramb_0_DO_24_UNCONNECTED : STD_LOGIC; 
  signal NLW_Mram_ram_inst_ramb_0_DO_23_UNCONNECTED : STD_LOGIC; 
  signal NLW_Mram_ram_inst_ramb_0_DO_22_UNCONNECTED : STD_LOGIC; 
  signal NLW_Mram_ram_inst_ramb_0_DO_21_UNCONNECTED : STD_LOGIC; 
  signal NLW_Mram_ram_inst_ramb_0_DO_20_UNCONNECTED : STD_LOGIC; 
  signal NLW_Mram_ram_inst_ramb_0_DO_19_UNCONNECTED : STD_LOGIC; 
  signal NLW_Mram_ram_inst_ramb_0_DO_18_UNCONNECTED : STD_LOGIC; 
  signal NLW_Mram_ram_inst_ramb_0_DO_17_UNCONNECTED : STD_LOGIC; 
  signal NLW_Mram_ram_inst_ramb_0_DO_16_UNCONNECTED : STD_LOGIC; 
  signal NLW_Mram_ram_inst_ramb_0_DOP_3_UNCONNECTED : STD_LOGIC; 
  signal NLW_Mram_ram_inst_ramb_0_DOP_2_UNCONNECTED : STD_LOGIC; 
  signal NLW_Mram_ram_inst_ramb_0_DOP_1_UNCONNECTED : STD_LOGIC; 
  signal NLW_Mram_ram_inst_ramb_0_DOP_0_UNCONNECTED : STD_LOGIC; 
  signal ptr : STD_LOGIC_VECTOR ( 8 downto 0 ); 
  signal ptr_n0000 : STD_LOGIC_VECTOR ( 8 downto 1 ); 
begin
  XST_VCC : VCC
    port map (
      P => N0
    );
  Q_n00028 : LUT4
    generic map(
      INIT => X"1000"
    )
    port map (
      I0 => ptr(4),
      I1 => ptr(5),
      I2 => ptr(8),
      I3 => ptr(0),
      O => CHOICE26
    );
  ptr_7 : FDR
    port map (
      D => ptr_n0000(7),
      R => Q_n0002,
      C => clk_BUFGP,
      Q => ptr(7)
    );
  Mram_ram_inst_ramb_0 : RAMB16_S36
    generic map(
      INIT_00 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_01 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_03 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_07 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_08 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_09 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_0A => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_0B => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_0C => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_0D => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_0E => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_0F => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_10 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_11 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_12 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_13 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_14 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_15 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_16 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_17 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_18 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_19 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_1A => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_1B => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_1C => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_1D => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_1E => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_1F => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_20 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_21 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_22 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_23 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_24 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_25 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_26 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_27 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_28 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_29 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_2A => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_2B => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_2C => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_2D => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_2E => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_2F => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_30 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_31 => X"0000000000000000000000000000000000000000000000000000000000000000",
      WRITE_MODE => "READ_FIRST"
    )
    port map (
      CLK => clk_BUFGP,
      EN => N0,
      SSR => N1,
      WE => N0,
      ADDR(8) => ptr(8),
      ADDR(7) => ptr(7),
      ADDR(6) => ptr(6),
      ADDR(5) => ptr(5),
      ADDR(4) => ptr(4),
      ADDR(3) => ptr(3),
      ADDR(2) => ptr(2),
      ADDR(1) => ptr(1),
      ADDR(0) => ptr(0),
      DI(31) => N1,
      DI(30) => N1,
      DI(29) => N1,
      DI(28) => N1,
      DI(27) => N1,
      DI(26) => N1,
      DI(25) => N1,
      DI(24) => N1,
      DI(23) => N1,
      DI(22) => N1,
      DI(21) => N1,
      DI(20) => N1,
      DI(19) => N1,
      DI(18) => N1,
      DI(17) => N1,
      DI(16) => N1,
      DI(15) => i_15_IBUF,
      DI(14) => i_14_IBUF,
      DI(13) => i_13_IBUF,
      DI(12) => i_12_IBUF,
      DI(11) => i_11_IBUF,
      DI(10) => i_10_IBUF,
      DI(9) => i_9_IBUF,
      DI(8) => i_8_IBUF,
      DI(7) => i_7_IBUF,
      DI(6) => i_6_IBUF,
      DI(5) => i_5_IBUF,
      DI(4) => i_4_IBUF,
      DI(3) => i_3_IBUF,
      DI(2) => i_2_IBUF,
      DI(1) => i_1_IBUF,
      DI(0) => i_0_IBUF,
      DIP(3) => N1,
      DIP(2) => N1,
      DIP(1) => N1,
      DIP(0) => N1,
      DO(31) => NLW_Mram_ram_inst_ramb_0_DO_31_UNCONNECTED,
      DO(30) => NLW_Mram_ram_inst_ramb_0_DO_30_UNCONNECTED,
      DO(29) => NLW_Mram_ram_inst_ramb_0_DO_29_UNCONNECTED,
      DO(28) => NLW_Mram_ram_inst_ramb_0_DO_28_UNCONNECTED,
      DO(27) => NLW_Mram_ram_inst_ramb_0_DO_27_UNCONNECTED,
      DO(26) => NLW_Mram_ram_inst_ramb_0_DO_26_UNCONNECTED,
      DO(25) => NLW_Mram_ram_inst_ramb_0_DO_25_UNCONNECTED,
      DO(24) => NLW_Mram_ram_inst_ramb_0_DO_24_UNCONNECTED,
      DO(23) => NLW_Mram_ram_inst_ramb_0_DO_23_UNCONNECTED,
      DO(22) => NLW_Mram_ram_inst_ramb_0_DO_22_UNCONNECTED,
      DO(21) => NLW_Mram_ram_inst_ramb_0_DO_21_UNCONNECTED,
      DO(20) => NLW_Mram_ram_inst_ramb_0_DO_20_UNCONNECTED,
      DO(19) => NLW_Mram_ram_inst_ramb_0_DO_19_UNCONNECTED,
      DO(18) => NLW_Mram_ram_inst_ramb_0_DO_18_UNCONNECTED,
      DO(17) => NLW_Mram_ram_inst_ramb_0_DO_17_UNCONNECTED,
      DO(16) => NLW_Mram_ram_inst_ramb_0_DO_16_UNCONNECTED,
      DO(15) => o_15_OBUF,
      DO(14) => o_14_OBUF,
      DO(13) => o_13_OBUF,
      DO(12) => o_12_OBUF,
      DO(11) => o_11_OBUF,
      DO(10) => o_10_OBUF,
      DO(9) => o_9_OBUF,
      DO(8) => o_8_OBUF,
      DO(7) => o_7_OBUF,
      DO(6) => o_6_OBUF,
      DO(5) => o_5_OBUF,
      DO(4) => o_4_OBUF,
      DO(3) => o_3_OBUF,
      DO(2) => o_2_OBUF,
      DO(1) => o_1_OBUF,
      DO(0) => o_0_OBUF,
      DOP(3) => NLW_Mram_ram_inst_ramb_0_DOP_3_UNCONNECTED,
      DOP(2) => NLW_Mram_ram_inst_ramb_0_DOP_2_UNCONNECTED,
      DOP(1) => NLW_Mram_ram_inst_ramb_0_DOP_1_UNCONNECTED,
      DOP(0) => NLW_Mram_ram_inst_ramb_0_DOP_0_UNCONNECTED
    );
  ptr_8 : FDR
    port map (
      D => ptr_n0000(8),
      R => Q_n0002,
      C => clk_BUFGP,
      Q => ptr(8)
    );
  fifo_ptr_n0000_8_xor : XORCY
    port map (
      CI => fifo_ptr_n0000_7_cyo,
      LI => ptr_8_rt,
      O => ptr_n0000(8)
    );
  ptr_0 : FDR
    port map (
      D => N3,
      R => Q_n0002,
      C => clk_BUFGP,
      Q => ptr(0)
    );
  ptr_1 : FDR
    port map (
      D => ptr_n0000(1),
      R => Q_n0002,
      C => clk_BUFGP,
      Q => ptr(1)
    );
  ptr_2 : FDR
    port map (
      D => ptr_n0000(2),
      R => Q_n0002,
      C => clk_BUFGP,
      Q => ptr(2)
    );
  ptr_3 : FDR
    port map (
      D => ptr_n0000(3),
      R => Q_n0002,
      C => clk_BUFGP,
      Q => ptr(3)
    );
  ptr_4 : FDR
    port map (
      D => ptr_n0000(4),
      R => Q_n0002,
      C => clk_BUFGP,
      Q => ptr(4)
    );
  ptr_5 : FDR
    port map (
      D => ptr_n0000(5),
      R => Q_n0002,
      C => clk_BUFGP,
      Q => ptr(5)
    );
  ptr_6 : FDR
    port map (
      D => ptr_n0000(6),
      R => Q_n0002,
      C => clk_BUFGP,
      Q => ptr(6)
    );
  XST_GND : GND
    port map (
      G => N1
    );
  fifo_ptr_n0000_0_lut_INV_0 : INV
    port map (
      I => ptr(0),
      O => N3
    );
  fifo_ptr_n0000_0_cy : MUXCY
    port map (
      CI => N1,
      DI => N0,
      S => N3,
      O => fifo_ptr_n0000_0_cyo
    );
  o_0_OBUF_0 : OBUF
    port map (
      I => o_0_OBUF,
      O => o(0)
    );
  fifo_ptr_n0000_1_cy : MUXCY
    port map (
      CI => fifo_ptr_n0000_0_cyo,
      DI => N1,
      S => ptr_1_rt,
      O => fifo_ptr_n0000_1_cyo
    );
  fifo_ptr_n0000_1_xor : XORCY
    port map (
      CI => fifo_ptr_n0000_0_cyo,
      LI => ptr_1_rt,
      O => ptr_n0000(1)
    );
  fifo_ptr_n0000_2_cy : MUXCY
    port map (
      CI => fifo_ptr_n0000_1_cyo,
      DI => N1,
      S => ptr_2_rt,
      O => fifo_ptr_n0000_2_cyo
    );
  fifo_ptr_n0000_2_xor : XORCY
    port map (
      CI => fifo_ptr_n0000_1_cyo,
      LI => ptr_2_rt,
      O => ptr_n0000(2)
    );
  fifo_ptr_n0000_3_cy : MUXCY
    port map (
      CI => fifo_ptr_n0000_2_cyo,
      DI => N1,
      S => ptr_3_rt,
      O => fifo_ptr_n0000_3_cyo
    );
  fifo_ptr_n0000_3_xor : XORCY
    port map (
      CI => fifo_ptr_n0000_2_cyo,
      LI => ptr_3_rt,
      O => ptr_n0000(3)
    );
  fifo_ptr_n0000_4_cy : MUXCY
    port map (
      CI => fifo_ptr_n0000_3_cyo,
      DI => N1,
      S => ptr_4_rt,
      O => fifo_ptr_n0000_4_cyo
    );
  fifo_ptr_n0000_4_xor : XORCY
    port map (
      CI => fifo_ptr_n0000_3_cyo,
      LI => ptr_4_rt,
      O => ptr_n0000(4)
    );
  fifo_ptr_n0000_5_cy : MUXCY
    port map (
      CI => fifo_ptr_n0000_4_cyo,
      DI => N1,
      S => ptr_5_rt,
      O => fifo_ptr_n0000_5_cyo
    );
  fifo_ptr_n0000_5_xor : XORCY
    port map (
      CI => fifo_ptr_n0000_4_cyo,
      LI => ptr_5_rt,
      O => ptr_n0000(5)
    );
  fifo_ptr_n0000_6_cy : MUXCY
    port map (
      CI => fifo_ptr_n0000_5_cyo,
      DI => N1,
      S => ptr_6_rt,
      O => fifo_ptr_n0000_6_cyo
    );
  fifo_ptr_n0000_6_xor : XORCY
    port map (
      CI => fifo_ptr_n0000_5_cyo,
      LI => ptr_6_rt,
      O => ptr_n0000(6)
    );
  fifo_ptr_n0000_7_cy : MUXCY
    port map (
      CI => fifo_ptr_n0000_6_cyo,
      DI => N1,
      S => ptr_7_rt,
      O => fifo_ptr_n0000_7_cyo
    );
  fifo_ptr_n0000_7_xor : XORCY
    port map (
      CI => fifo_ptr_n0000_6_cyo,
      LI => ptr_7_rt,
      O => ptr_n0000(7)
    );
  ptr_8_rt_1 : LUT1
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => ptr(8),
      O => ptr_8_rt
    );
  ptr_7_rt_2 : LUT1_L
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => ptr(7),
      LO => ptr_7_rt
    );
  Q_n000214 : LUT3_L
    generic map(
      INIT => X"40"
    )
    port map (
      I0 => ptr(6),
      I1 => ptr(2),
      I2 => ptr(3),
      LO => CHOICE30
    );
  clk_BUFGP_3 : BUFGP
    port map (
      I => clk,
      O => clk_BUFGP
    );
  i_15_IBUF_4 : IBUF
    port map (
      I => i(15),
      O => i_15_IBUF
    );
  i_14_IBUF_5 : IBUF
    port map (
      I => i(14),
      O => i_14_IBUF
    );
  i_13_IBUF_6 : IBUF
    port map (
      I => i(13),
      O => i_13_IBUF
    );
  i_12_IBUF_7 : IBUF
    port map (
      I => i(12),
      O => i_12_IBUF
    );
  i_11_IBUF_8 : IBUF
    port map (
      I => i(11),
      O => i_11_IBUF
    );
  i_10_IBUF_9 : IBUF
    port map (
      I => i(10),
      O => i_10_IBUF
    );
  i_9_IBUF_10 : IBUF
    port map (
      I => i(9),
      O => i_9_IBUF
    );
  i_8_IBUF_11 : IBUF
    port map (
      I => i(8),
      O => i_8_IBUF
    );
  i_7_IBUF_12 : IBUF
    port map (
      I => i(7),
      O => i_7_IBUF
    );
  i_6_IBUF_13 : IBUF
    port map (
      I => i(6),
      O => i_6_IBUF
    );
  i_5_IBUF_14 : IBUF
    port map (
      I => i(5),
      O => i_5_IBUF
    );
  i_4_IBUF_15 : IBUF
    port map (
      I => i(4),
      O => i_4_IBUF
    );
  i_3_IBUF_16 : IBUF
    port map (
      I => i(3),
      O => i_3_IBUF
    );
  i_2_IBUF_17 : IBUF
    port map (
      I => i(2),
      O => i_2_IBUF
    );
  i_1_IBUF_18 : IBUF
    port map (
      I => i(1),
      O => i_1_IBUF
    );
  i_0_IBUF_19 : IBUF
    port map (
      I => i(0),
      O => i_0_IBUF
    );
  o_15_OBUF_20 : OBUF
    port map (
      I => o_15_OBUF,
      O => o(15)
    );
  o_14_OBUF_21 : OBUF
    port map (
      I => o_14_OBUF,
      O => o(14)
    );
  o_13_OBUF_22 : OBUF
    port map (
      I => o_13_OBUF,
      O => o(13)
    );
  o_12_OBUF_23 : OBUF
    port map (
      I => o_12_OBUF,
      O => o(12)
    );
  o_11_OBUF_24 : OBUF
    port map (
      I => o_11_OBUF,
      O => o(11)
    );
  o_10_OBUF_25 : OBUF
    port map (
      I => o_10_OBUF,
      O => o(10)
    );
  o_9_OBUF_26 : OBUF
    port map (
      I => o_9_OBUF,
      O => o(9)
    );
  o_8_OBUF_27 : OBUF
    port map (
      I => o_8_OBUF,
      O => o(8)
    );
  o_7_OBUF_28 : OBUF
    port map (
      I => o_7_OBUF,
      O => o(7)
    );
  o_6_OBUF_29 : OBUF
    port map (
      I => o_6_OBUF,
      O => o(6)
    );
  o_5_OBUF_30 : OBUF
    port map (
      I => o_5_OBUF,
      O => o(5)
    );
  o_4_OBUF_31 : OBUF
    port map (
      I => o_4_OBUF,
      O => o(4)
    );
  o_3_OBUF_32 : OBUF
    port map (
      I => o_3_OBUF,
      O => o(3)
    );
  o_2_OBUF_33 : OBUF
    port map (
      I => o_2_OBUF,
      O => o(2)
    );
  o_1_OBUF_34 : OBUF
    port map (
      I => o_1_OBUF,
      O => o(1)
    );
  ptr_1_rt_35 : LUT1_L
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => ptr(1),
      LO => ptr_1_rt
    );
  ptr_2_rt_36 : LUT1_L
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => ptr(2),
      LO => ptr_2_rt
    );
  ptr_3_rt_37 : LUT1_L
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => ptr(3),
      LO => ptr_3_rt
    );
  ptr_4_rt_38 : LUT1_L
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => ptr(4),
      LO => ptr_4_rt
    );
  ptr_5_rt_39 : LUT1_L
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => ptr(5),
      LO => ptr_5_rt
    );
  ptr_6_rt_40 : LUT1_L
    generic map(
      INIT => X"2"
    )
    port map (
      I0 => ptr(6),
      LO => ptr_6_rt
    );
  Q_n000221 : LUT4
    generic map(
      INIT => X"8000"
    )
    port map (
      I0 => ptr(7),
      I1 => ptr(1),
      I2 => CHOICE30,
      I3 => CHOICE26,
      O => Q_n0002
    );

end Structure;

