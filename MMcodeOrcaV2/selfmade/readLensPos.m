function pos = readLensPos(s)
% READLENSPOS  Read the position (mm) of a Newport lens motor reliably.
%   pos = readLensPos(s) returns the position of the motor on serial port s
%   as a double, e.g. readLensPos(controlParameters.sDetLens).
%
%   Why (2026-11): the GUI used to send '1TP?' and read one line, which
%   1) returned an OLD position if an earlier reply was still waiting in the
%      serial input buffer (the buffer lives in controlParameters, so even
%      restarting the GUI did not clear it), and
%   2) could return a position from the middle of a move if the motor had
%      not finished within the fixed pause (InitTheMotor sends '1VA0.2';
%      the real velocity was not checked on the controller).
%   This function discards stale replies before every query and keeps
%   reading until two reads in a row agree, i.e. the motor has stopped.

    tol_mm    = 1e-4;   % two reads closer than this (0.1 um) = stopped
    timeout_s = 10;     % give up waiting after this long

    pause(0.2);         % let a move that was just commanded start
    prev = NaN;
    t0 = tic;
    while true
        discardInput(s);
        fprintf(s, '1TP?');
        pos = str2double(getpos(fscanf(s)));
        if abs(pos - prev) < tol_mm
            return;
        end
        if toc(t0) > timeout_s
            warning('readLensPos:notSettled', ...
                'Lens position still changing after %g s; using the last read, %.6f mm.', timeout_s, pos);
            return;
        end
        prev = pos;
        pause(0.1);
    end
end

function discardInput(s)
    if isa(s, 'serial')
        flushinput(s);          % old serial() object (used by InitTheMotor)
    else
        flush(s, 'input');      % newer serialport() object
    end
end
