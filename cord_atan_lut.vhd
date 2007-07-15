--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    
-- Design Name:    
-- Module Name:    cord_atan_lut - alg
-- Project Name:   
-- Target Device:  
-- Tool versions:  
-- Description:
-- | 8 + 1 LUT para la correspondencia entre tangente inversa (en realidad,
-- | fase N del algoritmo de Cordic) y el ángulo (atan) a restar al ángulo
-- | remanente Z.
-- | La dirección de entrada es de 4 bits para poder conectar directamente
-- | el estado del módulo de cálculo de Cordic (a pesar de que un bit sea
-- | sobrante).
-- Dependencies:
-- 
-- Revision:
-- | Revision 0.01 - File Created
-- Additional Comments:
-- 
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity cord_atan_lut is
	port (
		addr : in std_logic_vector(2 downto 0);
		angle : out std_logic_vector(15 downto 0)
	);
end cord_atan_lut;

architecture alg of cord_atan_lut is
	subtype angle_t is std_logic_vector(15 downto 0);
	constant ANGLE_S0 : angle_t := X"1922"; -- 45º ==
	constant ANGLE_S1 : angle_t := X"0ED6"; -- 26,5650º ==
	constant ANGLE_S2 : angle_t := X"07D7"; -- 14,0362º ==
	constant ANGLE_S3 : angle_t := X"03FB"; -- 7,12502º ==
	constant ANGLE_S4 : angle_t := X"01FF"; -- 3,57633º ==
	constant ANGLE_S5 : angle_t := X"0100"; -- 1,78991º ==
	constant ANGLE_S6 : angle_t := X"0080"; -- 0,89517º ==
	constant ANGLE_S7 : angle_t := X"0040"; -- 0,44761º ==
begin
	process(addr)
	begin
		case to_integer(unsigned(addr)) is
			when 0 =>
				angle <= ANGLE_S0;
			when 1 =>
				angle <= ANGLE_S1;
			when 2 =>
				angle <= ANGLE_S2;
			when 3 =>
				angle <= ANGLE_S3;
			when 4 =>
				angle <= ANGLE_S4;
			when 5 =>
				angle <= ANGLE_S5;
			when 6 =>
				angle <= ANGLE_S6;
			when 7 =>
				angle <= ANGLE_S7;
			when others =>
				-- SHOULD NOT HAPPEN (CANNOT happen)
				angle <= ANGLE_S0;
		end case;
	end process;
end alg;