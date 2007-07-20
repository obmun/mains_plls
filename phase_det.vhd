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
-- Phase detector based on Cordic seq engine. Control interface is identical to
-- the Cordic engine one. See Cordic doc.
-- 
-- *** DESCRIPTION ***
-- This phase detector multiplies input signal by a cos with current internal
-- detected phase to identify phase jumps. But due to the used method, a second
-- order harmonic in normal situation is generated and must be removed.
--
-- sin(theta_input) * cos(theta_internal) = sin(theta_input - theta_internal) *
-- 1/2 + sin(theta_input + theta_internal) * 1/2 <<-- (this second term is a
-- 2nd harmonic).
--
-- Therefore second harmonic substraction is also implemented inside this block.
--
-- This is just a wrapper around Cordic based cos / sin engine + some extra
-- combinational glue logic. Therefore no internal "state" machine apart of
-- the one from the Cordic engine is needed.
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.03 - An analisys of timing paths shows that the level of logic
-- due to the introduction of the new combinational angle_doubler at the entry
-- point of Cordic, creates a really LONG LONG combinational only path (delay
-- of 20 ns => max work freq. 50 MHz). To solve this, a register is introduced
-- in the middle of the street :)
-- Revision 0.02 - Added correct angle doubling procedure :). No-error tests
-- are correctly passed.
-- Revision 0.01 - File Created
-- 
--------------------------------------------------------------------------------
library IEEE;
use WORK.COMMON.ALL;
use IEEE.STD_LOGIC_1164.ALL;

entity phase_det is
    -- rev 0.02
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
                -- rev 0.01
		generic (
			width : natural := PIPELINE_WIDTH;
			prec_bits : natural := PIPELINE_PREC);
		port (
			a, b : in std_logic_vector (width - 1 downto 0);
			o : out std_logic_vector (width - 1 downto 0));
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
	signal mul_out, k_div_out, angle_doubler_out_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
        signal doubler_reg_out_s : std_logic_vector(PIPELINE_WIDTH downto 0);
	signal c_done, c_2_done : std_logic;
        signal input_reg_we_s : std_logic;
        signal norm_input_reg_out_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
begin

	-- INSTANTIATIONS
        norm_input_reg_i : entity work.reg(alg)
                generic map (
                        width => PIPELINE_WIDTH)
                
                port map (
                        clk => clk,
                        rst => rst,
                        we  => input_reg_we_s,
                        i => norm_input,
                        o => norm_input_reg_out_s);

        input_reg_we_s <= run and c_done and c_2_done;

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
			run => doubler_reg_out_s(PIPELINE_WIDTH),
			angle => doubler_reg_out_s(PIPELINE_WIDTH - 1 downto 0),
			-- SALIDAS
			sin => sin_2_out,
                        cos => open,
			done => c_2_done
		);

	mul_i : mul
		port map (
			-- ENTRADAS
			a => norm_input_reg_out_s,
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

        angle_doubler_i : entity work.angle_doubler(beh)
                port map (
                        i => curr_phase,
                        o => angle_doubler_out_s);

        doubler_reg_i : entity work.reg(alg)
                generic map (
                        width => PIPELINE_WIDTH + 1)
                port map (
                        clk => clk,
                        we => '1',
                        rst => '0',
                        i(PIPELINE_WIDTH) => run,
                        i(PIPELINE_WIDTH - 1 downto 0) => angle_doubler_out_s,
                        o => doubler_reg_out_s);

	done <= c_done and c_2_done;
end alg;
