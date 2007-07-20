library IEEE;
use WORK.COMMON.ALL;
use IEEE.STD_LOGIC_1164.ALL;

entity done_pulser is
        port (
                clk : in  std_logic;
                en  : in  std_logic;
                rst : in  std_logic;
                i   : in  std_logic;
                o   : out std_logic);
end done_pulser;

architecture beh of done_pulser is
        signal mono_out_s : std_logic;
begin  -- beh
        reg_i : entity work.reg(alg)
                generic map (
                        width => 1)
                port map (
                        i(0) => i,
                        o(0) => mono_out_s,
                        clk  => clk,
                        we   => en,
                        rst  => rst);

        o <= i and not mono_out_s;
end beh;
