--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    
-- Design Name:    
-- Module Name:  p2_ampl_loop
-- Project Name:   
-- Target Device:  
-- Tool versions:  
--
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - Creación del bucle de amplitud, basado en el modelo de
-- Simulink de Fran
-- Additional Comments:
-- 
--------------------------------------------------------------------------------

library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use WORK.COMMON.all;

entity p2_ampl_loop is
        -- rev 0.01
	port (
		clk, run, rst : in std_logic;
		in_signal, our_signal : in std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
		norm_in_signal : out std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
		done : out std_logic);
end p2_ampl_loop;

architecture beh of p2_ampl_loop is
        -- Some constants
        constant ONE : std_logic_vector(PIPELINE_WIDTH - 1 downto 0) := to_pipeline_vector(1.0);
        
	-- * Internal elements control *
        signal pi_int_done_s : std_logic;

        signal garbage_1_s : std_logic;

	-- * DATA PATH *
	signal squared_in_EXT_s, squared_alpha_EXT_s, squared_in_norm_EXT_s : std_logic_vector(EXT_PIPELINE_WIDTH - 1 downto 0);
	signal error_EXT_s, int_error_EXT_s, filtered_error_EXT_s : std_logic_vector(EXT_PIPELINE_WIDTH - 1 downto 0);
	signal error_adder_1_out_EXT_s : std_logic_vector(EXT_PIPELINE_WIDTH - 1 downto 0);
	signal alpha_EXT_s : std_logic_vector(EXT_PIPELINE_WIDTH - 1 downto 0);

	signal squared_norm_s, scaled_norm_s, in_mul_out_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
        signal error_s, pi_int_out_s, pi_kp_out_s, pi_out_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
	
	signal alpha_s, norm_in_signal_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
begin
	our_square : entity work.mul(beh)
		port map (
                        a => our_signal, b => our_signal, o => squared_norm_s);
        
        our_mul : entity work.mul(beh)
                port map (
                        a => our_signal,
                        b => alpha_s,
                        o => scaled_norm_s);

	in_mul : entity work.mul(beh)
                port map (
                        a => in_signal,
                        b => scaled_norm_s,
                        o => in_mul_out_s);

	error_sub : entity work.subsor(alg)
		port map (
			a => squared_norm_s,
                        b => in_mul_out_s,
                        o => error_s,
			f_ov => open, f_z => open);

	pi_integrator : entity work.kcm_integrator(beh)
		generic map (
			k => 1000.0,
                        delayer_width => 1)
		port map (
			clk => clk, rst => rst,
                        run_en => run, run_passthru => pi_int_done_s,
			i => error_s, o => pi_int_out_s,
                        delayer_in(0) => '-',
                        delayer_out(0) => garbage_1_s);

--	pi_kp_mul : entity work.kcm(beh)
--		generic map (
--                        k => 1.0)
--		port map (
--                        i => error_s,
--                        o => pi_kp_out_s);

        pi_adder : entity work.adder(alg)
                port map (
                        a    => error_s,
                        b    => pi_int_out_s,
                        o    => pi_out_s,
                        f_ov => open,
                        f_z  => open);
                
	error_dc_adder : entity work.adder(alg)
		port map (
			a => pi_out_s,
                        b => ONE,
			o => alpha_s,
                        f_ov => open, f_z => open);

        in_norm_mul : entity work.mul(beh)
                port map (
                        a => in_signal,
                        b => alpha_s,
                        o => norm_in_signal_s);

        done <= pi_int_done_s;
        norm_in_signal <= norm_in_signal_s;
end beh;
