--------------------------------------------------------------------------------
-- Company: Universidad de Vigo
-- Engineer: Jacobo Cabaleiro
--
-- Create Date:    
-- Design Name:    
-- Module Name:    1st_order_lpf - alg
-- Project Name:   
-- Target Device:  
-- Tool versions:  
-- *** Description ***
-- ** Ports **
-- * Inputs *
-- -> en: (no 3rd state). If 0, ignores clks
-- Dependencies:
-- 
-- Todo:
-- | > Check if alfa^(-1) and -beta / alfa values can be automatically calculated from Kp. Right now user has to precalc them.
--
-- *** Revisions ***
-- Revision 0.02 - Added RUN/DONE interface
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
--------------------------------------------------------------------------------
library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use WORK.COMMON.all;

entity first_order_lpf is
        -- rev 0.02
	generic (
		width : natural := PIPELINE_WIDTH);
	port (
		clk, en, rst : in std_logic;
		i : in std_logic_vector(width - 1 downto 0);
		o : out std_logic_vector(width - 1 downto 0);
                run : in std_logic;
                done : out std_logic);
        
end first_order_lpf;

architecture alg of first_order_lpf is
        type state is (ST_STOP, ST_RUN);
        signal st_s : state;
        
	component kcm
		generic (
			width : natural := PIPELINE_WIDTH;
			prec : natural := PIPELINE_PREC;
			k : pipeline_integer := -23410 -- Cte de ejemplo. Una síntesis de esta cte infiere un multiplicador
		);
		port (
			i : in std_logic_vector(width - 1 downto 0);
			o : out std_logic_vector(width - 1 downto 0)
		);
	end component;

	component adder is
		generic (
			width : natural := PIPELINE_WIDTH
		);
		port (
			a, b: in std_logic_vector(width - 1 downto 0);
			o: out std_logic_vector(width - 1 downto 0);
			f_ov, f_z: out std_logic
		);
	end component;

	component reg is
		generic (
			width : natural := PIPELINE_WIDTH
		);
		port (
			clk, we, rst : in std_logic;
			i : in std_logic_vector(width - 1 downto 0);
			o : out std_logic_vector(width - 1 downto 0)
		);
	end component;

	signal i_kcm_out, fb_adder_out, reg_adder_out, delay_out, fb_kcm_out : std_logic_vector(width - 1 downto 0);
        signal en_s : std_logic;
begin
	i_kcm : kcm
		generic map (
			k => 390 -- 0,047619047
		)
		port map (
			i => i,
			o => i_kcm_out
		);

	fb_kcm : kcm
		generic map (
			k => 7412 -- 0,904761
		)
		port map (
			i => delay_out,
			o => fb_kcm_out
		);

	fb_adder : adder
		port map (
			a => i_kcm_out, b => fb_kcm_out,
			o => fb_adder_out,
			f_ov => open, f_z => open);

	reg_adder : adder
		port map (
			a => fb_adder_out, b => i,
			o => reg_adder_out,
			f_ov => open, f_z => open
		);

	delay : reg
		port map (
			clk => clk, we => en_s, rst => rst,
			i => reg_adder_out,
			o => delay_out);

	o <= fb_adder_out;

        -- RUN/DONE protocol!
        -- run signal must control en of "sequential" elements.
        st_ctrl : process(clk)
        begin
            if (rising_edge(clk)) then
                if (en = '1') then
                    if (rst = '1') then
                        st_s <= ST_STOP;
                    else
                        case st_s is
                            when ST_STOP =>
                                if (run = '1') then
                                    st_s <= ST_RUN;
                                else
                                    st_s <= ST_STOP;
                                end if;
                            when ST_RUN =>
                                if (run = '1') then
                                    st_s <= ST_RUN;
                                else
                                    st_s <= ST_STOP;
                                end if;
                            when others =>
                                null;
                        end case;
                    end if;
                end if;
            end if;
        end process st_ctrl;

        signal_gen : process(st_s)
        begin
                case st_s is
                        when ST_STOP =>
                                done <= '0';
                                en_s <= '0';
                        when ST_RUN =>
                                done <= '1';
                                en_s <= en;
                        when others =>
                                null;
                end case;
        end process signal_gen;
end alg;
