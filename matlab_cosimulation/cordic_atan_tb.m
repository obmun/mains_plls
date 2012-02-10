function cordic_atan_tb(hdli_obj)
% CORDIC_ATAN_TB  Test bench for Cordic Atan entity
%  CORDIC_ATAN_TB(HDLI_OBJ) -
%    Implements a test of the Cordic seq working in vectoring mode element on the PLL code
%    (defined on cordic_atan.vhd.unconfig)
%
% For more information on the Cordic Atan entity, take a look at the
% corresponding .vhd file
%
% This test bench does the following:
% 1) Sequentially, inputs __many__ 'valid' (x, y) possible input pairs and
% verifies correct calculacion of the atan (that is, the vector angle) as
% well as its modulus [see code for why 'many' is used].
%
% This function makes use of an instance object, so make sure to instruct
% the EDA software to make use of it
%
% --- Test configuration ---
% You can configure this test by modifying the following code constants:
% - N_RADIUS_SAMPLES
% - N_ANGLE_SAMPLES

%%
rst = [0 '1'; 1 '0'];
run = [0 '0'; 1 '1'];

DEFAULT_CLOCK_FREQ = 1e6;

N_RADIUS_SAMPLES = 64;
N_ANGLE_SAMPLES = 64;

SIMULATE_TEST_END = false;
MAX_SAMPLE_NUMBER = 300;

done = false;

% Storage of input and output values is better to be done here, with
% persistent vars, instead of using the userdata object of the HDL instance
% object. It seems that too big information stored on the userdata field
% reduces amazingly the simulation speed!
persistent x_v;
persistent y_v;
persistent atan_v;
persistent mod_v;

%%
% if exist('portinfo', 'var') == 1
if (strcmp(hdli_obj.simstatus, 'Init'))
     % == Initialization of TEST BENCH METHOD == %
     ud = struct('width', -1, 'prec', -1, 'clock_freq', DEFAULT_CLOCK_FREQ, ...
          'n_samples', int32(0), 'sample_n', int32(0));
     
%      x_v = zeros(1, 3);
%      y_v = zeros(1, 3);
%      atan_v = zeros(1, 3);
%      mod_v = zeros(1, 3);
     
     arg_str_sz = size(hdli_obj.argument);
     % IMPORTANT NOTE
     % Matlab is SHIT, and it doesn't allow me to add variables dynamically
     % if I have a NESTED function!! Amazing!!
     eval(hdli_obj.argument(2:arg_str_sz(2) - 1));
     if (~exist('clock_freq', 'var'))
          error('CordicAtanTb:UseInstanceObj:BadCtorArgClockFreq', ...
               'Bad constructor arg to cordic_tb callback. Expecting ''clock_freq=value''.');
     else
          ud.clock_freq = clock_freq;
          disp(['cordic_atan_tb | clock_freq = ', num2str(clock_freq)]);
     end
     
     if (~exist('width', 'var'))
          error('CordicAtanTb:UseInstanceObj:BadCtorArgWidth', ...
               'Bad constructor arg to cordic_tb callback. Expecting ''width=value''.');
     else
          ud.width = int16(width);
          disp(['cordic_atan_tb | width = ', num2str(width)]);
     end
     
     if (~exist('prec', 'var'))
          error('CordicAtanTb:UseInstanceObj:BadCtorArgPrec', ...
               'Bad constructor arg to cordic_tb callback. Expecting ''prec=value''.');
     else
          ud.prec = int16(prec);
          disp(['cordic_atan_tb | prec = ', num2str(prec)]);
     end
     
     % -- Reserve vectors for the test results --
     % How many different inputs do we have? We have 2 input values with 16
     % bits each one => we have a total of 2^32 possible input
     % values!!!!!!!
     %
     % Such a high value of possible inputs cannot BE SIMULATED and TESTED
     % in a reasonable time!!
     %
     % So ... what we're going to do is to randomly "sample" the input
     % space:
     % - We randomly choose <n> different radius from > 0 to max_mod (given
     % pipeline)
     % - We randomly choose <m> different angles from 0 to 2PI
     % Both, m and n, are configurable on this function
     %
     % That means we end up having m * n different inputs and m * n
     % different results
     ud.n_samples = int32(N_RADIUS_SAMPLES * N_ANGLE_SAMPLES);
     CORDIC_GAIN = 0.607; % See any CORDIC description for more info
     MAX_RADIUS = 2^(width - prec - 1) * CORDIC_GAIN;
     radius_v = random('unif', 2^(-prec + 1), MAX_RADIUS, N_RADIUS_SAMPLES, 1);
     angle_v = random('unif', 0., 2.*pi - 0.0001, 1, N_ANGLE_SAMPLES);
     cos_v = cos(angle_v);
     sin_v = sin(angle_v);
     x_m = radius_v * cos_v;
     y_m = radius_v * sin_v;
     x_v = sfi(reshape(x_m, 1, ud.n_samples), width, prec);
     y_v = sfi(reshape(y_m, 1, ud.n_samples), width, prec);
     atan_v = zeros(1, ud.n_samples);
     mod_v = zeros(1, ud.n_samples);
     % plot(x_v, y_v, '.k');
     % axis equal;
     
     % Reset the gen_clock_val function
     gen_clock_val();
     
     hdli_obj.userdata = ud;
