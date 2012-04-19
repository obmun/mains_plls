function sqrt_tb(hdli_obj)
% SQRT_TB  Test bench for sqrt entity
%  SQRT_TB(HDLI_OBJ) -
%    Implements the callback function for a test of the sqrt seq element on the PLL code
%    (defined on sqrt.vhd)
%
% This is a Simulink simulation callback which gets executed on Matlab and
% takes care of generating all block inputs and storing and processing all
% block outputs. It was copied from the original one developed for the
% CORDIC Simulink based tb
%
% For more information on the 'sqrt' entity, take a look at the
% corresponding .vhd file or the PFC doc
%
% This test bench does the following:
% 1) Sequentially, a uniform set of random numbers on the range allowed by
% the pipeline reported by the entity being simulated
% 2) [TODO] Randomly, selects all posible input angles and verifies generated sin
% and cosine
%
% This function makes use of an instance object, so make sure to instruct
% the EDA software to make use of it
%
% == Execution ==
% Make use of the launch_sqrt_tb script for automation of ModelSim
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

% SIMULATE_TEST_END = false;
% SAMPLES_FOR_TEST_END = 256;
N_RANDOM_NUMBERS = 4096;

done = false;

%%
% if exist('portinfo', 'var') == 1
if (strcmp(hdli_obj.simstatus, 'Init'))
     disp('sqrt_tb | Initializing');
     
     % == Initialization of TEST BENCH METHOD == %
     ud = struct('width', -1, 'prec', -1, 'clock_freq', DEFAULT_CLOCK_FREQ, ...
          'in_v', zeros(1, 3), 'sqrt_v', zeros(1, 3), ...
          'sample_n', int32(1)); % Initialization of sample_n
     
     arg_str_sz = size(hdli_obj.argument);
     
     eval(hdli_obj.argument(2:arg_str_sz(2) - 1));
     if (~exist('clock_freq', 'var'))
          error('SQRTTb:UseInstanceObj:BadCtorArgClockFreq', ...
               'Bad constructor arg to sqrt_tb callback. Expecting ''clock_freq=value''.');
     else
          ud.clock_freq = clock_freq;
          disp(['sqrt_tb | clock_freq = ', num2str(clock_freq)]);
     end
     
     if (~exist('width', 'var'))
          error('SQRTTb:UseInstanceObj:BadCtorArgWidth', ...
               'Bad constructor arg to sqrt_tb callback. Expecting ''width=value''.');
     else
          ud.width = int16(width);
          disp(['sqrt_tb | width = ', num2str(width)]);
     end
     
     if (~exist('prec', 'var'))
          error('SQRTTb:UseInstanceObj:BadCtorArgWidth', ...
               'Bad constructor arg to cordic_tb callback. Expecting ''prec=value''.');
     else
          ud.prec = int16(prec);
          disp(['sqrt_tb | prec = ', num2str(prec)]);
     end
     
     % Reserve vectors for the test results
     ud.sqrt_v = zeros(1, N_RANDOM_NUMBERS);
     % Prepare the input values
     % int_in_v = randi([-(2^(width - 1)), 2^(width - 1) - 1], 1, N_RANDOM_NUMBERS);
     int_in_v = randi([0, 2^(width - 1) - 1], 1, N_RANDOM_NUMBERS);
     ud.in_v = sfi(zeros(1, N_RANDOM_NUMBERS), width, prec);
     tmp_sfi = sfi(0, width, prec);
     for i = 1:N_RANDOM_NUMBERS
          tmp_sfi.int = int_in_v(i);
          ud.in_v(i) = tmp_sfi;
     end
     
     % Reset the gen_clock_val function
     gen_clock_val();
     
     hdli_obj.userdata = ud;
     
     disp(['sqrt_tb | Simulating ', num2str(N_RANDOM_NUMBERS), ' random uniform input values covering the pipeline ...']);
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
     sample_n = hdli_obj.userdata.sample_n;
     not_first_sample = isfield(hdli_obj.userdata, 'not_first_sample');
     % Store last input and generated sqrt value
     if (not_first_sample)
          tmp = sfi(0, hdli_obj.userdata.width, hdli_obj.userdata.prec);
          tmp.bin = hdli_obj.portvalues.o';
          % Verify error is zero
          assert(hdli_obj.portvalues.error_p == '0',...
               'sqrt_tb | Failure: sqrt entity error_p is set!');
          hdli_obj.userdata.sqrt_v(sample_n) = tmp.data;
          hdli_obj.userdata.sample_n = sample_n + 1;
     end
     
     if (not_first_sample)
          % if ((SIMULATE_TEST_END && sample_n >= SAMPLES_FOR_TEST_END) || (sample_n == N_RANDOM_NUMBERS))
          % ^^^ No need for test simulation, as we can choose the # of
          % input samples
          if (sample_n == N_RANDOM_NUMBERS)
               % TEST IS DONE
               disp('sqrt_tb | Test done.');
               done = true;
               
               %% GENERATING RESULTS
               % in_v = hdli_obj.userdata.in_v;
               real_sqrt_v = sqrt(double(hdli_obj.userdata.in_v));
               % sqrt_v = hdli_obj.userdata.sqrt_v;
               sqrt_abs_e_v = real_sqrt_v - double(hdli_obj.userdata.sqrt_v);
               in_sqrt_err_mat = [double(hdli_obj.userdata.in_v); double(hdli_obj.userdata.sqrt_v); sqrt_abs_e_v];
               sorted_mat = sortrows(in_sqrt_err_mat');
               sorted_mat = sorted_mat';
               in_v = sorted_mat(1, :);
               sqrt_v = sorted_mat(2, :);
               sqrt_abs_e_v = sorted_mat(3, :);
               
               sqrt_mse = sqrt_abs_e_v * sqrt_abs_e_v';
               sqrt_mse = sqrt_mse/double(sample_n);
               
               figure;
               subplot(2, 1, 1);
               plot(in_v, sqrt_v);
               title('Generated sqrt');
               subplot(2, 1, 2);
               plot(in_v, sqrt_abs_e_v);
               title('SQRT abs error');
               disp(['sqrt_tb | MSE: ', num2str(sqrt_mse)]);
               
               % Store results on file
               [script_dirpath, ~, ~] = fileparts(which('sqrt_tb'));
               save_fpath = fullfile(script_dirpath, 'sqrt_tb_res.mat');
               save(save_fpath, ...
                    'in_v', 'sqrt_v');
          end
     end
     if (not_first_sample)
          if (sample_n + 1 <= N_RANDOM_NUMBERS)
               val = hdli_obj.userdata.in_v(sample_n + 1);
          else
               val = sfi(0, hdli_obj.userdata.width, hdli_obj.userdata.prec);
          end
     else
          % First sample
          val = hdli_obj.userdata.in_v(sample_n);
          hdli_obj.userdata.not_first_sample = true;
     end
     hdli_obj.portvalues.i = val.bin;
else
     
end

if (~done)
     hdli_obj.tnext = t_next_clock_change;
else
end

end
