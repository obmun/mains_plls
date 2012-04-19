% Script for launching the 'sqrt' entity Matlab testbench
%
% This test makes use of the sqrt cosimulation wrapper entity (see
% sqrt_cosim_wrapper.vhd file). Make sure it's compiled and available on ModelSim work
% library. Related Modelsim project: sqrt_cosim_wrapper

make_sure_hdldaemon_is_running();

old_cwd = pwd;
% We're going to CD, so I need current .m path on the path so the rest of
% the cordic functions are found
saved_path = addpath(old_cwd);

cd(SQRT_MODELSIM_PROJECT_PATH);

if (~exist('freq', 'var'))
     freq = 10e6;
end
disp(['Using a clock in simulation with freq=', num2str(freq)]);

SQRT_CLK_SIGNAL_NAME = '/sqrt_cosim_wrapper/clk';
SQRT_DONE_SIGNAL_NAME = '/sqrt_cosim_wrapper/done';
SQRT_HARDCODED_WIDTH = 18;

period = 1./freq;
period_ns = ceil(period / 1e-9);
half_period_ns = ceil(0.5 * period / 1e-9);
clk_force_cmd = sprintf('force %s 0 0 ns, 1 %d ns -repeat %d ns', SQRT_CLK_SIGNAL_NAME, half_period_ns, period_ns);
% disp(['force_cmd = ', force_cmd]);

% Create a cell array of strings for holding the Modelsim cmds
i = 1;
cmds{i} = ['vsimmatlab work.', SQRT_ENTITY_NAME];
i = i + 1;
cmds{i} = ['set width_val ', num2str(SQRT_HARDCODED_WIDTH, '%d')];
i = i + 1;
cmds{i} = 'set prec_val [examine /sqrt_cosim_wrapper/sqrt_i/prec]';
i = i + 1;
% cmds{i} = ['matlabtb cordic -sensitivity ', CORDIC_CLK_SIGNAL_NAME, ' ', CORDIC_DONE_SIGNAL_NAME, ' -mfunc cordic_tb -socket 4449'];
cmds{i} = ['matlabtb ', SQRT_ENTITY_NAME, ' -mfunc sqrt_tb -use_instance_obj -socket 4449 -argument "', ...
     'clock_freq=', num2str(freq), ';', ...
     'width=$width_val;', ...
     'prec=$prec_val;', ...
     '"'];
i = i + 1;

vsim('tclstart', cmds);

path(saved_path);
cd(old_cwd);

clear clk_force_cmd;
clear cmds;
clear old_cwd;
clear saved_path;
