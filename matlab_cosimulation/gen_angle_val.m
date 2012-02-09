function angle = gen_angle_val(width, prec, varargin)
     
assert(isinteger(width));
assert(isinteger(prec));

if (size(varargin, 2) == 0)
     % First iteration
     angle = sfi(0, width, prec);
else
     last_val = varargin{1};
     assert(strcmp(class(last_val), 'embedded.fi'));
     last_val.int = last_val.int + 1;
     if (last_val.data >= pi)
          last_val = sfi(-pi, width, prec);
     end
     angle = last_val;
end

end