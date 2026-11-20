function segs = focusSegments(checkpoints, tileIndex, k, startPos, endPos, defaultFocus)
% FOCUSSEGMENTS  Focus of one tile and color over its depth range, as segments.
%   segs = focusSegments(checkpoints, tileIndex, k, startPos, endPos, defaultFocus)
%   returns an M x 4 double, one row per segment from startPos to endPos (um):
%     [from_um, to_um, focus_mm, source]   (source: 2 segment, 1 tile, 0 default)
%   Neighbouring parts with the same focus and source are merged. The value of
%   each part is focusAtDepth at its middle, so it is what imaging uses for the
%   layers inside it. defaultFocus may be NaN (then default parts have NaN).
%   (2026-11-20, MATLAB R2019a compatible.)

if ~(isfinite(startPos) && isfinite(endPos)) || endPos < startPos
    segs = zeros(0, 4);
    return;
end
ops = tileFocusOps(checkpoints, tileIndex);
ops = ops(ops(:,1) == k, :);
b = [ops(:,2); ops(:,3)];
b = b(isfinite(b) & b > startPos & b < endPos);
b = unique([startPos; b(:); endPos]);
if isscalar(b)                            % start == end
    b = [b; b];
end
segs = zeros(0, 4);
for i = 1:numel(b)-1
    [p, s] = focusAtDepth(checkpoints, tileIndex, k, (b(i) + b(i+1)) / 2, defaultFocus);
    if ~isempty(segs) && segs(end,4) == s && isequaln(segs(end,3), p)
        segs(end,2) = b(i+1);
    else
        segs(end+1, :) = [b(i), b(i+1), p, s]; %#ok<AGROW>
    end
end
end
