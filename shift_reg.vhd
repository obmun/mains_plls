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
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use WORK.COMMON.all;

--! @brief Shift register
--!
--! @par Ports and generics
--!
--! Generics:
--!   * dir: the shift direction. SD_LEFT means to do a shift left (MSB is out, MSB - 1 is put on MSB).
--!          SD_RIGHT is the contrary
--!
--! Ports:
--!   * Input:
--!     * clk: clock input
--!     * load: sync parallel load. If '1' on rising edge loads register with p_in
--!     * we: if '1', register modifies its state (either by parallel load or shift
--!           and serial input). Otherwise internal state is not modified (but 
--!           value is always outputted).
--!     * p_in: parallel load in value
--!     * s_in: serial in value (size depends on step generic)
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
