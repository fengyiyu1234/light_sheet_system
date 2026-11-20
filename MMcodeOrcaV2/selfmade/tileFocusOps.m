function ops = tileFocusOps(checkpoints, tileIndex)
% TILEFOCUSOPS  Depth-segment focus operations of one tile (Focus editor).
%   ops = tileFocusOps(checkpoints, tileIndex) returns an N x 4 double, one row
%   per operation in the order they were made (later rows overwrite earlier ones):
%     [k, from_um, to_um, focus_mm]
%     k        : color 1..4 (488, 561, 640, 730 nm)
%     from, to : depth range (stage Y, um), half open: from <= y < to.
%                "start -> point" = [-Inf, point), "point -> end" = [point, Inf)
%     focus    : detection lens position (mm); NaN = the color's default
%                (Detection column of the offset table)
%   The rows are stored in checkpoints(tileIndex).focus_ops. Tiles without the
%   field or with an empty / wrong-sized value give zeros(0, 4).
%   (2026-11-20, MATLAB R2019a compatible.)

ops = zeros(0, 4);
if isempty(checkpoints) || ~isstruct(checkpoints) || ~isfield(checkpoints, 'focus_ops')
    return;
end
if tileIndex < 1 || tileIndex > numel(checkpoints)
    return;
end
v = checkpoints(tileIndex).focus_ops;
if isnumeric(v) && ~isempty(v) && size(v, 2) == 4
    ops = double(v);
end
end
