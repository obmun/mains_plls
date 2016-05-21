-- Copyright (c) 2012-2016 Jacobo Cabaleiro Cayetano
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

library IEEE;
library WORK;
use WORK.COMMON.all;
-- use IEEE.MATH_REAL.ALL;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;


entity fifo is
	generic (
		width : natural := PIPELINE_WIDTH;
		size : natural := 400
	);
	port (
		clk, we, rst : in std_logic;
		i : in std_logic_vector (width - 1 downto 0);
		o : out std_logic_vector (width - 1 downto 0)
	);
end fifo;


--! @brief FIFO based on memory blocks.
--!
--! While you waiting for writing x[n] on next clk rising edge, you're reading x[n - size].
--!
--! *** Description ***
--!
--! This FIFO has no facility for FULL RESET of internal storage. You must implement it yourself BY HAND
--!
--! ** Ports **
--!
--! rst: sync "partial" reset. Partial in the sense that it DOES NOT CLEAR internal memory positions;
--! it only resets the position pointers
--! resets position poi
architecture alg of fifo is
     type ram_t is array(size - 1 downto 0) of std_logic_vector(width - 1 downto 0);
     subtype mem_addr_t is natural range 0 to size - 1;

     signal w_addr_s, r_addr_s : mem_addr_t;

     signal ram : ram_t := (others => STD_LOGIC_VECTOR(TO_UNSIGNED(0, width)));
begin
     ctrl : process(clk, rst, we)
          variable w_addr, r_addr : mem_addr_t;
     begin
          if (rising_edge(clk)) then
               if rst = '1' then
                    w_addr := size - 1;
                    r_addr := size - 2;
               else
                    if (we = '1') then
                         w_addr := r_addr;
                         if (r_addr = 0) then
                              r_addr := size - 1;
                         else
                              r_addr := r_addr - 1;
                         end if;
                    end if;
               end if;
          end if;
          -- Por ejemplo, esta asignación dentro del if del rising edge provoca la inferencia de un
          -- par de registros más por parte del sintetizador.
          w_addr_s <= w_addr;
          r_addr_s <= r_addr;
     end process;

     
     mem : process(clk, we, i, w_addr_s, r_addr_s)
     begin
          if (rising_edge(clk)) then
               if (we = '1') then
                    ram(w_addr_s) <= i;
               end if;
               o <= ram(r_addr_s);
          end if;
     -- Si coloco la escritura de la salida fuera del control de reloj, sintetiza una RAM distribuida en lugar de una RAM en bloque ...
     -- Explicación: la RAM de bloque es una RAM con salida SÍNCRONA
     end process;
end alg;
