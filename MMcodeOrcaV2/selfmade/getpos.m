function [POS] = getpos(pos)
% GETPOS  Parse a Newport motor reply to '1TP?' and return the position.
%   POS = getpos(reply) takes the raw reply, e.g. '1TP4.3399998' or
%   '1TP-1.5e-04', and returns the position in mm as a char vector.
%   Callers convert it with str2num/str2double, as before.
%
%   2026-11 fix: the old version cut off the exponent of replies in
%   scientific notation (only e-05/e-06 were handled, as 0), so a reply
%   like '1.5e-04' was read as 1.5 mm. The whole number is now parsed.
%   An unreadable reply raises an error instead of returning a wrong value.

    k = strfind(pos, 'TP');
    if isempty(k)
        error('getpos:badReply', 'Unexpected motor reply: "%s"', strtrim(char(pos)));
    end
    val = str2double(strtrim(pos(k(1)+2:end)));
    if isnan(val)
        error('getpos:badReply', 'Could not read a position from motor reply: "%s"', strtrim(char(pos)));
    end
    POS = sprintf('%.9g', val);
end
