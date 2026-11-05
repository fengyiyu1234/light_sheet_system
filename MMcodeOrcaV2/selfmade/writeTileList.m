function writeTileList(filename, checkpoints, xyzScanArray, V, H, zStep, newFile)
% WRITETILELIST  Write the tile list of a scan pattern to an xlsx file.
%   writeTileList(filename, checkpoints, xyzScanArray, V, H, zStep, newFile)
%   checkpoints  : app.checkpoints_multipletile (one struct per tile)
%   xyzScanArray : app.xyzScanArray (3 x nTiles, from create scan pattern)
%   V, H         : Vertical tile, Horizontal tile (V*H must equal nTiles)
%   zStep        : z-stack step (um), stored for information only
%   newFile      : true (default) deletes an existing file first;
%                  false adds/overwrites only the two sheets below.
%
%   Sheet 'Tiles': one row per tile, in scan-pattern order (Z fastest):
%     Tile, Saved (1/0), Skip (1/0), Start_um, End_um (depth, Y stage),
%     X_um, Y_um, Z_um (stage position saved with the tile; imaging moves here),
%     LightPath, PlanX_um, PlanY_um, PlanZ_um (position from create scan pattern).
%   Sheet 'Grid': VerticalTiles, HorizontalTiles, ZStep_um, NumTiles, Written.
%   readTileList reads the same format back. (2026-11-04, MATLAB R2019a compatible.)

if nargin < 7
    newFile = true;
end
n = size(xyzScanArray, 2);
if n == 0
    error('writeTileList:empty', 'No scan pattern (xyzScanArray is empty).');
end
if V*H ~= n
    error('writeTileList:grid', ...
        'Vertical x Horizontal tile = %d x %d = %d, but the scan pattern has %d tiles. Were the tile numbers changed after create scan pattern?', ...
        V, H, V*H, n);
end
if numel(checkpoints) ~= n
    error('writeTileList:size', 'checkpoints has %d entries, scan pattern has %d tiles.', numel(checkpoints), n);
end

Tile = (1:n)';
Saved = zeros(n,1); Skip = zeros(n,1);
Start_um = NaN(n,1); End_um = NaN(n,1);
X_um = NaN(n,1); Y_um = NaN(n,1); Z_um = NaN(n,1);
LightPath = NaN(n,1);
PlanX_um = xyzScanArray(1,:)'; PlanY_um = xyzScanArray(2,:)'; PlanZ_um = xyzScanArray(3,:)';

for i = 1:n
    c = checkpoints(i);
    if ~isTrue(c, 'saved')
        continue;
    end
    Saved(i) = 1;
    Skip(i) = double(isTrue(c, 'skip'));
    X_um(i) = num(c, 'xPos'); Y_um(i) = num(c, 'yPos'); Z_um(i) = num(c, 'zPos');
    LightPath(i) = num(c, 'current_path');
    if ~Skip(i)
        Start_um(i) = num(c, 'start_pos');
        End_um(i) = num(c, 'end_pos');
    end
end

T = table(Tile, Saved, Skip, Start_um, End_um, X_um, Y_um, Z_um, LightPath, ...
    PlanX_um, PlanY_um, PlanZ_um);
G = {'Parameter', 'Value';
     'VerticalTiles', V;
     'HorizontalTiles', H;
     'ZStep_um', zStep;
     'NumTiles', n;
     'Written', datestr(now, 'yyyy-mm-dd HH:MM:SS');
     'Note', 'Tile order = create scan pattern order (Z fastest). Skip=1: blank tile. Saved=0: not saved.'};

if newFile && exist(filename, 'file') == 2
    delete(filename);
end
writetable(T, filename, 'Sheet', 'Tiles');
writecell(G, filename, 'Sheet', 'Grid');
end

function tf = isTrue(c, f)
tf = isfield(c, f) && isequal(c.(f), true);
end

function v = num(c, f)
v = NaN;
if isfield(c, f) && ~isempty(c.(f)) && isnumeric(c.(f))
    v = double(c.(f)(1));
end
end
