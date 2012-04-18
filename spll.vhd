--------------------------------------------------------------------------------
-- *** Brief description ***
--
-- ALL-PLL (also known as 'spll') full design, using the amplitude loop and phase loop
--
--------------------------------------------------------------------------------
library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.all;
use WORK.COMMON.all;


entity spll is
     port (
          clk, sample, rst : in std_logic;
          in_signal : in std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
          phase, out_signal : out std_logic_vector(PIPELINE_WIDTH -1 downto 0);
          done : out std_logic);
end spll;


architecture alg of spll is
     type state_t is (ST_RST, -- State required for waiting for individual elements reset [ampl_loop
                              -- can take some time]; 1st part of reset states (see ST_WAIT_FOR_RST
                              -- also).
                      ST_WAIT_FOR_RST ,
                      ST_SAMPLE_WAIT,
                      ST_RUN);

     signal st : state_t;

     signal run_s, rst_s, ampl_done_s, ampl_done_pulsed_s, phase_done_s, done_pulser_en_s: std_logic;
     signal our_signal_s, norm_in_signal_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
begin

     ampl_loop_i : entity work.ampl_loop(alg)
          port map (
               clk => clk, run => run_s, rst => rst_s,
               in_signal => in_signal, our_signal => our_signal_s,
               norm_in_signal => norm_in_signal_s,
               done => ampl_done_s);

     done_pulser_i : entity work.done_pulser(beh)
          port map (
               clk => clk,
               en  => done_pulser_en_s,
               rst => rst,
               i   => ampl_done_s,
               o   => ampl_done_pulsed_s);
     
     phase_loop_i : entity work.phase_loop(alg)
          port map (
               clk => clk, run => ampl_done_pulsed_s, rst => rst_s,
               norm_input => norm_in_signal_s,
               phase => phase, norm_sin => our_signal_s,
               done => phase_done_s
               );

     
     state_ctrl : process(clk, sample, ampl_done_s, phase_done_s)
     begin
          if (rising_edge(clk)) then
               if (rst = '1') then
                    st <= ST_RST;
               else
                    case st is
                         when ST_RST =>
                              st <= ST_WAIT_FOR_RST;
                         when ST_WAIT_FOR_RST =>
                              if (ampl_done_s = '1' and phase_done_s = '1') then
                                   st <= ST_SAMPLE_WAIT;
                              else
                                   st <= ST_WAIT_FOR_RST;
                              end if;
                         when ST_SAMPLE_WAIT =>
                              if (sample = '0') then
                                   st <= ST_SAMPLE_WAIT;
                              else
                                   st <= ST_RUN;
                              end if;
                         when ST_RUN =>
                              if (phase_done_s = '0' or ampl_done_s = '0') then
                                   st <= ST_RUN;
                              else
                                   if (sample = '0') then
                                        st <= ST_SAMPLE_WAIT;
                                   else
                                        st <= ST_RUN;
                                   end if;
                              end if;
                    end case;
               end if;
          end if;
     end process;

     
     signal_gen : process(st, sample, phase_done_s, rst)
     begin
          case st is
               when ST_RST =>
                    done <= '0';
                    run_s <= '0';
                    rst_s <= '1';
                    done_pulser_en_s <= '0';
               when ST_WAIT_FOR_RST =>
                    done <= '0';
                    run_s <= '0';
                    rst_s <= '0';
                    done_pulser_en_s <= '0'; -- Avoid that the done rising edge to launch a run of
                                             -- the chained phase_loop during reset, as the done is
                                             -- not signaling the finish of a calculation but the
                                             -- finish of the reset operation.
               when ST_SAMPLE_WAIT =>
                    done <= '1';
                    run_s <= sample;
                    rst_s <= rst;
                    done_pulser_en_s <= '1';
               when ST_RUN =>
                    done <= ampl_done_s and phase_done_s;
                    run_s <= '0';
                    rst_s <= rst;
                    done_pulser_en_s <= '1';
               when others =>
                    done <= '0'; -- Should be '-'
                    run_s <= '0';
                    rst_s <= '0';
                    done_pulser_en_s <= '0';
                    report "INCORRECT STATE ON spll entity FSM" severity failure;
          end case;
     end process;

     out_signal <= our_signal_s;
end alg;
