--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    09:55:04 06/26/06
-- Design Name:    
-- Module Name:    pipeline_expander - alg
-- Project Name:   
-- Target Device:  
-- Tool versions:  
-- Description:
--
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- TODO:
-- * REVIEW ME!! Check if TB covers all cases
--------------------------------------------------------------------------------
library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use WORK.COMMON.all;

entity pipeline_conv is
	generic (
		in_width : natural := PIPELINE_WIDTH;
		in_prec : natural := PIPELINE_PREC;
		out_width : natural := PIPELINE_WIDTH;
		out_prec : natural := PIPELINE_PREC
	);
	port (
		i_port : in std_logic_vector(in_width - 1 downto 0);
		o_port : out std_logic_vector(out_width - 1 downto 0)
	);
end pipeline_conv;

architecture alg of pipeline_conv is
begin
	conversor : process(i_port)
		constant in_magn : natural := in_width - in_prec;
		constant out_magn : natural := out_width - out_prec;
	begin
		-- Fractionary part
		if (in_prec < out_prec) then
			-- Expansión parte fraccionaria
			o_port(out_prec - 1 downto out_prec - in_prec) <= i_port(in_prec - 1 downto 0);
			o_port(out_prec - in_prec - 1 downto 0) <= (others => '0');
		else
			-- Compresión parte fraccionaria
			o_port(out_prec - 1 downto 0) <= i_port(in_prec - 1 downto in_prec - out_prec);
		end if;

		-- Magnitude part
		if (in_magn < out_magn) then
			-- Expansión
			-- Sign
			o_port(out_width - 1 downto out_prec + in_magn - 1) <= (others => i_port(in_width - 1));
			-- Value
			o_port(out_prec + in_magn - 2 downto out_prec) <= i_port(in_width - 2 downto in_prec);
		else
			-- Compresión
			-- Signo
			o_port(out_width - 1) <= i_port(in_width - 1);
			-- Valor
			o_port(out_width - 2 downto out_prec) <= i_port(in_prec + out_magn - 1 downto in_prec);
		end if;
	end process;
end alg;
