--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    04:25:51 05/05/06
-- Design Name:    
-- Module Name:    kcm - alg
-- Project Name:   
-- Target Device:  
-- Tool versions:  
-- Description:
--
-- Dependencies:
-- 
-- *** Changelog ***
-- Revision 0.03 - Corrected stupid problem with multiplication assignment
-- Revision 0.02 - Modified constant generic to be able to compile in ModelSim
-- Revision 0.01 - File Created
--
-- *** TODO ***
-- | > TODO: see if this is optimized using precomputed sub products (using small ROMs as LUTs; o sea, usando LUTs :)). Comprobado: aparentemente NO => Tengo que implementarlo YO de forma manual.
-- | > TODO: por qué está infiriendo un sumador?? Revisar el código <- DONE, a 
-- | > TODO: test bench this design
-- | > TODO: what happens if OVERFLOW occurss ... I'm doing "a saco" (TM) rounding
--------------------------------------------------------------------------------
library IEEE;
use WORK.COMMON.all;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity kcm is
	generic (
		width : natural := PIPELINE_WIDTH;
		prec : natural := PIPELINE_PREC;
		k : pipeline_integer := EXAMPLE_VAL_FX316 -- Cte de ejemplo. Una síntesis de esta cte infiere un multiplicador
	);
	port (
		i : in std_logic_vector(width - 1 downto 0);
		o : out std_logic_vector(width - 1 downto 0));
end kcm;

architecture alg of kcm is
begin
	process(i)
		constant k_signed : signed(width - 1 downto 0) := to_signed(k, width);
		variable res : signed(2 * width - 1 downto 0);
		variable j_out : natural;
	begin
		res := signed(i) * k_signed; -- Mmm... numeric_std signed * signed RETURNS (in own standard words) a'length * b'length - 1 (double sign bit!) result.
                                             -- I'm really wasting a bit. Why?
                                             -- Its just stupid ...
		-- Manual shift for correct truncation
		j_out := 0;
		for i in prec to prec + width - 2 loop
			o(j_out) <= res(i);
			j_out := j_out + 1;
		end loop;
		o(j_out) <= res(res'length - 1);
		--o <= std_logic_vector(resize(shift_right(signed(i) * k, PIPELINE_PREC), width));
	end process;
end alg;
