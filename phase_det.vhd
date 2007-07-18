--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    
-- Design Name:    
-- Module Name:    phase_det - alg
-- Project Name:   
-- Target Device:  
-- Tool versions:  
--
-- *** BRIEF DESCRIPTION ***
-- Phase detector based on Cordic seq engine. Control interfaz is identical to
-- the Cordic engine one. See Cordic doc.
-- 
-- *** DESCRIPTION ***
-- This is just a wrapper around Cordic based cos / sin engine + some extra
-- combinational glue logic. Therefore no internal "state" machine apart of
-- the one from the Cordic engine is needed.
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- 
--------------------------------------------------------------------------------
library IEEE;
use WORK.COMMON.ALL;
use IEEE.STD_LOGIC_1164.ALL;

entity phase_det is
    -- rev 0.01
    port (
        -- Input value signals
        norm_input, curr_phase : in std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
        -- Input control signals
        run, rst, clk : in std_logic;
        -- Out value signals
        phase_error : out std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
        norm_output : out std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
        -- Out control signals
        done : out std_logic);
end phase_det;

architecture alg of phase_det is
	-- Component declarations
	component cordic is
		generic (
			width : natural := PIPELINE_WIDTH
		);
		port (
			clk, rst, run : in std_logic;
			angle : in std_logic_vector(width - 1 downto 0); -- In RADIANS!
			sin, cos : out std_logic_vector(width - 1 downto 0);
			done : out std_logic
		);
	end component;

	component mul is
		generic (
			width : natural := PIPELINE_WIDTH;
			prec_bits : natural := PIPELINE_PREC
		);
		port (
			a, b : in std_logic_vector (width - 1 downto 0);
			o : out std_logic_vector (width - 1 downto 0)
		);
	end component;

	component subsor is
		generic (
			width : natural := PIPELINE_WIDTH
		);
		port (
			a, b: in std_logic_vector(width - 1 downto 0);
			o: out std_logic_vector(width - 1 downto 0);
			f_ov, f_z: out std_logic
		);
	end component;

	component k_2_div is
		generic (
			width : natural := PIPELINE_WIDTH
		);
		port (
			i : in std_logic_vector(width - 1 downto 0);
			o : out std_logic_vector(width - 1 downto 0)
		);
	end component;

	component k_2_mul is
		generic (
			width : natural := PIPELINE_WIDTH
		);
		port (
			i : in std_logic_vector(width - 1 downto 0);
			o : out std_logic_vector(width - 1 downto 0)
		);
	end component;

	signal cos_out, sin_2_out : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
	signal mul_out, k_div_out, k_mul_out : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
	signal c_done, c_2_done : std_logic;
begin

	-- INSTANTIATIONS
	cordic_i : cordic
		port map (
			-- ENTRADAS
			clk => clk,
			rst => rst,
			run => run,
			angle => curr_phase,
			-- SALIDAS
			sin => norm_output,
			cos => cos_out,
			done => c_done
		);

	cordic_2_i : cordic
		port map (
			-- ENTRADAS
			clk => clk,
			rst => rst,
			run => run,
			angle => k_mul_out,
			-- SALIDAS
			sin => sin_2_out,
                        cos => open,
			done => c_2_done
		);

	mul_i : mul
		port map (
			-- ENTRADAS
			a => norm_input,
			b => cos_out,
			-- SALIDAS
			o => mul_out);

	subsor_i : subsor
		port map (
			-- ENTRADAS
			a => mul_out,
			b => k_div_out,
			-- SALIDAS
			o => phase_error,
                        -- Unused
                        f_ov => open,
                        f_z => open);

	k_2_div_i : k_2_div
		port map (
			i => sin_2_out,
			o => k_div_out
		);

	k_2_mul_i : k_2_mul
		port map (
			i => curr_phase,
			o => k_mul_out
		);

	done <= c_done or c_2_done;
end alg;
