function focusEditor(app, action)
% FOCUSEDITOR  Window to set the detection lens focus by depth inside one tile.
%   focusEditor(app)            opens the window (or brings it to the front)
%   focusEditor(app, 'refresh') redraws it if it is open (refreshTileTable does this)
%
%   (2026-11-20) Opened with the "Focus editor" button in panel 3 (applyLayout).
%   It always shows the current tile of the main window (move to tile); the tile
%   must have start/end saved. One bar per color from start (left, close to camera) to end
%   (right, away from camera): grey = the color's default (offset table), blue = tile focus
%   ("Set tile focus"), orange = depth segment set here. Blue line = the point,
%   dashed line = the stage depth when the window was last redrawn. The row of the
%   wavelength chosen in the main window is highlighted; all settings are for that
%   color.
%   Pick the point by clicking a bar, typing it, or "Use stage depth". Adjust the
%   focus with the Obj buttons, then "start -> point" or "point -> end" stores the
%   detection lens position read from the motor for that part of the tile (later
%   settings overwrite earlier ones; the point itself belongs to "point -> end").
%   "Default" buttons set a part back to the color's default. "Whole tile" = Set
%   tile focus (one value for the whole tile; this color's segments are removed).
%   "Undo last" undoes the last change made in this window (lost when it closes).
%   Data: app.checkpoints_multipletile(t).focus_ops (see tileFocusOps) and
%   .tile_focus. Imaging uses them through tileFocus(app, t, k, depth).
%   Locked while "start image all tiles" runs. MATLAB R2019a compatible (classic
%   figure, uicontrol); this file must stay ASCII.

if nargin < 2
    action = 'open';
end
fig = findall(0, 'Type', 'figure', 'Tag', 'LightSheetFocusEditor');
if strcmp(action, 'refresh')
    if ~isempty(fig)
        redraw(app, fig(1));
    end
    return;
end
if isempty(fig)
    fig = makeWindow(app);
else
    fig = fig(1);
    figure(fig);
end
redraw(app, fig);
end

%% ---------------------------------------------------------------- window
function fig = makeWindow(app)
bg = [1.00 0.97 0.85];
% (2026-11-20, layout v2) over the lower part of panel 3 (the tile table) of the main
% window; the settings panel (wavelength), Obj buttons (panel 1), stage (panel 2), the top
% of panel 3 and Live View (right half) stay visible
fig = figure('Name', 'Focus editor', 'NumberTitle', 'off', 'MenuBar', 'none', ...
    'ToolBar', 'none', 'Tag', 'LightSheetFocusEditor', 'HandleVisibility', 'callback', ...
    'Color', bg, 'Units', 'pixels', 'Position', [531 47 420 280], 'Resize', 'off');
ud.tile = 0; ud.point = NaN; ud.st = NaN; ud.en = NaN; ud.undo = {};
ud.ax = axes('Parent', fig, 'Units', 'pixels', 'Position', [40 182 368 90], ...
    'YDir', 'reverse', 'YLim', [0.5 4.5], 'YTick', 1:4, ...
    'YTickLabel', {'488', '561', '640', '730'}, 'Box', 'on', 'FontSize', 9, ...
    'ButtonDownFcn', @(src, evt) pickPoint(app, fig));
ud.info = uicontrol(fig, 'Style', 'text', 'Position', [8 126 404 34], 'BackgroundColor', bg, ...
    'HorizontalAlignment', 'left', 'String', ...
    'Pick a point (click a bar, type it, or use the stage depth), adjust the Obj lens, then set start -> point or point -> end.');
uicontrol(fig, 'Style', 'text', 'Position', [8 94 62 18], 'BackgroundColor', bg, ...
    'HorizontalAlignment', 'left', 'String', 'Point (um)');
ud.pointEdit = uicontrol(fig, 'Style', 'edit', 'Position', [70 92 64 24], ...
    'Callback', @(src, evt) typedPoint(app, fig));
btn(fig, 'Use stage depth',    [140 92 132 24], @(src, evt) stageDepthPoint(app, fig));
btn(fig, 'Move stage here',    [276 92 136 24], @(src, evt) moveStage(app, fig));
btn(fig, 'Lens to focus here', [8 62 132 24],   @(src, evt) lensToPoint(app, fig));
btn(fig, 'Undo last',          [144 62 132 24], @(src, evt) undoLast(app, fig));
btn(fig, 'Refresh',            [280 62 132 24], @(src, evt) redraw(app, fig));
uicontrol(fig, 'Style', 'text', 'Position', [8 34 80 18], 'BackgroundColor', bg, ...
    'HorizontalAlignment', 'left', 'String', 'Current lens:');
btn(fig, '<  start -> point', [90 32 104 24],  @(src, evt) applyOp(app, fig, 'left', true));
btn(fig, 'point -> end  >',   [198 32 104 24], @(src, evt) applyOp(app, fig, 'right', true));
btn(fig, 'Whole tile',        [306 32 106 24], @(src, evt) wholeTile(app, fig));
uicontrol(fig, 'Style', 'text', 'Position', [8 6 80 18], 'BackgroundColor', bg, ...
    'HorizontalAlignment', 'left', 'String', 'Default:');
btn(fig, '<  start -> point', [90 4 104 24],  @(src, evt) applyOp(app, fig, 'left', false));
btn(fig, 'point -> end  >',   [198 4 104 24], @(src, evt) applyOp(app, fig, 'right', false));
set(fig, 'UserData', ud);
end

function btn(fig, txt, pos, cb)
uicontrol(fig, 'Style', 'pushbutton', 'String', txt, 'Position', pos, 'Callback', cb);
end

%% ---------------------------------------------------------------- drawing
function redraw(app, fig)
if ~ishghandle(fig)
    return;
end
ud = get(fig, 'UserData');
ax = ud.ax;
delete(get(ax, 'Children'));
[ti, k] = target(app);
ud.tile = ti;
[ok, st, en, why] = tileRange(app, ti);
if ~ok
    ud.st = NaN; ud.en = NaN; ud.point = NaN;
    set(ud.pointEdit, 'String', '');
    set(ax, 'XLim', [0 1], 'XTick', []);
    set(fig, 'Name', ['Focus editor - ' why]);
    set(fig, 'UserData', ud);
    return;
end
ud.st = st; ud.en = en;
if ~(ud.point >= st && ud.point <= en)
    ud.point = NaN;
end
if en > st
    set(ax, 'XLim', [st en], 'XTickMode', 'auto');
else
    set(ax, 'XLim', [st-1 en+1], 'XTickMode', 'auto');
end
cp = app.checkpoints_multipletile;
defaults = app.UITable_offset.Data.Detectionlens(:)';
if ~isempty(k)                                  % highlight the current wavelength
    patch('Parent', ax, 'XData', [st en en st], 'YData', [k-0.48 k-0.48 k+0.48 k+0.48], ...
        'FaceColor', [1 0.85 0.35], 'EdgeColor', 'none', 'HitTest', 'off');
end
faceCol = {[0.85 0.85 0.85], [0.65 0.80 1.00], [1.00 0.70 0.45]};   % default, tile, segment
tag = {' def', ' tile', ''};
for kk = 1:4
    segs = focusSegments(cp, ti, kk, st, en, defaults);
    for s = 1:size(segs, 1)
        a = segs(s,1); b = segs(s,2);
        patch('Parent', ax, 'XData', [a b b a], 'YData', [kk-0.35 kk-0.35 kk+0.35 kk+0.35], ...
            'FaceColor', faceCol{segs(s,4)+1}, 'EdgeColor', [0.3 0.3 0.3], ...
            'LineWidth', 0.5 + 1.5*isequal(kk, k), 'HitTest', 'off');
        if (b - a) >= 0.07 * max(en - st, 1)   % label only where it fits
            text('Parent', ax, 'Position', [(a+b)/2, kk, 0], 'String', [sprintf('%.4f', segs(s,3)) tag{segs(s,4)+1}], ...
                'HorizontalAlignment', 'center', 'FontSize', 8, 'HitTest', 'off', 'Clipping', 'on');
        end
    end
end
y = NaN;
try
    [~, y, ~] = getXYZposition(app.controlParameters.MMC);
catch
end
if y >= st && y <= en
    line('Parent', ax, 'XData', [y y], 'YData', [0.5 4.5], 'LineStyle', '--', ...
        'Color', [0.2 0.2 0.2], 'HitTest', 'off');
end
if isfinite(ud.point)
    line('Parent', ax, 'XData', [ud.point ud.point], 'YData', [0.5 4.5], ...
        'Color', [0 0.3 1], 'LineWidth', 2, 'HitTest', 'off');
    set(ud.pointEdit, 'String', sprintf('%g', ud.point));
else
    set(ud.pointEdit, 'String', '');
end
if isempty(k)
    wl = 'none';
else
    wl = colorName(k);
end
set(fig, 'Name', sprintf('Focus editor - tile %d (start %g um, end %g um), wavelength %s, stage depth %s um', ...
    ti, st, en, wl, num2str(round(y))));
set(fig, 'UserData', ud);
end

%% ---------------------------------------------------------------- point
function pickPoint(app, fig)
ud = get(fig, 'UserData');
if ~isfinite(ud.st)
    return;
end
c = get(ud.ax, 'CurrentPoint');
setPoint(app, fig, c(1,1));
end

function typedPoint(app, fig)
ud = get(fig, 'UserData');
v = str2double(get(ud.pointEdit, 'String'));
if ~isfinite(v)
    setInfo(fig, 'Type the point as a number (um).');
    redraw(app, fig);
    return;
end
setPoint(app, fig, v);
end

function stageDepthPoint(app, fig)
[~, y, ~] = getXYZposition(app.controlParameters.MMC);
setPoint(app, fig, y);
end

function setPoint(app, fig, v)
ud = get(fig, 'UserData');
if ~isfinite(ud.st)
    setInfo(fig, 'No tile with start/end: nothing to pick.');
    return;
end
v = round(v);
if v < ud.st || v > ud.en
    setInfo(fig, sprintf('%g um is outside this tile (%g .. %g um): the point is set to the nearest end.', v, ud.st, ud.en));
    v = min(max(v, ud.st), ud.en);
end
ud.point = v;
set(fig, 'UserData', ud);
redraw(app, fig);
end

%% ---------------------------------------------------------------- actions
function [ok, ti, k, ud] = check(app, fig, needColor, needPoint)
% common checks before an action; shows the reason in the info line
ok = false; k = [];
ud = get(fig, 'UserData');
ti = ud.tile;
if isImaging(app)
    setInfo(fig, 'Imaging is running: the Focus editor is locked.');
    return;
end
[tiNow, k] = target(app);
if tiNow ~= ud.tile
    redraw(app, fig);
    setInfo(fig, sprintf('The main window moved to tile %d: check the point and press again.', tiNow));
    return;
end
[okRange, ~, ~, why] = tileRange(app, ti);
if ~okRange
    setInfo(fig, why);
    return;
end
if needColor && isempty(k)
    setInfo(fig, 'Choose the wavelength in the main window first: the focus is set for that color.');
    return;
end
if needPoint && ~isfinite(ud.point)
    setInfo(fig, 'Pick a point first.');
    return;
end
ok = true;
end

function applyOp(app, fig, side, useLens)
[ok, ti, k, ud] = check(app, fig, true, true);
if ~ok
    return;
end
defaults = app.UITable_offset.Data.Detectionlens(:)';
if useLens
    pos = readLensPos(app.controlParameters.sDetLens);
    if ~isfinite(pos)
        setInfo(fig, 'Could not read the detection lens position: nothing changed.');
        return;
    end
    app.state_motor.MotorPosition_mm_(3) = pos;
    refreshPathMotorTable(app);
    val = sprintf('%.4f mm', pos);
else
    pos = NaN;
    val = sprintf('default (%.4f mm)', defaults(k));
end
ud = pushUndo(app, ud, ti);
if strcmp(side, 'left')
    row = [k, -Inf, ud.point, pos];
    where = sprintf('start (%g) -> %g um', ud.st, ud.point);
else
    row = [k, ud.point, Inf, pos];
    where = sprintf('%g -> end (%g) um', ud.point, ud.en);
end
set(fig, 'UserData', ud);
app.checkpoints_multipletile(ti,1).focus_ops = [tileFocusOps(app.checkpoints_multipletile, ti); row];
updateTileStatus(app, ti);          % tile table, scanpattern.mat, and redraws this window
setInfo(fig, sprintf('Tile %d, %s: %s = %s', ti, colorName(k), where, val));
end

function wholeTile(app, fig)
[ok, ti, ~, ud] = check(app, fig, true, false);
if ~ok
    return;
end
ud = pushUndo(app, ud, ti);
set(fig, 'UserData', ud);
setTileFocus(app);                  % reads the lens; removes this color's segments
if ~isempty(app.TileFocusInfo) && isvalid(app.TileFocusInfo)
    setInfo(fig, ['Whole tile: ' app.TileFocusInfo.Text]);
end
end

function undoLast(app, fig)
ud = get(fig, 'UserData');
if isImaging(app)
    setInfo(fig, 'Imaging is running: the Focus editor is locked.');
    return;
end
if isempty(ud.undo)
    setInfo(fig, 'Nothing to undo (only changes made in this window since it was opened).');
    return;
end
snap = ud.undo{end};
ud.undo(end) = [];
set(fig, 'UserData', ud);
if snap.tile > numel(app.checkpoints_multipletile)
    setInfo(fig, 'Cannot undo: the scan pattern has changed.');
    return;
end
app.checkpoints_multipletile(snap.tile,1).tile_focus = snap.tile_focus;
app.checkpoints_multipletile(snap.tile,1).focus_ops = snap.ops;
updateTileStatus(app, snap.tile);
setInfo(fig, sprintf('Undone: tile %d is back to its focus before the last change.', snap.tile));
end

function moveStage(app, fig)
[ok, ~, ~, ud] = check(app, fig, false, true);
if ~ok
    return;
end
[~, y, ~] = getXYZposition(app.controlParameters.MMC);
SetRelativePos(app.controlParameters.MMC, 0, ud.point - y, 0);
redraw(app, fig);
setInfo(fig, sprintf('Stage moved to depth %g um.', ud.point));
end

function lensToPoint(app, fig)
[ok, ti, k, ud] = check(app, fig, true, true);
if ~ok
    return;
end
[pos, src] = focusAtDepth(app.checkpoints_multipletile, ti, k, ud.point, app.UITable_offset.Data.Detectionlens);
fprintf(app.controlParameters.sDetLens, ['1PA', num2str(pos)]);
now_pos = readLensPos(app.controlParameters.sDetLens);
app.state_motor.MotorPosition_mm_(3) = now_pos;
refreshPathMotorTable(app);
names = {'default', 'tile focus', 'segment'};
setInfo(fig, sprintf('Detection lens moved to %.4f mm (%s of %s at %g um); read back %.4f mm.', ...
    pos, names{src+1}, colorName(k), ud.point, now_pos));
end

%% ---------------------------------------------------------------- helpers
function ud = pushUndo(app, ud, ti)
snap.tile = ti;
snap.tile_focus = tileFocusOf(app.checkpoints_multipletile, ti);
snap.ops = tileFocusOps(app.checkpoints_multipletile, ti);
ud.undo{end+1} = snap;
end

function [ti, k] = target(app)
ti = app.movetotileSpinner.Value;
k = find(strcmp(char(app.Lightwavelight.Value), {'488nm', '561nm', '640nm', '730nm'}));
end

function [ok, st, en, why] = tileRange(app, ti)
ok = false; st = NaN; en = NaN; why = '';
cp = app.checkpoints_multipletile;
if isempty(app.xyzScanArray) || ~isequal(app.xyzScanArray_status, true) || isempty(cp)
    why = 'no scan pattern (create scan pattern first)';
elseif ti < 1 || ti > numel(cp)
    why = 'no tile (move to tile first)';
elseif ~(isfield(cp, 'saved') && isequal(cp(ti).saved, true))
    why = sprintf('tile %d: save checkpoints (start/end) first', ti);
elseif isfield(cp, 'skip') && isequal(cp(ti).skip, true)
    why = sprintf('tile %d is skipped (blank)', ti);
else
    st = cp(ti).start_pos; en = cp(ti).end_pos;
    ok = isfinite(st) && isfinite(en);
    if ~ok
        why = sprintf('tile %d has no start/end', ti);
    end
end
end

function n = colorName(k)
names = {'488nm', '561nm', '640nm', '730nm'};
n = names{k};
end

function setInfo(fig, msg)
fprintf('Focus editor: %s\n', msg);   % also in the log file
if ishghandle(fig)
    ud = get(fig, 'UserData');
    set(ud.info, 'String', msg);
end
end
