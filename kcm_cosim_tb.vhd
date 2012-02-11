library IEEE;
library WORK;
use WORK.COMMON.all;
use IEEE.STD_LOGIC_1164.all;


entity kcm_cosim_tb is
     generic (
          tb_width_g : positive := PIPELINE_WIDTH;  -- generic type
          tb_prec_g: positive := PIPELINE_PREC;
          tb_k_g : real := 1.0);
     -- Yes, I know this is a test bench and that suposedly I shouldn't have ports ...
     -- But remember that this is a cosimulated TB. This input port is driven by Matlab
     port (
          i : in std_logic_vector(tb_width_g - 1 downto 0);
          o_beh, o_beh2, o_beh3, o_struct_mm : out std_logic_vector(tb_width_g - 1 downto 0));
end kcm_cosim_tb;


architecture structural of kcm_cosim_tb is
begin
     kcm_beh_i : entity work.kcm(beh)
          generic map (
               width => tb_width_g, prec => tb_prec_g,
               k => tb_k_g)
          port map (
               i => i,
               o => o_beh);
     kcm_beh2_i : entity work.kcm(beh2)
          generic map (
               width => tb_width_g, prec => tb_prec_g,
               k => tb_k_g)
          port map (
               i => i,
               o => o_beh2);
     kcm_beh3_i : entity work.kcm(beh3)
          generic map (
               width => tb_width_g, prec => tb_prec_g,
               k => tb_k_g)
          port map (
               i => i,
               o => o_beh3);
     kcm_struct_mm_i : entity work.kcm(structural_mm)
          generic map (
               width => tb_width_g, prec => tb_prec_g,
               k => tb_k_g)
          port map (
               i => i,
               o => o_struct_mm);

end structural;