end

%%
[clock_val, t_next_clock_change, clk_cycle_n, rising] = gen_clock_val(hdli_obj.userdata.clock_freq);
rst_val = get_vector_sample(clk_cycle_n, rst);
run_val = get_vector_sample(clk_cycle_n, run);

hdli_obj.portvalues.clk = clock_val;
hdli_obj.portvalues.rst = rst_val;
hdli_obj.portvalues.run = run_val;

% Initially, set inputs to '0', so they don't get a 'U' state
if (clk_cycle_n == 0)
     hdli_obj.portvalues.x = repmat('0', 1, hdli_obj.userdata.width);
     hdli_obj.portvalues.y = repmat('0', 1, hdli_obj.userdata.width);
end

% cycle 0 is the one for the reset. Once I reach cycle 1, rst is already
% set to 0 and run set to 1
if (clk_cycle_n >= 1 && hdli_obj.portvalues.done == '1' && ~rising)
     % sample_n holds the sample number for the JUST CALCULATED VALUES.
     % That means that the input value on this cycle is for sample_n + 1
     % Initially sample_n is 0, meaning that "no value" has been
     % calculated. We use that value for identifying the "initial" sample
     sample_n = hdli_obj.userdata.sample_n;
     
     % == Store generated result values ==
     if (sample_n ~= 0)
          tmp = sfi(0, hdli_obj.userdata.width, hdli_obj.userdata.prec);
          tmp.bin = hdli_obj.portvalues.angle';
          atan_v(sample_n) = tmp.data;
          tmp.bin = hdli_obj.portvalues.modu';
          mod_v(sample_n) = tmp.data;
     end
     
     if ((SIMULATE_TEST_END && sample_n >= MAX_SAMPLE_NUMBER) || (sample_n >= hdli_obj.userdata.n_samples))
          % ==== TEST IS DONE ====
          disp(['cordic_atan_tb | Test done. Generated ', num2str(sample_n), ' samples']);
          done = true;
          
          if (~SIMULATE_TEST_END)
               assert(size(x_v, 2) == sample_n);
          end
          
          x_d_v = data(x_v);
          y_d_v = data(y_v);
          real_angle_v = atan2(y_d_v, x_d_v);
          real_mod_v = sqrt(x_d_v.^2 + y_d_v.^2);
          angle_abs_e_v = real_angle_v - atan_v;
          mod_abs_e_v = real_mod_v - mod_v;
               
          angle_mse = angle_abs_e_v * angle_abs_e_v';
          angle_mse = angle_mse/double(sample_n);
          mod_mse = mod_abs_e_v * mod_abs_e_v';
          mod_mse = mod_mse/double(sample_n);
               
          figure('Renderer', 'OpenGL');
          plot3(x_d_v, y_d_v, atan_v, '.r');
          hold on;
          plot3(x_d_v, y_d_v, real_angle_v, 'ok');
          axis equal;
          grid;
          legend('Calculated', 'Real');
          title('Calculated angle vs real one');
          
          figure('Renderer', 'OpenGL');
          plot3(x_d_v, y_d_v, mod_v, '.r');
          hold on;
          plot3(x_d_v, y_d_v, real_mod_v, 'ok');
          axis equal;
          grid;
          legend('Calculated', 'Real');
          title('Calculated modulus vs real one');
          disp(['cordic_atan_tb | Angle (atan2) MSE: ', num2str(angle_mse)]);
          disp(['cordic_atan_tb | Modulus MSE: ', num2str(mod_mse)]);
               
          % Store results on file
          [script_dirpath, ~, ~] = fileparts(which('cordic_atan_tb'));
          save_fpath = fullfile(script_dirpath, 'cordic_atan_tb_res.mat');
          save(save_fpath, ...
               'x_v', 'y_v', 'atan_v', 'mod_v');
     end
     
     % == Select input values ==
     if (sample_n < hdli_obj.userdata.n_samples)
          x_sfi = x_v(sample_n + 1);
          y_sfi = y_v(sample_n + 1);
          x = x_sfi.bin;
          y = y_sfi.bin;
     else
          x = repmat('0', 1, hdli_obj.userdata.width);
          y = repmat('0', 1, hdli_obj.userdata.width);
     end
     if (~done)
          hdli_obj.portvalues.x = x;
          hdli_obj.portvalues.y = y;
     end
     
     hdli_obj.userdata.sample_n = sample_n + 1;

end

if (~done)
     hdli_obj.tnext = t_next_clock_change;
else
end

end
