--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    02:17:31 05/05/06
-- Design Name:    
-- Module Name:    fifo - alg
-- Project Name:   
-- Target Device:  
-- Tool versions:  
-- Description:
-- | FIFO based on memory blocks
-- Dependencies:
-- 
-- Revision:
-- Revision 0.02 - Revised implementation. Now executes faster (15 MHz :)), compiler doesn't throw warnings and consumes less FPGA resources!!!!
-- Revision 0.01 - First implementation
-- Additional Comments:
-- >> TO DO: intentar comprender exactamente la razón de la síntesis. < DONE
--------------------------------------------------------------------------------
library IEEE;
library WORK;
use WORK.COMMON.all;
use IEEE.MATH_REAL.ALL;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity fifo is
	generic (
		width : natural := PIPELINE_WIDTH;
		size : natural := 400
	);
	port (
		clk, we : in std_logic;
		i : in std_logic_vector (width - 1 downto 0);
		o : out std_logic_vector (width - 1 downto 0)
	);
end fifo;

architecture alg of fifo is
	type ram_t is array(size - 1 downto 0) of std_logic_vector(width - 1 downto 0);
	subtype mem_addr_t is natural range 0 to size - 1;

	signal ram : ram_t := (others => STD_LOGIC_VECTOR(TO_UNSIGNED(0, width)));
begin
	write: process(clk)
		variable w_mem_addr : mem_addr_t := size - 1;
		variable r_mem_addr : mem_addr_t := size - 2;
	begin
		if (rising_edge(clk)) then
			o <= ram(r_mem_addr);
			if (we = '1') then
				ram(w_mem_addr) <= i;
				w_mem_addr := r_mem_addr;
				if (r_mem_addr = 0) then
					r_mem_addr := size - 1;
				else
					r_mem_addr := r_mem_addr -1;
				end if;
			end if;
		end if;
		-- Si coloco la escritura de la salida fuera del control de reloj, sintetiza una RAM distribuida en lugar de una RAM en bloque ...
		-- Explicación: la RAM de bloque es una RAM con salida SÍNCRONA
	end process;
end alg;
