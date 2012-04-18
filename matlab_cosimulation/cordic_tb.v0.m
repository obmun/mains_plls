function [iport, tnext] = cordic_tb_v0(oport, tnow, portinfo)
% CORDIC_TB  Test bench for Cordic entity
%  [IPORT,TNEXT] = MANCHESTER_DECODER(OPORT,TNOW,PORTINFO) -
%    Implements a test of the Cordic sin/cos seq element on the PLL code
%    (defined on cordic.vhd)
%
% For more information on the Cordic entity, take a look at the
% corresponding .vhd file
%
% This test bench does the following:
% 1) Sequentially, inputs all correct possible input angles [-pi, pi), and
% verifies correct calculacion of sin and cos
% 2) Randomly, selects all posible input angles and verifies generated sin
% and cosine
%
% == How to execute me ==
% 1) Load ModelSim from Matlab: 
%    >> vsim('socketsimulink', 4449)
% 2) Make sure cordic entity is compiled and available in the work library
% on ModelSim
% 3) Execute the testbench using the matlabtb function
%    >> matlabtb cordic -mfunc cordic_tb
%    

     function [clock_val, t_next_clock_change] = gen_clock_val(clock_freq)
          % GEN_CLOCK_VAL
          %
          % You should not change the clock_freq between executions

          persistent clock_period;

          persistent next_clk_event_t;
          persistent curr_clk_val;

          if (nargin == 0)
               % Reset clock process
               next_clk_event_t = [];
               curr_clk_val = [];
               return;
          end
     
          if (isempty(next_clk_event_t))
               % Initializing clk process
               clock_period = 1 / clock_freq;
          
               curr_clk_val = 0;
               clock_val = '0';
               next_clk_event_t = clock_period * 0.5;
               t_next_clock_change = next_clk_event_t;
          else
               if (curr_clk_val == 0)
                    curr_clk_val = 1;
                    clock_val = '1';
               else
                    curr_clk_val = 0;
                    clock_val = '0';
               end
               next_clk_event_t = next_clk_event_t + clock_period * 0.5;
               t_next_clock_change = next_clk_event_t;
          end
          
     end

% 0 -> RST generation
% 1 -> Input of angles for cosine calculation
persistent state;

persistent reset_state_data;

     function reset_state_entry_action()
          if (isempty(reset_state_data))
               reset_state_data = struct();
          end
          reset_state_data.
     end

     function reset_state_repeat_action()
     end

     function reset_state_exit_action()
     end

persistent next_clk_evt_t;

% global testisdone;
% This useful feature allows you to manually
% reset the plot by simply typing: > manchester_decoder
tnext = [];
iport = struct();

if (nargin == 0)
     % Do something if the user calls this manually without parameters
     return;
end

if exist('portinfo', 'var') == 1
     % == FIRST CALL TO TEST BENCH METHOD == %
    
     % Reset all the state related shit
     state = [];
     reset_state_data = [];
     next_clk_evt_t = [];
end

[clk_val, next_clk_evt_t] = gen_clock_val(20e6);
iport.clk = clk_val;

if isempty(state), %% First call
     state = 0;
     reset_state_entry_action();
else
     switch (state)
          case 0
               % -- "RESET" state transitions
               next_state = reset_state_decide_transition();
               switch (next_state)
                    case 0
                         % Nothing TO DO
                    case 1
                         values_state_entry_action();
               end
          case 1
               state = 2;
     end  
end

switch (state)
     case 0
          % -- "RESET" state action --
          iport.rst = '1';
     case 1
          % -- "
          iport.rst = '0';

end

% This approach is SHIT. I can become crazy before even starting to code
% the required FSM. I have to review my approach to the TB! ...

end


