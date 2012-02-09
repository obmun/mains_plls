function [clock_val, t_next_clock_change, clk_cycle_, rising] = gen_clock_val(clock_freq)
%GEN_CLOCK_VAL Summary of this function goes here
%   You should not change the clock_freq between executions
%                                               _
% clk_cycle_ -> The current clk cycle number. _| |_
%               The clk_cycle number is _changed_ at the falling edge
% rising -> A boolean value. If true, that means that generated value
%           creates a rising edge; if false, it's a falling edge.

persistent clock_period;

persistent next_clk_event_t;
persistent clk_cycle;
persistent curr_clk_val;

if (nargin == 0)
     % Reset clock process
     clear clk_cycle;
     clear next_clk_event_t;
     clear curr_clk_val;
     return;
end
     
if (isempty(next_clk_event_t))
     % Initializing clk process
     clock_period = 1 / clock_freq;
     clk_cycle = 0;
          
     curr_clk_val = 0;
     clock_val = '0';
     rising = false;
     next_clk_event_t = clock_period * 0.5;
     t_next_clock_change = next_clk_event_t;
     clk_cycle_ = clk_cycle;
else
     if (curr_clk_val == 0)
          % Rigins edge
          curr_clk_val = 1;
          clock_val = '1';
          rising = true;
     else
          curr_clk_val = 0;
          clock_val = '0';
          clk_cycle = clk_cycle + 1;
          rising = false;
     end
     next_clk_event_t = next_clk_event_t + clock_period * 0.5;
     t_next_clock_change = next_clk_event_t;
     clk_cycle_ = clk_cycle;
end


