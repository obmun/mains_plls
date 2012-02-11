function kcm_cosim_tb_cb(hdli_obj)
% KCM_COSIM_TB_CB  Callback function for the KCM testbench
%
% === Test configuration ===
%
% See associated "launch" function for configuration options
%
% === Required initialization parameters (-argument on matlabtb) ===
%
% * read_delay -> The delay, in seconds, between input change and output
% read
% * out_signal_name -> The signal which must be read on the TB entity
% (remember, we have various KCM instantiations simulatenously, each one
% usiung a different architecture)
% * width -> The PIPELINE width
% * prec -> The PIPELINE prec
%
% === Interchange file ===
% == Output ==
% out_v -> Vector of doubles

persistent in_v;
persistent out_m;
persistent n_sample;

%%
% if exist('portinfo', 'var') == 1
if (strcmp(hdli_obj.simstatus, 'Init'))
     % == Initialization of TEST BENCH METHOD == %
     ud = struct('width', -1, 'prec', -1, 'read_delay', 1e-9, ...
          'sample_n', int32(0));
     
     arg_str_sz = size(hdli_obj.argument);
     eval(hdli_obj.argument(2:arg_str_sz(2) - 1));
     
     if (~exist('read_delay', 'var'))
          error('KCMCosimTBCb:UseInstanceObj:BadCtorArg:NoReadDelay', ...
               'Bad constructor arg to kcm_cosim_tb_cb callback. Expecting ''read_delay=value''.');
     else
          ud.read_delay = read_delay;
          disp(['kcm_cosim_tb_cb | read_delay = ', num2str(read_delay)]);
     end
     
     if (~exist('width', 'var'))
          error('KCMCosimTBCb:UseInstanceObj:BadCtorArg:NoWidth', ...
               'Bad constructor arg to kcm_cosim_tb_cb callback. Expecting ''width=value''.');
     else
          ud.width = int16(width);
          disp(['kcm_cosim_tb_cb | width = ', num2str(width)]);
     end
     
     if (~exist('prec', 'var'))
          error('KCMCosimTBCb:UseInstanceObj:BadCtorArg:NoPrec', ...
               'Bad constructor arg to kcm_cosim_tb_cb callback. Expecting ''prec=value''.');
     else
          ud.prec = int16(prec);
          disp(['kcm_cosim_tb_cb | prec = ', num2str(prec)]);
     end
     
     if (~exist('out_signal_name', 'var'))
          error('KCMCosimTBCb:UseInstanceObj:BadCtorArg:NoOutSignalName', ...
               'Bad constructor arg to kcm_cosim_tb_cb callback. Expecting ''out_signal_name=value''.');
     else
          ud.out_signal_name = out_signal_name;
          disp(['kcm_cosim_tb_cb | out_signal_name = ', num2str(prec)]);
     end
     
     if (~exist('iteration', 'var'))
          error('KCMCosimTBCb:UseInstanceObj:BadCtorArg:NoIteration', ...
               'Bad constructor arg to kcm_cosim_tb_cb callback. Expecting ''iteration=value''.');
     else
          ud.iteration = iteration;
          disp(['kcm_cosim_tb_cb | iteration # = ', num2str(iteration)]);
     end
     
     hdli_obj.userdata = ud;
          
     % -- Read the big vars from the launcher on the interchange file --
     [script_dirpath, ~, ~] = fileparts(which('kcm_cosim_tb_cb'));
     interchange_fpath = fullfile(script_dirpath, KCM_COSIM_TB_INTERCHANGE_FNAME);
     f_contents = load(interchange_fpath);
     if (~isfield(f_contents, 'in_v'))
          error('KCMCosimTBCb:InterchangeFile:NoInVField', ...
               'Bad interchange file. Missing ''in_v'' field');
     end
     in_v = f_contents.in_v;
     if (~isfield(f_contents, 'out_m'))
          % First iteration
          assert(iteration == 1);
          % -- Reserve vector for this iteration test results --
          out_m = zeros(1, size(in_v, 2));
     else
          % Read previous results for appending the data to the results
          % matrix
          out_m = f_contents.out_m;
          out_m = [out_m; zeros(1, size(in_v, 2))];
     end
     
     % -- Initialize other things ... --
     n_sample = 0;
end

%% Signal generation and capture

% REMEMBER: n_sample is counting starting at 0

if (n_sample > 0)
     % Store output value
     tmp = sfi(0, hdli_obj.userdata.width, hdli_obj.userdata.prec);
     out_bit_v = hdli_obj.portvalues.(hdli_obj.userdata.out_signal_name);
     tmp.bin = out_bit_v';
     out_m(hdli_obj.userdata.iteration, n_sample) = tmp.data;
end

if (n_sample == size(in_v, 2))
     % === DONE! ===
     
     % Save output vector to interchange file
     [script_dirpath, ~, ~] = fileparts(which('kcm_cosim_tb_cb'));
     interchange_fpath = fullfile(script_dirpath, KCM_COSIM_TB_INTERCHANGE_FNAME);
     save(interchange_fpath, 'out_m', '-append'); % We have to 'append' the new data. Otherwise, in_v gets replaced
     
     % Avoid further processing
     return; 
end

i_sfi = in_v(n_sample + 1);
hdli_obj.portvalues.i = i_sfi.bin;
n_sample = n_sample + 1;

hdli_obj.tnext = hdli_obj.tnow + hdli_obj.userdata.read_delay;

end


