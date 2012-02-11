function launch_kcm_tb()
% LAUNCH_KCM_TB  "Special" test bench launch function
%  LAUNCH_KCM_TB() -
%    Implements a "complex" launch of the KCM Matlab testbench (defined on kcm.vhd)
%
% ==== Why do we say this is a complex launch? ====
%
% The other testbench 'launch's are really no more than a small script for
% automating the launching of the HDL Daemon, ModelSim connected to Matlab
% and correctly launching the vsim command inside ModelSim, also connected to
% Matlab.
%
% This one is more complex. It takes care of looping, restarting the
% simulation MULTIPLE TIMES, each with a different mapping of a certain KCM
% generic parameter: the constant value.

% The testing space is VERY BIG: 2^pipeline_width * 2^pipeline_width, as we
% have 2 different DOFs: 1) the constant of the KCM, 2) the input which
% gets multiplied.
%
% With 16 bits pipeline, that means we have something like 4000e6 different
% values, which is a quantity which cannot get simulated on a reasonable
% time.
%
% Therefore, as we do with other tests, we also randomly pick samples on
% the input space, up to a certain value we choose. See N_CONSTANT_SAMPLES
% as well as N_INPUT_SAMPLES "constants" on code.
%
% Remember that the KCM is a combinational element, and therefore we don't
% need a clock. We use the GIVEN freq. as a _DELAY_ before sampling KCM
% output once a new input is passed.
%
% ==== Saved results ====
%
% == k_v ==
% Vector with the different constant values simulated (sfi format)
%
% == i_v ==
% Vector with the input values for the multiplier (also in sfi format)
%
% == out_m ==
% Output matrix with the multiplication results (double format, converted
% from the sfi output). Each row 'm' has the output for the 'm'th constant,
% and all the different input values. That is: M is m x n, where m =
% size(k_v) and n = size(i_v)
%

%% Definition of some constants

PIPELINE_WIDTH = 16;
PIPELINE_PREC = 12;

N_CONSTANT_SAMPLES = 64;
N_INPUT_SAMPLES = 128;

% See kcm_cosim_tb.vhd for the possible instances / architectures, and the
% connected output signals
KCM_OUT_PORT_NAME = 'o_struct_mm';
CONSTANT_VALUE_GENERIC_NAME = 'tb_k_g';

%% Calculation of (partial) input space

[pipe_min, pipe_max] = min_n_max_pipeline_values(PIPELINE_WIDTH, PIPELINE_PREC);
k_v = random('unif', pipe_min, pipe_max, 1, N_CONSTANT_SAMPLES);
k_v = sort(k_v);
k_v = sfi(k_v, PIPELINE_WIDTH, PIPELINE_PREC);
in_v = random('unif', pipe_min, pipe_max, 1, N_INPUT_SAMPLES);
in_v = sort(in_v);
in_v = sfi(in_v, PIPELINE_WIDTH, PIPELINE_PREC);

%% Basic preparation of simulation

make_sure_hdldaemon_is_running();

% Before changing the folder, prepare the interchange and results files name
[script_dirpath, ~, ~] = fileparts(which('launch_kcm_tb'));
interchange_fpath = fullfile(script_dirpath, KCM_COSIM_TB_INTERCHANGE_FNAME);
results_fpath = fullfile(script_dirpath, KCM_COSIM_TB_RESULTS_FNAME);

old_cwd = pwd;
% We're going to CD, so I need current .m path on the path so the rest of
% the cordic functions are found
saved_path = addpath(old_cwd);
cd(KCM_COSIM_TB_MODELSIM_PROJECT_PATH);

if (~exist('freq', 'var'))
     freq = 10e6;
end
delay = 1/freq;
disp(['Using a delay before output read of ', num2str(delay)]);

%% Save into _interchange_file_ those big vars that the CB function needs
save(interchange_fpath, ...
     'in_v');

%% Looping all over the different constants that are going to get tested, creating a cell array of strings for holding ALL the Modelsim cmds

% Yes, we're going to have a LOT of cmds (n_cmds_per_exec *
% n_of_constants!)

cmds = cell(0);
j = 1;
for i = 1:size(k_v, 2)
     k = k_v(i);
     k = k.double;
     cmds{j} = ['vsimmatlab work.', KCM_COSIM_TB_ENTITY_NAME, ' -G/', KCM_COSIM_TB_ENTITY_NAME, '/', CONSTANT_VALUE_GENERIC_NAME, '=', num2str(k, '%.20f')];
     j = j + 1;
     cmds{j} = ['matlabtb ', KCM_COSIM_TB_ENTITY_NAME, ' -mfunc kcm_cosim_tb_cb -use_instance_obj -socket ', num2str(HDL_DAEMON_PORT), ' -argument "', ...
          'read_delay=', num2str(delay), ';', ...
          'out_signal_name=''', KCM_OUT_PORT_NAME, ''';', ...
          'width=', num2str(PIPELINE_WIDTH), ';', ...
          'prec=', num2str(PIPELINE_PREC), ';', ...
          'iteration=', num2str(i), ';', ...
          '"'];
     j = j + 1;
     cmds{j} = 'run -all';
     j = j + 1;
     if (i == size(k_v, 2))
          % In the last vsim call, I must signal Matlab that I have
          % finished. The notifyMatlabServer call has to be made from
          % inside vsim!
          cmds{j} = ['notifyMatlabServer 5 -socket ', num2str(HDL_DAEMON_PORT)];
          j = j + 1;
     end
     cmds{j} = 'quit -sim';
     j = j + 1;
end
cmds{j} = 'quit';
j = j + 1;
vsim('tclstart', cmds, 'runmode', 'CLI');

path(saved_path);
cd(old_cwd);

disp('launch_kcm_tb | Waiting for simulation to finish ...');
while (waitForHdlClient(10, 5) < 0)
end

% === Read results and prepare data ===
disp('launch_kcm_tb | Preparing results ...');

interchange = load(interchange_fpath);
assert(isfield(interchange, 'out_m'));
out_m = interchange.out_m;
assert(size(out_m, 1) == size(k_v, 2));
assert(size(out_m, 2) == size(in_v, 2));
in_d_v = data(in_v);
k_d_v = data(k_v);
real_out_m = k_d_v' * in_d_v;
real_out_m = max(real_out_m, pipe_min);
real_out_m = min(real_out_m, pipe_max);
abs_err_m = real_out_m - out_m;
sq_abs_err_m = abs_err_m .* abs_err_m;
mse = sum(sum(sq_abs_err_m)) / (N_CONSTANT_SAMPLES * N_INPUT_SAMPLES);
max_sq_abs_err = max(max(sq_abs_err_m));

disp(['launch_kcm_tb | Total MSE: ', num2str(mse)]);
disp(['              | Max squared abs err: ', num2str(max_sq_abs_err)]);

% Save data to results file
save(results_fpath, 'k_v', 'in_v', 'out_m');

% Prepare a few visual results
% Mesh -> The _optimal_ output, as obtained using matlab
% Faces (surface) -> The _real_ output from the KCM
% If Mesh is coincident with the surface, everything is OK :)
% (the correct way of verifying if everything is OK is checking the MSE)
figure('Renderer', 'OpenGL');
surf(in_d_v, k_d_v, out_m, 'EdgeColor', 'none');
hold on;
surf(in_d_v, k_d_v, real_out_m, 'EdgeColor', [0 0 0], 'FaceColor', 'none');

end