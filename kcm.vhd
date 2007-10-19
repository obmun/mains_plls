--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    04:25:51 05/05/06
-- Design Name:    
-- Module Name:    kcm - alg
-- Project Name:   
-- Target Device:  
-- tool versions:  
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
                -- Cte de ejemplo. Una síntesis de esta cte infiere un multiplicador
		k : real);
	port (
		i : in std_logic_vector(width - 1 downto 0);
		o : out std_logic_vector(width - 1 downto 0));
end kcm;

architecture beh of kcm is
begin
	process(i)
                constant all_ones : signed((width - prec) - 1 downto 0) := (others => '1');
                constant all_zeros : signed((width - prec) - 1 downto 0) := (others => '0');
		constant k_signed : signed(width - 1 downto 0) := signed(to_vector(k, width, prec));
		variable res : signed(2 * width - 1 downto 0);
	begin
		res := signed(i) * k_signed;
                -- Correctly saturate OUTPUT (otherwise we're doing some kind
                -- of modulus operation)
                if ((res(res'length - 1) = '1') and (res(res'length - 2 downto (prec + width - 1)) /= all_ones)) then
                        -- Saturation towards negative
                        o(width - 2 downto 0) <= (others => '0');
                        o(width - 1) <= '1';
                elsif ((res(res'length - 1) = '0') and (res(res'length - 2 downto (prec + width - 1)) /= all_zeros)) then
                        -- Saturation towards positive
                        o(width - 2 downto 0) <= (others => '1');
                        o(width - 1) <= '0';
                else
                        -- Manual shift for correct truncation
                        for i in prec to prec + width - 2 loop
                                o(i - prec) <= res(i);
                        end loop;
                        o(o'length - 1) <= res(res'length - 1);
                        -- o <= std_logic_vector(resize(shift_right(signed(i) * k, PIPELINE_PREC), width));
                end if;
	end process;
end beh;
