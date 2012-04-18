function [b, a] = sampler_block_init(gcb, f_s, in_w)
%SAMPLER_BLOCK_INIT Initialization function for the "sampler" block (masked
%subsystem)
%
% REQUIRED TOOLBOXES:
% 1) Signal processing toolbox
%
% Remember: for debugging, recover the "Sampler" block inside a Simulink
% system using:
%   sampler_block_fullpath = find_system(gcs, 'Name', 'Sampler');
% For using find_system under masked object, remember that you have to use
% the 'LookUnderMasks' option!
%   blks = find_system(sampler_block_fullpath, 'LookUnderMasks', 'all');

% Design the sampler antialiasing filter
order = 10;
stopband_min_reject = 60;
stopband_edge_freq = 0.5*f_s;
[z,p,k] = cheby2(order, stopband_min_reject, 2*pi*stopband_edge_freq, 's');
[b, a] = zp2tf(z, p, k);

% ==== Using the input port width for configuring the internal transfer
% function numerator ====
%
% The problem: the transfer function does not automatically adapt to the input
% vector
% The possible solution: to detect input width and set the numerator matrix
% according (just as a repetition of the single numerator vector)
%
% The aparent problem during implementation: it's impossible to get input port
% width before block is compiled and ... once block is compiled it's
% probably too late to change the transfer function coefs ...
%
% == More about the problem during implementation ==
%
% According to Matlab doc on masked subsystems, initialization commands for
% masked blocks in a model run when you:
% (all)
% * Update the diagram
% * Start simulation
% * Start code generation
% (specific)
% * Change any of the parameters that define the mask
% * ...
%
% That is ... the initialization commands are run BEFORE block is compiled
%
% For running code just after block compilation, you can use the StartFcn
% callback (I think it was called this way)
%
% == Code related to this non-working solution ==
% assert(strcmp(get_param([gcb '/in'], 'BlockType'), 'Inport'));
% assert(size(find_system(gcb, 'LookUnderMasks', 'all', 'BlockType', 'Inport'), 1) == 1);
% port_handles = get_param(gcb, 'PortHandles');
% in_dims = get_param(port_handles.Inport, 'CompiledPortDimensions');
%
% http://www.mathworks.es/support/solutions/en/data/1-17R1X/index.html?product=ML&solution=1-17R1X
% http://www.mathworks.de/matlabcentral/newsreader/view_thread/249093
%
% == SOLUTION 1 ==
% * OVERKILL!!!! *
% Add a block parameter specyfing the sampler width
%
% == SOLUTION 2 ==
% Use a for_each subsystem!!!

% Depending on input size, prepare a correct <b> matrix
% assert(in_w > 0);
% b_mat = repmat(b, in_w, 1);
% See == SOLUTION 1 == comment above

end

