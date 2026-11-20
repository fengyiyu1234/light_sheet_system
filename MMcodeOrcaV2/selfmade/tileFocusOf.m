function f = tileFocusOf(checkpoints, tileIndex)
% TILEFOCUSOF  Per-tile detection lens focus of one tile.
%   f = tileFocusOf(checkpoints, tileIndex) returns a 1x4 double, one value per
%   color (488, 561, 640, 730 nm): the detection lens position (mm) set for this
%   tile with "Set tile focus", or NaN where the tile uses the color's default
%   (Detection column of the offset table).
%   checkpoints = app.checkpoints_multipletile; the value is stored in the field
%   tile_focus. Tiles without the field (older scan patterns, tile lists) or with
%   an empty / wrong-sized value give NaN(1,4).
%   (2026-11-20, MATLAB R2019a compatible.)

f = NaN(1, 4);
if isempty(checkpoints) || ~isstruct(checkpoints) || ~isfield(checkpoints, 'tile_focus')
    return;
end
if tileIndex < 1 || tileIndex > numel(checkpoints)
    return;
end
v = checkpoints(tileIndex).tile_focus;
if isnumeric(v) && numel(v) == 4
    f = double(v(:)');
end
end
