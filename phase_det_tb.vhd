library IEEE;
use WORK.COMMON.ALL;
use IEEE.STD_LOGIC_1164.ALL;

entity phase_det_tb is
end phase_det_tb;

architecture beh of phase_det_tb is
        constant CLOCK_PERIOD : time := 20 ns;
        
        signal clk_s, rst_s, run_s, done_s : std_logic;
        signal norm_input_s, curr_phase_s, phase_error_s, norm_output_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);

        constant ONE_FX316_V : std_logic_vector(PIPELINE_WIDTH - 1 downto 0) := X"2000";
        constant MINUS_ONE_FX316_V : std_logic_vector(PIPELINE_WIDTH - 1 downto 0) := X"E000";

        constant PI_OVER_4_FX316_V : std_logic_vector(PIPELINE_WIDTH - 1 downto 0) := X"1922";
        constant MINUS_3_PI_OVER_4_FX316_V : std_logic_vector(PIPELINE_WIDTH - 1 downto 0) := X"B49A";
begin

        phase_det_i : entity work.phase_det(alg)
                port map (
                        clk   => clk_s,
                        rst   => rst_s,
                        run   => run_s,
                        norm_input => norm_input_s,
                        curr_phase => curr_phase_s,
                        phase_error => phase_error_s,
                        norm_output => norm_output_s,
                        done => done_s);
                
        signal_gen : process
        begin
                rst_s <= '1';
                run_s <= '0';
                curr_phase_s <= (others => '0');
                norm_input_s <= (others => '0');
                                
                wait on clk_s until rising_edge(clk_s);
                wait on clk_s until falling_edge(clk_s);
                rst_s <= '0';
                
                -- Just check the BASIC detecting capabilities
                -- INPUT THIS a NON ERROR SIGNAL, and check if it works:
                -- Input: theta_internal = theta_current = 0 =>
                -- curr_phase_s <= 0
                -- norm_input_s <= sin(0) = 0
                -- Output SHOULD be: 0
                curr_phase_s <= (others => '0');
                norm_input_s <= ZERO_FX316_V;
                run_s <= '1';
                wait on done_s until done_s = '0';
                run_s <= '0';
                wait on done_s until done_s = '1';

                -- Input: theta_internal = theta_current = pi / 2 =>
                -- curr_phase_s <= pi / 2
                -- norm_input_s <= sin(pi / 2) = 1
                -- Output SHOULD be: 0
                curr_phase_s <= HALF_PI_FX316_V;
                norm_input_s <= ONE_FX316_V;
                run_s <= '1';
                wait on done_s until done_s = '0';
                run_s <= '0';
                wait on done_s until done_s = '1';

                -- Input: theta_internal = theta_current = pi =>
                -- curr_phase_s <= pi
                -- norm_input_s <= sin(pi) = 0
                -- Output SHOULD be: 0
                curr_phase_s <= PI_FX316_V;
                norm_input_s <= ZERO_FX316_V;
                run_s <= '1';
                wait on done_s until done_s = '0';
                run_s <= '0';
                wait on done_s until done_s = '1';

                -- Input: theta_internal = theta_current = -pi/2 =>
                -- curr_phase_s <= -pi/2
                -- norm_input_s <= sin(-pi/2) = -1
                -- Output SHOULD be: 0
                curr_phase_s <= MINUS_HALF_PI_FX316_V;
                norm_input_s <= MINUS_ONE_FX316_V;
                run_s <= '1';
                wait on done_s until done_s = '0';
                run_s <= '0';
                wait on done_s until done_s = '1';

                -- Input: theta_internal = theta_current = pi/4 =>
                -- curr_phase_s <= pi/4
                -- norm_input_s <= sin(pi/4)
                -- Output SHOULD be: 0
                curr_phase_s <= PI_OVER_4_FX316_V;
                norm_input_s <= X"16A1";  -- hex(fi(sin(pi/4), 1, 16, 13))
                run_s <= '1';
                wait on done_s until done_s = '0';
                run_s <= '0';
                wait on done_s until done_s = '1';

                -- Input: theta_internal = theta_current = -3*pi/4 =>
                -- curr_phase_s <= -3*pi/4
                -- norm_input_s <= sin(-3*pi/4)
                -- Output SHOULD be: 0
                curr_phase_s <= MINUS_3_PI_OVER_4_FX316_V;
                norm_input_s <= X"E95F";
                run_s <= '1';
                wait on done_s until done_s = '0';
                run_s <= '0';
                wait on done_s until done_s = '1';

                -- ------------------------
                -- REAL error CHECKING
                -- First round: pi/32 error in phase
                
                -- Input: theta_internal = 0; input_theta = pi/32 =>
                -- curr_phase_s <= 0
                -- norm_input_s <= sin(pi/32) = X"0323"
                -- Output SHOULD be: approx pi/32 (798 en decimal)
                curr_phase_s <= (others => '0');
                norm_input_s <= X"0323";
                run_s <= '1';
                wait on done_s until done_s = '0';
                run_s <= '0';
                wait on done_s until done_s = '1';
                -- Resultado REAL: 774.
                -- Error relativo: (798 - 774) / 798 = 0.0301

                wait;
        end process;

        clock : process
        begin
            clk_s <= '0';
            wait for CLOCK_PERIOD / 2;
            clk_s <= '1';
            wait for CLOCK_PERIOD / 2;
        end process clock;
end beh;
