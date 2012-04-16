--------------------------------------------------------------------------------
-- *** BRIEF DESCRIPTION ***
--
-- Class: sequential iterative.
--
-- Phase detector based on Cordic seq engine. Control interface is identical to the Cordic engine
-- one. See Cordic doc.
-- 
-- *** DESCRIPTION ***
--
-- This phase detector multiplies input signal by a cos with current internal detected phase to
-- identify phase jumps. But due to the used method, a second order harmonic in normal situation is
-- generated and must be removed.
--
-- A_in * sin(theta_input) * cos(theta_internal) = A_in * sin(theta_input - theta_internal) * 1/2 +
-- A_in * sin(theta_input + theta_internal) * 1/2 <<-- (this second term is a 2nd harmonic).
--
-- In this second version of the phase det, 2nd harmonic is removed outside this element.
--
-- This is just a wrapper around Cordic based cos / sin engine + some extra combinational glue
-- logic. Therefore no internal "state" machine apart of the one from the Cordic engine is needed.
--
-- ** Port description **
--
-- * input *
--
-- Input value: signal whose phase deviation we want to detect (ideally a sinusoidal). It's up to
-- you to pass it normalized to us. If not, as you can verify observing the stupid structure, that
-- phase error is going to be multiplied by the input amplitude. Standard pipeline with and
-- prec easily allow for values up to 7.9999
--
-- Dependencies:
-- 
-- *** Revision ***
--
-- Revision 0.01 - File Created, based on Fran Simulink model
-- 
--------------------------------------------------------------------------------

library IEEE;
use WORK.COMMON.ALL;
use IEEE.STD_LOGIC_1164.ALL;

entity p2_phase_det is
    -- rev 0.02
    port (
        -- Input value signals
        input, curr_phase : in std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
        -- Input control signals
        run, rst, clk : in std_logic;
        -- Out value signals
        phase_error : out std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
        norm_output : out std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
        -- Out control signals
        done : out std_logic);
end p2_phase_det;

architecture beh of p2_phase_det is
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

	signal cos_out : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
	signal c_done : std_logic;
        signal input_reg_we_s : std_logic;
        signal input_reg_out_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
begin

	-- INSTANTIATIONS
        input_reg_i : entity work.reg(alg)
                generic map (
                        width => PIPELINE_WIDTH)
                
                port map (
                        clk => clk,
                        rst => rst,
                        we  => input_reg_we_s,
                        i => input,
                        o => input_reg_out_s);

        input_reg_we_s <= run and c_done;

	cordic_i : entity work.cordic(structural)
		port map (
			-- ENTRADAS
			clk => clk, rst => rst,
                        run => run,
			angle => curr_phase,
			-- SALIDAS
			sin => norm_output,
			cos => cos_out,
			done => c_done
		);

	mul_i : entity work.mul(beh)
		port map (
			-- ENTRADAS
			a => input_reg_out_s,
			b => cos_out,
			-- SALIDAS
			o => phase_error);

	done <= c_done;
end beh;
