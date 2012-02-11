function [min, max] = min_n_max_pipeline_values(width, prec)
%MIN_N_MAX_PIPELINE_VALUES Returns the min and max possible values on a
%fixed point signed pipelined, defined by a width and a number of precision
%bits
%   Detailed explanation goes here

tmp_v = sfi(0, width, prec);
c_v = repmat('1', 1, width);
c_v(1) = '0';
tmp_v.bin = c_v;
max = tmp_v.double;
c_v = repmat('0', 1, width);
c_v(1) = '1';
tmp_v.bin = c_v;
min = tmp_v.double;

end

