function data = tileTableData(checkpoints, nTiles)
% TILETABLEDATA  Rows of the tile table in panel 3 (app.TileTable).
%   data = tileTableData(checkpoints, nTiles) returns an nTiles x 7 cell array of
%   text: Tile, Start, End, 488, 561, 640, 730.
%     Start / End : depth (um) saved with "save checkpoints"; 'none' if the tile
%                   is not saved yet; 'skip' if the tile is skipped (blank).
%     488 .. 730  : detection lens focus (mm) set for this tile, or 'default'
%                   (the color's value in the offset table). Empty for a
%                   skipped tile (it is not imaged). With depth segments (Focus
%                   editor) that give more than one value: 'N seg' (N parts).
%   checkpoints = app.checkpoints_multipletile (may be shorter than nTiles).
%   (2026-11-20, MATLAB R2019a compatible.)

data = cell(nTiles, 7);
for i = 1:nTiles
    data{i,1} = sprintf('%d', i);
    saved = false; skip = false; st = NaN; en = NaN;
    if isstruct(checkpoints) && i <= numel(checkpoints)
        c = checkpoints(i);
        saved = isfield(c, 'saved') && isequal(c.saved, true);
        skip = isfield(c, 'skip') && isequal(c.skip, true);
        st = num(c, 'start_pos');
        en = num(c, 'end_pos');
    end
    if saved && skip
        data(i,2:7) = {'skip', '', '', '', '', ''};
        continue;
    elseif saved
        data{i,2} = numText(st);
        data{i,3} = numText(en);
    else
        data{i,2} = 'none';
        data{i,3} = 'none';
    end
    f = tileFocusOf(checkpoints, i);
    ops = tileFocusOps(checkpoints, i);
    for k = 1:4
        if saved && any(ops(:,1) == k)     % (2026-11-20) depth segments of this color
            segs = focusSegments(checkpoints, i, k, st, en, NaN(1,4));
            if size(segs, 1) > 1
                data{i,3+k} = sprintf('%d seg', size(segs, 1));
                continue;
            elseif size(segs, 1) == 1 && segs(1,4) == 0
                data{i,3+k} = 'default';
                continue;
            elseif size(segs, 1) == 1
                data{i,3+k} = sprintf('%.4f', segs(1,3));
                continue;
            end
        end
        if isfinite(f(k))
            data{i,3+k} = sprintf('%.4f', f(k));
        else
            data{i,3+k} = 'default';
        end
    end
end
end

function t = numText(v)
if isfinite(v)
    t = sprintf('%g', v);
else
    t = 'none';
end
end

function v = num(c, f)
v = NaN;
if isfield(c, f) && ~isempty(c.(f)) && isnumeric(c.(f))
    v = double(c.(f)(1));
end
end
