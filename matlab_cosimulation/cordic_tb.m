function cordic_tb(hdli_obj)
% CORDIC_TB  Test bench for Cordic entity
%  CORDIC_TB(HDLI_OBJ) -
%    Implements a test of the Cordic sin/cos seq element on the PLL code
%    (defined on cordic.vhd)
%
% This is a Simulink simulation callback which gets executed on Matlab and
% takes care of generating all block inputs and storing and processing all
% block outputs.
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
% This function makes use of an instance object, so make sure to instruct
% the EDA software to make use of it
%
% == Execution ==
% Make use of the launch_cordic_tb script for automation of ModelSim
% launch and project loading.
%
% Once ModelSim has been launched, issue a "run -all" command and wait (go for a walk or drink a few coffees; it takes time).
% This callback takes care of ending the simulation once all input values
% have been tested.
%
% == TODO ==
% * Implement the 2nd part (the random part). Really necesary?

%%
rst = [0 '1'; 1 '0'];
run = [0 '0'; 1 '1'];

DEFAULT_CLOCK_FREQ = 1e6;

SIMULATE_TEST_END = false;
MAX_SAMPLE_NUMBER = 256;

done = false;

%%
% if exist('portinfo', 'var') == 1
if (strcmp(hdli_obj.simstatus, 'Init'))
     disp('cordic_tb | Initializing');
     
     % == Initialization of TEST BENCH METHOD == %
     ud = struct('width', -1, 'prec', -1, 'clock_freq', DEFAULT_CLOCK_FREQ, ...
          'angles_v', zeros(1, 3), 'cos_v', zeros(1, 3), 'sin_v', zeros(1, 3), ...
          'sample_n', int32(1));
     
     arg_str_sz = size(hdli_obj.argument);
     % IMPORTANT NOTE
     % Matlab is SHIT, and it doesn't allow me to add variables dynamically
     % if I have a NESTED function!! Amazing!!
     eval(hdli_obj.argument(2:arg_str_sz(2) - 1));
     if (~exist('clock_freq', 'var'))
          error('CordicTb:UseInstanceObj:BadCtorArgClockFreq', ...
               'Bad constructor arg to cordic_tb callback. Expecting ''clock_freq=value''.');
     else
          ud.clock_freq = clock_freq;
          disp(['cordic_tb | clock_freq = ', num2str(clock_freq)]);
     end
     
     if (~exist('width', 'var'))
          error('CordicTb:UseInstanceObj:BadCtorArgWidth', ...
               'Bad constructor arg to cordic_tb callback. Expecting ''width=value''.');
     else
          ud.width = int16(width);
          disp(['cordic_tb | width = ', num2str(width)]);
     end
     
     if (~exist('prec', 'var'))
          error('CordicTb:UseInstanceObj:BadCtorArgWidth', ...
               'Bad constructor arg to cordic_tb callback. Expecting ''width=value''.');
     else
          ud.prec = int16(prec);
          disp(['cordic_tb | prec = ', num2str(prec)]);
     end
     
     % Reserve vectors for the test results
     % 2^width: we now this is not true, but it's a safe max value of different
     % angles generated
     ud.angles_v = zeros(1, 2^width);
     ud.cos_v = zeros(1, 2^width);
     ud.sin_v = zeros(1, 2^width);
     
     % Reset the gen_clock_val function
     gen_clock_val();
     
     hdli_obj.userdata = ud;
     
     disp('cordic_tb | Simulating input angles on [0, pi] and [-pi, 0) ranges ...');
end

%%
[clock_val, t_next_clock_change, clk_cycle_n, rising] = gen_clock_val(hdli_obj.userdata.clock_freq);
rst_val = get_vector_sample(clk_cycle_n, rst);
run_val = get_vector_sample(clk_cycle_n, run);

hdli_obj.portvalues.clk = clock_val;
hdli_obj.portvalues.rst = rst_val;
hdli_obj.portvalues.run = run_val;

