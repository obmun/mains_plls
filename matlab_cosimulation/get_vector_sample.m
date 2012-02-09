function [sample, out_of_bounds] = get_vector_sample(clk_cycle, values)
%GET_VECTOR_SAMPLE Retrieves a sample from the given 'values' vector
%   A 'values vector' is a 2 columnn matrix were the first column is the
%   clk_cycle for the second column value
%
% clk_cycle -> The current clock cycle #. Starts at 0.

assert(clk_cycle >= 0);

values_s = size(values);
assert(values_s(1) > 0);
assert(values_s(2) == 2);
if clk_cycle > values(values_s(1), 1)
     sample = values(values_s(1), 2);
     out_of_bounds = true;
elseif clk_cycle < values(1, 1)
     sample = values(1, 2);
     out_of_bounds = true;
else
     first_idx_clk = values(1, 1);
     sample = values(1 + (clk_cycle - first_idx_clk), 2);
     out_of_bounds = false;
end

end

