function [pos, source] = focusAtDepth(checkpoints, tileIndex, k, y, defaultFocus)
% FOCUSATDEPTH  Detection lens focus used at one depth of one tile, for one color.
%   [pos, source] = focusAtDepth(checkpoints, tileIndex, k, y, defaultFocus)
%   k            : color 1..4 (488, 561, 640, 730 nm)
%   y            : depth (stage Y, um)
%   defaultFocus : Detection column of the offset table (4 values)
%   pos          : lens position (mm)
%   source       : 2 = depth segment (Focus editor), 1 = tile focus ("Set tile
%                  focus"), 0 = the color's default
%   Order: the last depth segment of this color that contains y wins (a segment
%   set to "default" gives the color's default); without one, the tile focus;
%   without that, the default.
%   (2026-11-20, MATLAB R2019a compatible.)

defaultFocus = double(defaultFocus(:)');
pos = defaultFocus(k);
source = 0;
f = tileFocusOf(checkpoints, tileIndex);
if isfinite(f(k))
    pos = f(k);
    source = 1;
end
ops = tileFocusOps(checkpoints, tileIndex);
for r = size(ops, 1):-1:1
    if ops(r,1) == k && y >= ops(r,2) && y < ops(r,3)
        if isnan(ops(r,4))
            pos = defaultFocus(k);
            source = 0;
        else
            pos = ops(r,4);
            source = 2;
        end
        return;
    end
end
end
