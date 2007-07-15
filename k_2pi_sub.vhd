--------------------------------------------------------------------------------
-- Company: Universidad de Vigo
-- Engineer: Jacobo Cabaleiro
--
-- Create Date:    
-- Design Name:    
-- Module Name:    k_2pi_sub - alg
-- Project Name:   
-- Target Device:  
-- Tool versions:  7.1i
-- Description:
-- | Módulo que RESTA a la entrada 2*PI.
-- | El uso de esta entidad es en aquellos casos en los que se quiere mantener
-- | 0 <= |phi| < PI, restando 2*PI cuado phi acabe de superar el límite de PI.
-- | Dada la codificación elegida (coma fija FX3.16), 2*PI NO es un valor
-- | representable. Por eso internamente se trabaja con un bit más (FX4.16) para
-- | luego truncar el resultado a FX3.16 => EL RESULTADO SÓLO ES VÁLIDO EN LOS
-- | casos supuestos.
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- 
-- Additional Comments:
-- 
-- TODO:
-- | 1.- A 17 bit adder is CORRECTLY inferred. But I'M ADDING A CONSTANT.
-- |     Check in the final implementation is design is simplified with k in mind.
--------------------------------------------------------------------------------
library IEEE;
use WORK.COMMON.all;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity k_2pi_sub is
	generic (
		width : natural := PIPELINE_WIDTH
	);
	port (
		i : in std_logic_vector(width - 1 downto 0);
		en : in std_logic;
		o : out std_logic_vector(width - 1 downto 0)
	);
end k_2pi_sub;

architecture alg of k_2pi_sub is
begin
	sub : process(i, en)
		variable big_in, big_res : std_logic_vector(width downto 0);
	begin
		big_in(width - 1 downto 0) := i;
		big_in(width) := i(width - 1); -- Sign extension
		big_res := std_logic_vector(signed(big_in) + signed(MINUS_TWO_PI_FX417_V));
		if (en = '1') then
			o(width - 2 downto 0) <= big_res(width - 2 downto 0);
			o(width - 1) <= big_res(width); -- SIGN EXTENSION
		else
			o <= i;
		end if;
	end process;
end alg;