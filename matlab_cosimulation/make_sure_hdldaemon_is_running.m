function make_sure_hdldaemon_is_running()
%MAKE_SURE_HDLDAEMON_IS_RUNNING Takes care of loading the Matlab hdldaemon
%in case it's off
%   Call this method whenever you need to make sure the hdldaemon is
%   running. Takes care of starting the daemon, with communication thru
%   socket on port 4449

running = sum(size(hdldaemon('status')));

res = 0;
if (running == 0)
     res = hdldaemon('socket', 4449, 'time', 'sec');
end
if (sum(size(res)) == 0)
     error('make_sure_hadldaemon_is_running::couldNotStarthdldaemon', 'I have not been able to start the daemon', res);
end