% cycle 0 is the one for the reset. Once I reach cycle 1, rst is already
% set to 0 and run set to 1
if (clk_cycle_n >= 1 && hdli_obj.portvalues.done == '1' && ~rising)
     have_last_angle = isfield(hdli_obj.userdata, 'last_angle');
     % Store last angle and generated sin and cos values
     sample_n = hdli_obj.userdata.sample_n;
     if (have_last_angle)
          last_angle = hdli_obj.userdata.last_angle;
          tmp = sfi(0, hdli_obj.userdata.width, hdli_obj.userdata.prec);
          hdli_obj.userdata.angles_v(sample_n) = last_angle.data;
          tmp.bin = hdli_obj.portvalues.sin';
          hdli_obj.userdata.sin_v(sample_n) = tmp.data;
          tmp.bin = hdli_obj.portvalues.cos';
          hdli_obj.userdata.cos_v(sample_n) = tmp.data;
          hdli_obj.userdata.sample_n = sample_n + 1;
     end
     
     % Generate angle value
     if (~have_last_angle)
          % First angle
          angle = gen_angle_val(hdli_obj.userdata.width, hdli_obj.userdata.prec);
     else
          angle = gen_angle_val(hdli_obj.userdata.width, hdli_obj.userdata.prec, hdli_obj.userdata.last_angle);
     end
     
     if (have_last_angle)
          if ((SIMULATE_TEST_END && sample_n >= MAX_SAMPLE_NUMBER) || (angle.data >= 0 && hdli_obj.userdata.last_angle < 0))
               % TEST IS DONE
               disp(['cordic_tb | Test done. Generated ', num2str(sample_n), ' samples']);
               done = true;
               
               angles_v = hdli_obj.userdata.angles_v(1:sample_n);
               real_cos_v = cos(angles_v);
               real_sin_v = sin(angles_v);
               cos_v = hdli_obj.userdata.cos_v(1:sample_n);
               sin_v = hdli_obj.userdata.sin_v(1:sample_n);
               cos_abs_e_v = real_cos_v - cos_v;
               sin_abs_e_v = real_sin_v - sin_v;
               angle_cos_sin_errs_mat = [angles_v; cos_v; sin_v; cos_abs_e_v; sin_abs_e_v];
               sorted_mat = sortrows(angle_cos_sin_errs_mat');
               sorted_mat = sorted_mat';
               angles_v = sorted_mat(1, :);
               cos_v = sorted_mat(2, :);
               sin_v = sorted_mat(3, :);
               cos_abs_e_v = sorted_mat(4, :);
               sin_abs_e_v = sorted_mat(5, :);
               
               cos_mse = cos_abs_e_v * cos_abs_e_v';
               cos_mse = cos_mse/double(sample_n);
               sin_mse = sin_abs_e_v * sin_abs_e_v';
               sin_mse = sin_mse/double(sample_n);
               
               figure;
               subplot(2, 2, 1);
               plot(angles_v, sin_v);
               title('Generated sin');
               subplot(2, 2, 2);
               plot(angles_v, cos_v);
               title('Generated cos');
               subplot(2, 2, 3);
               plot(angles_v, sin_abs_e_v);
               title('Sin abs error');
               subplot(2, 2, 4);
               plot(angles_v, cos_abs_e_v);
               title('Cos abs error');
               disp(['cordic_tb | Cos MSE: ', num2str(cos_mse)]);
               disp(['cordic_tb | Sin MSE: ', num2str(sin_mse)]);
               
               % Store results on file
               [script_dirpath, ~, ~] = fileparts(which('cordic_tb'));
               save_fpath = fullfile(script_dirpath, 'cordic_tb_res.mat');
               save(save_fpath, ...
                    'angles_v', 'cos_v', 'sin_v');
          end
     end
     hdli_obj.userdata.last_angle = angle;
     hdli_obj.portvalues.angle = angle.bin;
else
     
end

if (~done)
     hdli_obj.tnext = t_next_clock_change;
else
end

end
