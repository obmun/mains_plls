----------------------------------------------------------------------------------------------------
-- *** Brief description ***
--
-- Wrapper around 'sqrt' entity which takes care of, given x[n] input, calculating:
-- y[n] = sign(x[n])(sqrt(abs(x[n])))
--
----------------------------------------------------------------------------------------------------

library WORK;
use WORK.COMMON.all;
library IEEE;
use IEEE.STD_LOGIC_1164.all;


entity signed_sqrt is
     generic (
          prec : natural := PIPELINE_PREC);
     port (
          clk, rst, run   : in  std_logic;
          i               : in  std_logic_vector(18 - 1 downto 0);
          o               : out std_logic_vector(18 - 1 downto 0);
          done, neg_input : out std_logic);
end entity;


architecture structural of signed_sqrt is
     signal error_s, sign_REG_s : std_logic;
     signal abs_i_s, sqrt_o_s, inv_sqrt_o_s : std_logic_vector(18 - 1 downto 0);
begin
     abs_i : entity work.absolute(beh)
          generic map (
               width => 18)
          port map (
               i => i,
               o => abs_i_s);

     signed_reg_i : entity work.reg(alg)
          generic map (
               width => 1)
          port map (
               clk  => clk,
               we   => run,
               rst  => rst,
               i(0) => i(18 - 1),
               o(0) => sign_REG_s);
     
     sqrt_i : entity work.sqrt(alg)
          generic map (
               prec => prec)
          port map (
               clk     => clk,
               rst     => rst,
               run     => run,
               i       => abs_i_s,
               o       => sqrt_o_s,
               done    => done,
               error_p => error_s);
     assert error_s = '0' report "ERROR reported by SQRT!!!" severity error;

     inv_i : entity work.inverter(beh)
          generic map (
               width => 18)
          port map (
               i => sqrt_o_s,
               o => inv_sqrt_o_s);

     o <= sqrt_o_s when (sign_REG_s = '0') else inv_sqrt_o_s;     
end architecture structural;
                         
