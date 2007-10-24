-- park_transform_wrapper is an stupid VHDL entity around park_transform to be able to synthesize it
-- for synthesis comparison purposes. It's needed because park_transform needs some actuals to be applied
-- to some of its generics without default values.

library WORK;
use WORK.COMMON.all;
library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity park_transform_wrapper is
        port (
                a,b,c,sin,cos : in  std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
                d,q : out std_logic_vector(PIPELINE_WIDTH - 1 downto 0));
end park_transform_wrapper;

architecture beh of park_transform_wrapper is
begin 
        kcm_i : entity work.park_transform(structural)
                generic map (
                        width => PIPELINE_WIDTH,
                        prec  => PIPELINE_PREC)
                port map (
                        a => a, b => b, c => c,
                        sin => sin, cos => cos,
                        d => d, q => q);
end beh;
