function bin_angles = atan_lut_calc(width, prec)
i = 0;
disp(sprintf('Starting calc of Cordic angles for %d bits word, with %d bits of precision', width, prec));
while 1
    angle_rad = atan(2^(-i));
    angle_deg = 180 * angle_rad / pi;
    fi_obj = fi(angle_rad, 1, width, prec, 'RoundMode', 'Nearest');
    if (fi_obj.int == 0)
        disp('Stopping - reached max precision!');
        break;
    end
    disp(sprintf('%d - %fº - %s', i, angle_deg, dec(fi_obj)));
    if (i == 0)
        angle_bin = bin(fi_obj);
    else
        angle_bin = [angle_bin; bin(fi_obj)];
    end
    i = i + 1;
end

bin_angles = angle_bin;