--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    
-- Design Name:    
-- Module Name:    d_shift_reg - alg
-- Project Name:   
-- Target Device:  
-- Tool versions:  
-- Description:
-- | SAME as SHIFT_REG!!!! But with HARDCODED DOUBLE SHIFT as ISE 7.1i
-- | is NOT ABLE TO COMPILE IT properly inside the sqrt algorithm imple-
-- | mentation!!!! ModelSim has no problem compiling it!!!! (this demons-
-- | trates quality of Xilinx HDL compiler ... )
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

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity d_shift_reg is
	generic (
		width : natural := PIPELINE_WIDTH;
		dir : shift_dir_t := SD_LEFT
	);
	port (
		clk, load, we : in std_logic;
		s_in : in std_logic_vector(2 - 1 downto 0);
		p_in : in std_logic_vector(width - 1 downto 0);
		o : out std_logic_vector(width - 1 downto 0)
	);
end d_shift_reg;

architecture alg of d_shift_reg is
begin
	process(clk)
		constant step_s : natural := 2;
		variable val : std_logic_vector(width - 1 downto 0);
	begin
		if (rising_edge(clk)) then
			if (we = '1') then
				if (load = '1') then
					val := p_in;
				else
					if (dir = SD_LEFT) then
						val(width - 1 downto step_s) := val(width - step_s - 1 downto 0);
						val(step_s - 1 downto 0) := B"00";
					else
						val(width - step_s - 1 downto 0) := val(width - 1 downto step_s);
						val(width - 1 downto width - step_s - 1) := B"00";
					end if;
				end if;
			end if;
		end if;
		o <= val;
	end process;
end alg;