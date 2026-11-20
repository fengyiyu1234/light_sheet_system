function [checkpoints, xyzScanArray, V, H, zStep] = readTileList(filename)
% READTILELIST  Read a tile list written by writeTileList (sheets 'Tiles' and 'Grid').
%   [checkpoints, xyzScanArray, V, H, zStep] = readTileList(filename)
%   checkpoints  : nTiles x 1 struct, same fields as app.checkpoints_multipletile
%                  after create scan pattern + save checkpoints / skip tile
%   xyzScanArray : 3 x nTiles (PlanX/PlanY/PlanZ columns)
%   V, H         : Vertical tile, Horizontal tile; zStep: z step stored in the file
%   Works on any imaging_params_*.xlsx written after 2026-11-04 (it has the same
%   two sheets). Errors if the file is incomplete or inconsistent.
%   (2026-11-20) Optional columns Focus488_mm .. Focus730_mm: per-tile detection
%   lens focus (field tile_focus, NaN = default). Files without them load with
%   every tile on the default focus.
%   (2026-11-20) Optional sheet FocusSegments: depth segments (field focus_ops,
%   see tileFocusOps). Files without it load with no segments.
%   (2026-11-04, MATLAB R2019a compatible: readtable / readcell.)

T = readtable(filename, 'Sheet', 'Tiles');
G = readcell(filename, 'Sheet', 'Grid');

need = {'Tile','Saved','Skip','Start_um','End_um','X_um','Y_um','Z_um', ...
        'LightPath','PlanX_um','PlanY_um','PlanZ_um'};
missing = setdiff(need, T.Properties.VariableNames);
if ~isempty(missing)
    error('readTileList:columns', 'Sheet Tiles is missing column(s): %s', strjoin(missing, ', '));
end

V = gridValue(G, 'VerticalTiles');
H = gridValue(G, 'HorizontalTiles');
zStep = gridValue(G, 'ZStep_um');

tile = col(T, 'Tile');
[tile, order] = sort(tile);
n = numel(tile);
if n == 0 || ~isequal(tile(:)', 1:n)
    error('readTileList:tiles', 'Sheet Tiles: the Tile column must be 1..N with no gaps.');
end
if V*H ~= n
    error('readTileList:grid', 'Grid says %d x %d tiles, sheet Tiles has %d rows.', V, H, n);
end

saved = col(T,'Saved'); skip = col(T,'Skip');
st = col(T,'Start_um'); en = col(T,'End_um');
x = col(T,'X_um'); y = col(T,'Y_um'); z = col(T,'Z_um');
lp = col(T,'LightPath');
px = col(T,'PlanX_um'); py = col(T,'PlanY_um'); pz = col(T,'PlanZ_um');
saved = saved(order); skip = skip(order); st = st(order); en = en(order);
x = x(order); y = y(order); z = z(order); lp = lp(order);
px = px(order); py = py(order); pz = pz(order);

xyzScanArray = [px(:)'; py(:)'; pz(:)'];
if any(~isfinite(xyzScanArray(:)))
    error('readTileList:plan', 'PlanX/PlanY/PlanZ must be filled for every tile.');
end

template = struct('saved_488nm', false, 'saved_561nm', false, 'saved_640nm', false, ...
    'tile_xpos', [], 'tile_ypos', [], 'tile_zpos', [], 'skip', false, ...
    'current_path', [], 'xPos', [], 'yPos', [], 'zPos', [], ...
    'start_pos', [], 'end_pos', [], 'saved', false, 'tile_focus', NaN(1,4), 'focus_ops', zeros(0,4));
checkpoints = repmat(template, n, 1);
focusCols = {'Focus488_mm', 'Focus561_mm', 'Focus640_mm', 'Focus730_mm'};
focus = NaN(n, 4);
for k = 1:4
    if any(strcmp(T.Properties.VariableNames, focusCols{k}))
        v = col(T, focusCols{k});
        focus(:,k) = v(order);
    end
end
for i = 1:n
    checkpoints(i).tile_focus = focus(i,:);
    checkpoints(i).tile_xpos = px(i);
    checkpoints(i).tile_ypos = py(i);
    checkpoints(i).tile_zpos = pz(i);
    if ~(saved(i) == 1)
        continue;                         % not saved: like a fresh scan pattern tile
    end
    if any(~isfinite([x(i) y(i) z(i)]))
        error('readTileList:pos', 'Tile %d is saved but X_um/Y_um/Z_um is empty.', i);
    end
    if ~isfinite(lp(i))
        lp(i) = 1;
    end
    checkpoints(i).saved = true;
    checkpoints(i).skip = (skip(i) == 1);
    checkpoints(i).current_path = lp(i);
    checkpoints(i).xPos = x(i); checkpoints(i).yPos = y(i); checkpoints(i).zPos = z(i);
    if checkpoints(i).skip
        checkpoints(i).start_pos = NaN;
        checkpoints(i).end_pos = NaN;
    else
        if ~isfinite(st(i)) || ~isfinite(en(i))
            error('readTileList:depth', 'Tile %d is saved but Start_um/End_um is empty.', i);
        end
        if st(i) > en(i)
            error('readTileList:depth', 'Tile %d: Start_um (%g) is larger than End_um (%g).', i, st(i), en(i));
        end
        checkpoints(i).start_pos = st(i);
        checkpoints(i).end_pos = en(i);
    end
end

try
    F = readtable(filename, 'Sheet', 'FocusSegments');
catch
    F = [];                               % older file: no depth segments
end
fneed = {'Tile', 'Color_nm', 'From_um', 'To_um', 'DetLens_mm'};
if istable(F) && height(F) > 0 && all(ismember(fneed, F.Properties.VariableNames))
    ft = col(F, 'Tile'); fc = col(F, 'Color_nm'); fd = col(F, 'DetLens_mm');
    ff = col(F, 'From_um'); ff(isnan(ff)) = -Inf;
    fto = col(F, 'To_um'); fto(isnan(fto)) = Inf;
    [~, kk] = ismember(fc, [488 561 640 730]);
    for r = 1:numel(ft)
        if kk(r) == 0 || ~(ft(r) >= 1 && ft(r) <= n && ft(r) == round(ft(r)))
            error('readTileList:focus', 'Sheet FocusSegments, row %d: bad Tile or Color_nm.', r + 1);
        end
        checkpoints(ft(r)).focus_ops(end+1, :) = [kk(r), ff(r), fto(r), fd(r)];
    end
end
end

function v = col(T, name)
% numeric column; empty cells become NaN (a fully empty column can be read as text)
v = T.(name);
if iscell(v)
    v = str2double(v);
elseif ~isnumeric(v) && ~islogical(v)
    v = str2double(cellstr(v));
end
v = double(v(:));
end

function v = gridValue(G, name)
v = NaN;
for r = 1:size(G,1)
    if ischar(G{r,1}) && strcmp(strtrim(G{r,1}), name)
        v = G{r,2};
        if ischar(v)
            v = str2double(v);
        end
        break;
    end
end
if ~isnumeric(v) || ~isscalar(v) || ~isfinite(v)
    if strcmp(name, 'ZStep_um')
        v = NaN;                          % information only
        return;
    end
    error('readTileList:gridsheet', 'Sheet Grid: %s is missing or not a number.', name);
end
v = double(v);
end
