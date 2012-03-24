--------------------------------------------------------------------------------
-- Revision:
-- Revision 0.01 - File Created
-- 
--------------------------------------------------------------------------------
library IEEE;
library WORK;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use WORK.COMMON.all;


entity spll is
     port (
          clk, sample, rst : in std_logic;
          in_signal : in std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
          phase, out_signal : out std_logic_vector(PIPELINE_WIDTH -1 downto 0);
          done : out std_logic);
end spll;


architecture alg of spll is
     type state_t is (ST_SAMPLE_WAIT, ST_RUN);

     signal st : state_t := ST_SAMPLE_WAIT;

     signal run_s, ampl_done_s, phase_done_s: std_logic;
     signal our_signal_s, norm_in_signal_s : std_logic_vector(PIPELINE_WIDTH - 1 downto 0);
begin

     ampl_loop_i : entity work.ampl_loop(alg)
          port map (
               clk => clk, run => ampl_done_s, rst => rst,
               in_signal => in_signal, our_signal => our_signal_s,
               norm_in_signal => norm_in_signal_s,
               done => phase_done_s
               );

     phase_loop_i : entity work.phase_loop(alg)
          port map (
               clk => clk, run => run_s, rst => rst,
               norm_input => norm_in_signal_s,
               phase => phase, norm_sin => our_signal_s,
               done => ampl_done_s
               );

     state_ctrl : process(clk)
     begin
          if (rising_edge(clk)) then
               if (rst = '1') then
                    st <= ST_SAMPLE_WAIT;
               else
                    case st is
                         when ST_SAMPLE_WAIT =>
                              if (sample = '0') then
                                   st <= ST_SAMPLE_WAIT;
                              else
                                   st <= ST_RUN;
                              end if;
                         when ST_RUN =>
                              if (phase_done_s = '0') then
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

     signal_gen : process(st, sample, phase_done_s)
     -- I need to control:
     -- * run_s
     -- * done
     begin
          case st is
               when ST_SAMPLE_WAIT =>
                    done <= '1';
                    run_s <= sample;
               when ST_RUN =>
                    done <= phase_done_s;
                    run_s <= phase_done_s and sample;
          end case;
     end process;

     out_signal <= our_signal_s;
end alg;
