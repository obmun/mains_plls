--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    
-- Design Name:    
-- Module Name:    mul - alg
-- Project Name:   
-- Target Device:  
-- Tool versions:  
-- Description:
--
-- Dependencies:
-- 
-- Revision:
-- Revision 0.02 - Added correct saturation of output, to avoid "oscillations"
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
--------------------------------------------------------------------------------
library IEEE;
use WORK.COMMON.all;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity mul is
        -- rev 0.02
	generic (
		width : natural := PIPELINE_WIDTH;
		prec : natural := PIPELINE_PREC);
	port (
		a, b : in std_logic_vector (width - 1 downto 0);
		o : out std_logic_vector (width - 1 downto 0));
end mul;

architecture beh of mul is
begin
	process(a, b)
                constant all_ones : signed((width - prec) - 1 downto 0) := (others => '1');
                constant all_zeros : signed((width - prec) - 1 downto 0) := (others => '0');
                variable tmp_res : signed(2 * width - 1 downto 0);
	begin
                tmp_res := signed(a) * signed(b);
                -- Correct output saturation
                if ((tmp_res(tmp_res'length - 1) = '1') and (tmp_res(tmp_res'length - 2 downto (prec + width - 1)) /= all_ones)) then
                        o(width - 2 downto 0) <= (others => '0');
                        o(width - 1) <= '1';
                elsif ((tmp_res(tmp_res'length - 1) = '0') and (tmp_res(tmp_res'length - 2 downto (prec + width - 1)) /= all_zeros)) then
                        o(width - 2 downto 0) <= (others => '1');
                        o(width - 1) <= '0';
                else
                        o <= std_logic_vector(resize(shift_right(tmp_res, prec), width));
                end if;
	end process;
end beh;
