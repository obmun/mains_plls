--------------------------------------------------------------------------------
-- KCM wrapper is an stupid VHDL entity around KCM to be able to synthesize it for synthesis
-- comparison purposes. It's needed because KCM needs some actuals to be applied to some of its
-- generics without default values.
--------------------------------------------------------------------------------

library WORK;
use WORK.COMMON.all;
library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity kcm_wrapper is
        port (
                i : in  std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
                o : out std_logic_vector(PIPELINE_WIDTH - 1 downto 0));
end kcm_wrapper;

architecture beh of kcm_wrapper is
begin 
        kcm_i : entity work.kcm(structural_mm)
                generic map (
                        width => PIPELINE_WIDTH,
                        prec  => PIPELINE_PREC,
                        k     => 5.8712)
                port map (
                        i => i,
                        o => o);
end beh;
