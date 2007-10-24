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


architecture beh2 of kcm is
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
                if (res(res'length - 1) = '1') then
                        if (res(res'length - 2 downto (prec + width - 1)) /= all_ones) then
                                -- Saturation towards negative
                                o(width - 2 downto 0) <= (others => '0');
                        else
                                for i in prec to prec + width - 2 loop
                                        o(i - prec) <= res(i);
                                end loop;
                        end if;
                else
                        if (res(res'length - 2 downto (prec + width - 1)) /= all_zeros) then
                                -- Saturation towards positive
                                o(width - 2 downto 0) <= (others => '1');
                        else
                                -- Manual shift for correct truncation
                                for i in prec to prec + width - 2 loop
                                        o(i - prec) <= res(i);
                                end loop;
                                -- o <= std_logic_vector(resize(shift_right(signed(i) * k, PIPELINE_PREC), width));
                        end if;
                end if;
                o(width - 1) <= res(res'length - 1);
	end process;
end beh2;


architecture beh3 of kcm is
        signal res_s : signed(2 * width - 1 downto 0);
begin
	mult : process(i)
		constant k_signed : signed(width - 1 downto 0) := signed(to_vector(k, width, prec));
	begin
		res_s <= signed(i) * k_signed;
	end process;

        saturation : process(res_s)
                constant all_ones : signed((width - prec) - 1 downto 0) := (others => '1');
                constant all_zeros : signed((width - prec) - 1 downto 0) := (others => '0');
        begin
                -- Correctly saturate OUTPUT (otherwise we're doing some kind
                -- of modulus operation)
                if (res_s(res_s'length - 1) = '1') then
                        if (res_s(res_s'length - 2 downto (prec + width - 1)) /= all_ones) then
                                -- Saturation towards negative
                                o(width - 2 downto 0) <= (others => '0');
                        else
                                for i in prec to prec + width - 2 loop
                                        o(i - prec) <= res_s(i);
                                end loop;
                        end if;
                else
                        if (res_s(res_s'length - 2 downto (prec + width - 1)) /= all_zeros) then
                                -- Saturation towards positive
                                o(width - 2 downto 0) <= (others => '1');
                        else
                                -- Manual shift for correct truncation
                                for i in prec to prec + width - 2 loop
                                        o(i - prec) <= res_s(i);
                                end loop;
                                -- o <= std_logic_vector(resize(shift_right(signed(i) * k, PIPELINE_PREC), width));
                        end if;
                end if;
        end process;

        o(width - 1) <= res_s(res_s'length - 1);
end beh3;


architecture structural_mm of kcm is
        -- I need as many intermediate results (tmp_res) as bits has the
        -- constant multiplicand, and "one more" to maintain generate for uniform
        type tmp_res_t is array (width downto 0) of std_logic_vector(width downto 0);
        signal tmp_res_s : tmp_res_t;
        
        signal res_s : std_logic_vector(2 * width - 1 downto 0);

        constant csd_multiplicand : csd_logic_vector(width downto 0) := vector_to_csd(to_vector(k, width, prec));
begin
        tmp_res_s(0) <= (others => '0');
        
        additions_i: for j in 0 to width - 1 generate
                with csd_multiplicand(j) select tmp_res_s(j + 1) <=
                        std_logic_vector(shift_right(signed(tmp_res_s(j - 1 + 1)), 1)) when '0',
                        std_logic_vector(signed(tmp_res_s(j - 1 + 1)(width downto 1)) + signed(i)) when 'p',
                        std_logic_vector(signed(tmp_res_s(j - 1 + 1)(width downto 1)) - signed(i)) when 'm';
                res_s(j) <= tmp_res_s(j + 1)(0);                
        end generate additions_i;

        res_s(2 * width - 1 downto width) <= tmp_res_s(width - 1 + 1)(width downto 1);

end structural_mm;
