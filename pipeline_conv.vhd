--------------------------------------------------------------------------------
-- *** Changelog ***
--
-- Revision 0.02 - Port renaming and file structure change to overcome ModelSim
-- simulator problem!
--
-- Revision 0.01 - File Created
--
-- *** TODO ***
--
-- * MAKE rounding mode configurable thru a generic
-- * ADD A SECOND ARCHITECTURE WITH A CORRECT ROUNDING MODE. But I don't really
-- know if I'm gonna need it
-- * REVIEW ME!! Check if TB covers all cases
--------------------------------------------------------------------------------

library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use WORK.COMMON.all;

entity pipeline_conv is
        -- rev 0.02
	generic (
		in_width : natural;
		in_prec : natural;
		out_width : natural;
		out_prec : natural);
	port (
		i : in std_logic_vector(in_width - 1 downto 0);
		o : out std_logic_vector(out_width - 1 downto 0));
end pipeline_conv;

architecture alg of pipeline_conv is
        constant in_magn : natural := in_width - in_prec;
        constant out_magn : natural := out_width - out_prec;
        
        function execute_checks return std_logic is
        begin
             assert in_width > in_prec report "in_width < in_prec" severity failure;
             assert out_width > out_prec report "out_width < out_prec" severity failure;
             assert in_magn > 0 report "input magnitude bits <= 0" severity failure;
             assert out_magn > 0 report "output magnitude bits <= 0" severity failure;
             return '0';
        end execute_checks;

        signal garbage_s : std_logic := execute_checks;
begin
        -- Fractionary part
        frac_gen_0 : if (in_prec < out_prec) generate
                frac_part_conv : process(i)
                begin   
                        -- Expansión parte fraccionaria
                        o(out_prec - 1 downto out_prec - in_prec) <= i(in_prec - 1 downto 0);
                        o(out_prec - in_prec - 1 downto 0) <= (others => '0');
                end process frac_part_conv;
        end generate;

        frac_gen_1 : if (in_prec >= out_prec) generate
                frac_part_conv : process(i)
                begin
                        -- Compresión parte fraccionaria
			o(out_prec - 1 downto 0) <= i(in_prec - 1 downto in_prec - out_prec);
                end process frac_part_conv;
        end generate;
                                
        
        -- Magnitude part

        -- Expansión
        magn_gen_0a : if (in_magn < out_magn) and (in_magn = 1) generate  -- VHDL 2002 does not
                                                                          -- support nested if-generates
             -- Any other option is impossibale. out_magn = 1 would mean in_magn <= 0 (impossible)
             magn_part_conv : process(i)
             begin
                  -- Only sign on input
                  o(out_width - 1 downto out_prec + (in_width - in_prec) - 1) <= (others => i(in_width - 1));
             end process magn_part_conv;
        end generate;
        
        magn_gen_0b: if (in_magn < out_magn) and (in_magn /= 1) generate
             magn_part_conv : process(i)
             begin
                  -- Sign
                  o(out_width - 1 downto out_prec + (in_width - in_prec) - 1) <= (others => i(in_width - 1));
                  -- Value
                  o(out_prec + (in_width - in_prec) - 2 downto out_prec) <= i(in_width - 2 downto in_prec);
             end process magn_part_conv;
        end generate;
        
        -- Compresión
        magn_gen_1a : if (in_magn >= out_magn) and (out_magn = 1) generate
             magn_part_conv : process(i)
             begin
                  -- Only sign
                  o(out_width - 1) <= i(in_width - 1);
             end process magn_part_conv;     
        end generate;

        magn_gen_1b : if (in_magn >= out_magn) and (out_magn /= 1) generate
             magn_part_conv : process(i)
             begin
                  -- Signo
                  o(out_width - 1) <= i(in_width - 1);
                  -- Valor
                  o((out_width - 2) downto out_prec) <= i(in_prec + (out_width - out_prec) - 2 downto in_prec);
             end process;
        end generate;
end alg;
