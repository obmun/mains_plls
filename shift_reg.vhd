--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    00:51:26 06/28/06
-- Design Name:    
-- Module Name:    shift_reg - alg
-- Project Name:   
-- Target Device:  
-- Tool versions:  
-- Description:
-- | Ports:
-- | - Input:
-- |   -> clk: clock input
-- |   -> load: sync parallel load. If '1' on rising edge loads register with p_in
-- |...-> we: if '1', register modifies its state (either by parallel load or shift
-- |   ->     and serial input). Otherwise internal state is not modified (but 
-- |   ->     value is always outputted).
-- |   -> p_in: parallel load in value
-- |   -> s_in: serial in value (size depends on step generic)
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
--------------------------------------------------------------------------------
library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use WORK.COMMON.all;

entity shift_reg is
	generic (
		width : natural := PIPELINE_WIDTH;
		dir : shift_dir_t := SD_LEFT;
		step_s : natural := 1
	);
	port (
		clk, load, we : in std_logic;
		s_in : in std_logic_vector(step_s - 1 downto 0);
		p_in : in std_logic_vector(width - 1 downto 0);
		o : out std_logic_vector(width - 1 downto 0)
	);
end shift_reg;

architecture alg of shift_reg is
begin
	process(clk)
		variable val : std_logic_vector(width - 1 downto 0);
	begin
		if (rising_edge(clk)) then
			if (we = '1') then
				if (load = '1') then
					val := p_in;
				else
					if (dir = SD_LEFT) then
						val(width - 1 downto step_s) := val(width - step_s - 1 downto 0);
						val(step_s - 1 downto 0) := s_in;
					else
						val(width - step_s - 1 downto 0) := val(width - 1 downto step_s);
						val(width - 1 downto width - step_s - 1) := s_in;
					end if;
				end if;
			end if;
		end if;
		o <= val;
	end process;
end alg;