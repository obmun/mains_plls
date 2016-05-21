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
use WORK.COMMON.all;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;


-- === Brief description ===
--
-- Módulo que resta a la entrada el valor 2*pi, aunque el formato del pipeline tenga una magnitud
-- limitada que no permita representar la constante 2*pi.
--
-- === Description ===
--
-- El uso habitual de esta entidad es en aquellos casos en los que se quiere mantener 0 <= |phi| <
-- PI, mediante la resta de la constante 2*pi en cuanto se detecte que el ángulo phi acabe de
-- superar el límite superior de pi, pero se dispone de un pipeline con magnitud limitada. Con un
-- elemento restador del ancho del pipeline y una constante en una de sus entradas, no sería posible
-- realizar la resta.
--
-- Este bloque se encarga de internamente extender el pipeline, si es necesario, para representar la
-- constante 2*pi, y llevar a cabo la resta. 
--
-- == Necesidad ==
--
-- La codificación elegida originalmente (FX3.16) obligaba a la utilización de este elemento, ya que
-- 2*pi no era un valor representable en el pipeline. Para comodidad, en lugar de "anchear" el
-- pipeline temporalmente en el punto donde fuese necesario el reajuste del valor de determinado
-- ángulo, se diseño este bloque.
--
-- Ahora mismo, el ancho de pipeline es 100% flexible. Las primeras pruebas nos parecen indicar que
-- al menos deberemos usar un FX4.16 o incluso FX5.16 (con tan sólo 9 bits para la parte
-- fraccionaria), todas con capacidad para representar 2*pi. Este bloque parecería carecer de uso
--
-- Preferimos sin embargo mantener la táctica de que todos los ángulos vayan en argumento principal
-- (-180 < 0 <= 180), y seguimos utilizando este elemento.
--
-- === TODO ===
--
-- == Check if constant adder is using "simplified logic" ==
--
-- 1.- A 17 bit adder is CORRECTLY inferred. But I'M ADDING A CONSTANT.
--      Check in the final implementation is design is simplified with k in mind.
entity k_2pi_sub is
	generic (
		width : natural := PIPELINE_WIDTH;
                prec : natural := PIPELINE_PREC);
	port (
		i : in std_logic_vector(width - 1 downto 0);
		en : in std_logic;
		o : out std_logic_vector(width - 1 downto 0));
end k_2pi_sub;

architecture beh of k_2pi_sub is
        constant magn_size : natural := PIPELINE_WIDTH - PIPELINE_PREC - 1;
begin
        extended_generate : if magn_size < min_magn_size(TWO_PI) generate
        begin
                sub : process(i, en)
                        variable big_in, big_res : std_logic_vector(min_magn_size(TWO_PI) + 1 + PIPELINE_PREC downto 0);
                begin
                        big_in(width - 1 downto 0) := i;
                        big_in(big_in'high downto width) := (others => i(width - 1)); -- Sign extension
                        big_res := std_logic_vector(signed(big_in) + signed(to_vector(MINUS_TWO_PI, big_res'length, PIPELINE_PREC)));
                        if (en = '1') then
                                o(width - 2 downto 0) <= big_res(width - 2 downto 0);
                                o(width - 1) <= big_res(width); -- SIGN
                                                                -- EXTENSION
                                                                -- (compression :)
                        else
                                o <= i;
                        end if;
                end process;
        end generate;

        normal_generate : if magn_size >= min_magn_size(TWO_PI) generate
        begin
                sub : process(i, en)
                begin
                        if (en = '1') then
                                o <= std_logic_vector(signed(i) + signed(to_vector(MINUS_TWO_PI, width, prec)));
                        else
                                o <= i;
                        end if;
                end process;
        end generate;
end beh;
