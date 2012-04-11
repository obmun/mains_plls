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
--
-- === Brief description ===
-- Parametrizable LUT for storing Cordic algorithm angles
--
-- === Description ===
-- LUT para la correspondencia entre tangente inversa (en realidad,
-- fase N del algoritmo de Cordic) y el �ngulo (atan) a restar al �ngulo
-- remanente Z.
--
-- El objetivo fundamental es implementar una LUT que permita la inteferencia
-- al sintetizador de una ROM, para minimizar el uso de logica y poder
-- aprovechar los recursos como BRAM y ROMS disponibles en las FPGAs.
--
-- Otro objetivo importante es el disponer de una LUT de atan lo
-- suficientemente parametrizable y flexible como para poder ser utilizada para
-- cualquier prec y ancho de palabra as� como para cualquier numero de steps en
-- el algoritmo Cordic.
--
-- == Ports ==
-- * Generics *
-- -> width, prec: definition of pipeline format
-- -> last_angle: the max valid address. If addr > last_angle, entity asserts
-- * Inputs *
-- -> addr: 0 indexed
-- * Outputs *
-- -> angle: sin value for given input angle
--
--
-- == Implementacion ==
--
-- La implementaci�n original "forzaba" demasiadas cosas en lugar de dar flexibilidad al
-- sintetizador, con lo que ten�a un problema principal: poco flexible.
--
-- Para poder implementar una LUT utilizable si se aumentaba la precisi�n, se decidi� "almacenar"
-- los �ngulos para una precisi�n m�xima alta, q sabemos dificilmente llegaremos a utilizar en el
-- dise�o. En este caso, ese valor de precisi�n es de **24 BITS**.
--
-- Como no todos los �ngulos pueden ser necesarios (direccionamiento) ni todos los bits de precisi�n
-- son necesarios (trimming de los bits finales de las palabras), las siguientes decisiones se
-- tomaron:
--
-- * La direcci�n de entrada no es un logic_vector, si no diretamente un entero. La direcci�n m�xima
-- se fija mediante un generic, utilizado en un assert para emitir un error en caso de ser este
-- valor superado [la explicaci�n de por qu� se usa un assert, a continuaci�n]
--
-- * Se intent�, para el caso del Xilinx ISE 7.1, codificar un l�mite para la direcci�n (subrango en
-- el puerto de entrada de la direcci�n, subtypo con limitaci�n de rango, if en el proceso para
-- fijar una direcci�n local a un m�ximo en caso que la direcci�n de entrada superase un valor) sin
-- �xito. La s�ntesis en lugar de mejorar [infiriendo roms de menor anchura y tama�o], empeoraba en
-- gran medida: la herramienta no era capaz de seguir infiriendo una ROM. La gran disponibilidad de
-- memoria / ROM distribuidas / concentradas en esta y pr�cticamente cualquier otra FPGA, y el
-- tama�o reducido de la ROM final implementada (a�n en el caso de usar todos los datos) hacen que
-- NO MEREZCA LA PENA rallarse la cabeza buscando reducir la anchura de palabra de la ROM de los 24
-- bits originales a menos o del tama�o de la ROM de 26 a menos.
--
-- * Es muy f�cil conseguir la asignaci�n correcta de los bits de salida, qued�ndose s�lo con la
-- precisi�n necesaria de los valores almacenados.
--
-- This was quickly implemented by extensive use of emacs macros and a pair of Matlab scripts for
-- easily calculating the binary values of the angles.
--
-- === Changelog ===
--
-- Revision 0.02 - Cambio radical. M�s anchura, m�s tama�o, para flexibilizar y posibilitar su uso
-- en cualquier situaci�n.
--
-- Revision 0.01 - File Created
--------------------------------------------------------------------------------
library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use WORK.COMMON.all;

entity cordic_atan_lut is
        generic (
                width : natural := PIPELINE_WIDTH;
                prec : natural := PIPELINE_PREC;
                last_angle : natural := 7);
	port (
		addr : in natural;
		angle : out std_logic_vector(width - 1 downto 0));
end cordic_atan_lut;

architecture beh of cordic_atan_lut is
	subtype angle_t is std_logic_vector(23 downto 0);
        type rom_t is array (0 to 24) of angle_t;
        -- 45� = pi/4 rad ~= 0,78 < 1 => we do not need magnitud bits, just precision
        constant ROM : rom_t := (
                "110010010000111111011011",  -- 45�
                "011101101011000110011100",
                "001111101011011011101100",
                "000111111101010110111011",
                "000011111111101010101110",
                "000001111111111101010101",
                "000000111111111111101011",
                "000000011111111111111101",
                "000000010000000000000000",
                "000000001000000000000000",
                "000000000100000000000000",
                "000000000010000000000000",
                "000000000001000000000000",
                "000000000000100000000000",
                "000000000000010000000000",
                "000000000000001000000000",
                "000000000000000100000000",
                "000000000000000010000000",
                "000000000000000001000000",
                "000000000000000000100000",
                "000000000000000000010000",
                "000000000000000000001000",
                "000000000000000000000100",
                "000000000000000000000010",
                "000000000000000000000001");

begin
        angle(width - 1 downto prec) <= (others => '0');
        
	process(addr)
	begin
                -- This test throws a lot of stupid warnings because during
                -- Cordic, after finishing, we do not really STOP the counter
                -- (we just let it continue till it overflows)
                -- assert (addr <= last_angle) report "addr > last_angle [you're going outside your own fixed limits" severity error;
                assert (addr <= 24) report "no such angle value stored. You've gone too far!! Recalc angles" severity error;
                angle(prec - 1 downto 0) <= ROM(addr)(angle_t'length - 1 downto (angle_t'length - prec));
	end process;
end beh;
