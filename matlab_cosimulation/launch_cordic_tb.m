% Script for launching the Cordic Matlab testbench

make_sure_hdldaemon_is_running();

old_cwd = pwd;
% We're going to CD, so I need current .m path on the path so the rest of
% the cordic functions are found
saved_path = addpath(old_cwd);

cd(CORDIC_MODELSIM_PROJECT_PATH);

if (~exist('freq', 'var'))
     freq = 10e6;
end
disp(['Using a clock in simulation with freq=', num2str(freq)]);

CORDIC_CLK_SIGNAL_NAME = 'cordic/clk';
CORDIC_DONE_SIGNAL_NAME = '/cordic/done';
period = 1./freq;
period_ns = ceil(period / 1e-9);
half_period_ns = ceil(0.5 * period / 1e-9);
clk_force_cmd = sprintf('force %s 0 0 ns, 1 %d ns -repeat %d ns', CORDIC_CLK_SIGNAL_NAME, half_period_ns, period_ns);
% disp(['force_cmd = ', force_cmd]);

% Create a cell array of strings for holding the Modelsim cmds
i = 1;
cmds{i} = ['vsimmatlab ', CORDIC_ENTITY_NAME];
i = i + 1;
cmds{i} = 'set width_val [examine /width]'; % YES. This is "TCL"
i = i + 1;
cmds{i} = 'set prec_val [examine /prec]';
i = i + 1;
% cmds{i} = ['matlabtb cordic -sensitivity ', CORDIC_CLK_SIGNAL_NAME, ' ', CORDIC_DONE_SIGNAL_NAME, ' -mfunc cordic_tb -socket 4449'];
cmds{i} = ['matlabtb cordic -mfunc cordic_tb -use_instance_obj -socket 4449 -argument "', ...
     'clock_freq=', num2str(freq), ';', ...
     'width=$width_val;', ...
     'prec=$prec_val;', ...
     '"'];
i = i + 1;
% cordic_tb generates its own clock!
% cmds{i} = clk_force_cmd;
% i = i + 1;
% cmds{i} = 'run';
vsim('tclstart', cmds);

path(saved_path);
cd(old_cwd);

clear clk_force_cmd;
clear cmds;
clear old_cwd;
clear saved_path;
