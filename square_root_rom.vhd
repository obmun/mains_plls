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
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--! @brief ROM for initial seed in Newton Raphson square root algorithm.
--!
--! Resulting values must be, of course, shifted so they get the decimal
--! point in the correct bit (given the pipeline fixed point format).
--!
--! USES XILINX SPECIFIC ATTRIBUTE so even being a ROM gets sinthesized
--! as a preinitialized block RAM (in our design we have a lot of them
--! :). For other FPGAs, just delete the attribute line and this should get
--! sinthesized just as well.
entity square_root_rom is
	port (
		clk : in std_logic;
		addr : in std_logic_vector(7 downto 0);
		o : out std_logic_vector(7 downto 0)
	);
	-- Xilinx specific to force BRAM inference
	attribute bram_map : string;
	attribute bram_map of square_root_rom : entity is "yes";
end square_root_rom;

architecture alg of square_root_rom is
	type mem_t is array(0 to 255) of std_logic_vector(7 downto 0);
begin
	process(clk)
		variable mem : mem_t;
	begin
		-- VALUE GENERATION BY MEANS OF COMPUTER SOFTWARE (cut and paste text file)
		mem(000) := X"00";
		mem(001) := X"01";
		mem(002) := X"02";
		mem(003) := X"03";
		mem(004) := X"04";
		mem(005) := X"05";
		mem(006) := X"06";
		mem(007) := X"07";
		mem(008) := X"08";
		mem(052) := X"09";
		mem(105) := X"0A";
		mem(154) := X"A1";
		mem(254) := X"5F";
		mem(255) := X"FF";

		if (rising_edge(clk)) then
			o <= mem(to_integer(unsigned(addr)));
		end if;
	end process;
end alg;
