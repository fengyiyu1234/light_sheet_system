function flushDiary()
% FLUSHDIARY  Write the command-window log (diary) to disk now.
%   Turning the diary off and on again closes and reopens the file, so the text
%   printed so far is on disk even if MATLAB crashes afterwards. Does nothing
%   when the diary is off. Called by the app's log timer (every 30 s) and after
%   each tile during imaging. (2026-11-04)
if strcmp(get(0, 'Diary'), 'on')
    diary off;
    diary on;
end
end
