-- park_transform_wrapper is an stupid VHDL entity around park_transform to be able to synthesize it
-- for synthesis comparison purposes. It's needed because park_transform needs some actuals to be applied
-- to some of its generics without default values.

library WORK;
use WORK.COMMON.all;
library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity park_transform_wrapper_tb is
end park_transform_wrapper_tb;

architecture beh of park_transform_wrapper_tb is
        signal a_s, b_s, c_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
        signal sin_s, cos_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
        signal d_s, q_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
begin 
        uut : entity work.park_transform_wrapper(beh)
                port map (
                        a => a_s, b => b_s, c => c_s,
                        sin => sin_s, cos => cos_s,
                        d => d_s, q => q_s);
end beh;
