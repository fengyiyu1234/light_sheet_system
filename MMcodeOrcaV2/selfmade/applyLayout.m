function applyLayout(app)
% APPLYLAYOUT  Rearrange LightSheetControl by workflow (called once from startupFcn).
%
%   (2026-11-04) The Design View layout is not changed. At startup this function
%   creates 4 panels and moves the existing components into them (only Parent,
%   Position and a few display properties change; callbacks are untouched).
%   (2026-11-20) Layout v2:
%     settings (top left) : image saving directory; wavelength, power, filter, exposure,
%               contrast, AFG scan, Enable/Disable Camera; light path, shutter, save image,
%               autofocus method; acquisition: colors, power/exposure, z step, autofocus
%               step, 640 nm mode and tools, HDR powers, reset / start imaging
%     1 Channel tuning (below, left) : galvo X/Y (slider, buttons and step below it),
%               lenses, path table (4x1) and offset table (transposed view)
%     2 Stage + Paint (below, middle) : stage arrows (also the Paint moves when Paint is
%               on), depth buttons (close to / away from camera), steps, Paint column,
%               stage position, tile grid
%     3 Z bounds and focus per tile (right, full height) : move to tile, start/end, save
%               checkpoints, tile focus buttons, Focus editor, tile table (Tile States box
%               hidden)
%   The window is half of a 1920 x 1080 screen (left half); Live View and Paint
%   open on the right half (set in EnableCamButtonPushed / PaintButtonValueChanged).
%   To go back to the Design View layout, remove the applyLayout(app) line in startupFcn.
%   Components that are not placed here (e.g. a button added later in Design View)
%   stay on the window at their Design View position, behind the panels; their
%   names are printed in the command window.
%   This file must stay ASCII (R2019a reads .m files in the system encoding).

fig = app.UIFigure;
W = 960; H = 960;
fig.Position = [1 41 W H];          % left half of the screen, above the taskbar

colTop = [0.92 0.92 0.92];          % settings (laser, camera, acquisition): grey
col1   = [0.88 0.96 0.88];          % 1 channel tuning: green
col2   = [0.88 0.93 1.00];          % 2 stage + paint: blue
col3   = [1.00 0.97 0.85];          % 3 z per tile: yellow

% (2026-11-20) the old top bar and panel 4 (acquisition) are one settings panel on top,
% as wide as panels 1 + 2 below it; panel 3 (tiles) uses the full height on the right
pTop = uipanel(fig, 'Title', 'Laser, camera and acquisition', ...
    'Position', [5 610 515 345], 'BackgroundColor', colTop, 'FontWeight', 'bold');
p1 = uipanel(fig, 'Title', '1. Channel tuning', ...
    'Position', [5 5 255 600], 'BackgroundColor', col1, 'FontWeight', 'bold');
p2 = uipanel(fig, 'Title', '2. Stage + Paint (XY bounds)', ...
    'Position', [265 5 255 600], 'BackgroundColor', col2, 'FontWeight', 'bold');
p3 = uipanel(fig, 'Title', '3. Z bounds and focus per tile', ...
    'Position', [525 5 430 950], 'BackgroundColor', col3, 'FontWeight', 'bold');
T  = 575;                            % top of the usable area inside p1, p2 (600 minus the title)
T3 = 925;                            % same for p3

%% settings panel (top)
% row 1: image saving directory
put(app.ImagesavingdirectoryButton, pTop, [8 292 140 24]);
put(app.pathEditField,              pTop, [152 292 282 24]);
put(app.OpenPathButton,             pTop, [438 292 68 24]);
% rows 2-3: wavelength, laser power, filter wheel / exposure, contrast, AFG scan;
% Enable / Disable Camera on the right (used very often)
put(app.WavelengthLabel,        pTop, [8 252 150 34]);   % coloured by wavelength; the dropdown sits on it
put(app.Lightwavelight,         pTop, [83 258 72 22]);
put(app.LaserPowermWEditFieldLabel, pTop, [160 258 64 22]);
put(app.LaserPower,             pTop, [226 258 40 22]);
put(app.FilterwheelDropDownLabel, pTop, [270 258 34 22]);
put(app.Filterwheel,            pTop, [306 258 88 22]);
app.LaserPowermWEditFieldLabel.Text = 'Power(mW)';
app.FilterwheelDropDownLabel.Text = 'Filter';
put(app.Exposure_timeEditFieldLabel, pTop, [8 224 86 22]);
put(app.Exposure_timeEditField, pTop, [96 224 55 22]);
put(app.ImagecontrastLabel,     pTop, [157 224 85 22]);
put(app.Imagecontrast,          pTop, [244 224 55 22]);
put(app.AFG_scanButton,         pTop, [306 224 68 22]);
put(app.EnableCam,              pTop, [400 255 106 32]);
put(app.DisableCam,             pTop, [400 219 106 32]);
app.EnableCam.FontSize = 12;
app.EnableCam.FontWeight = 'bold';
app.DisableCam.FontSize = 12;
app.DisableCam.FontWeight = 'bold';
% row 4: light path, shutter (hardly used), save image, autofocus method
put(app.LightPathDropDownLabel, pTop, [8 188 36 22]);
put(app.LightPathDropDown,      pTop, [46 188 64 22]);
put(app.ShutterButton,          pTop, [116 188 60 22]);
put(app.SaveImage,              pTop, [182 188 120 22]);
put(app.AutoFocusDropDownLabel, pTop, [306 188 66 22]);
put(app.AutoFocusDropDown,      pTop, [374 188 132 22]);
app.LightPathDropDownLabel.Text = 'Path';
uipanel(pTop, 'Position', [8 179 498 2], 'BorderType', 'none', 'BackgroundColor', [0.6 0.6 0.6]);
% rows 5-7 (acquisition): colors with power / exposure; z step, autofocus step, 640 nm mode
put(app.ChoosewhichcolortoimageLabel, pTop, [8 150 78 22]);
app.ChoosewhichcolortoimageLabel.Text = 'Colors';
colors = {'488', '561', '640', '730'};
for i = 1:4
    x = 90 + (i-1)*68;
    put(app.(['W' colors{i} 'nmCheckBox']),          pTop, [x 150 66 22]);
    app.(['W' colors{i} 'nmCheckBox']).Text = colors{i};   % (2026-11-20) '488' instead of 'W488nm'
    put(app.(['Power_' colors{i} 'EditField']),      pTop, [x 124 50 22]);
    put(app.(['Exposure_' colors{i} 'EditField']),   pTop, [x 98 50 22]);
    if i == 1   % one row label per row, the other labels are hidden
        put(app.(['Power_' colors{i} 'EditFieldLabel']),    pTop, [8 124 78 22]);
        put(app.(['Exposure_' colors{i} 'EditFieldLabel']), pTop, [8 98 78 22]);
        app.(['Power_' colors{i} 'EditFieldLabel']).Text = 'Power';
        app.(['Exposure_' colors{i} 'EditFieldLabel']).Text = 'Exposure';
        app.(['Power_' colors{i} 'EditFieldLabel']).HorizontalAlignment = 'left';
        app.(['Exposure_' colors{i} 'EditFieldLabel']).HorizontalAlignment = 'left';
    else
        app.(['Power_' colors{i} 'EditFieldLabel']).Visible = 'off';
        app.(['Exposure_' colors{i} 'EditFieldLabel']).Visible = 'off';
    end
end
put(app.z_step_sizeumLabel,                 pTop, [362 150 92 22]);
put(app.zstack_distanceum,                  pTop, [458 150 48 22]);
put(app.AutoFocusStepSizeumEditFieldLabel,  pTop, [362 124 92 22]);
put(app.AutoFocusStepSizeumEditField,       pTop, [458 124 48 22]);
app.z_step_sizeumLabel.Text = 'z step (um)';
app.AutoFocusStepSizeumEditFieldLabel.Text = 'AF step (um)';
app.z_step_sizeumLabel.HorizontalAlignment = 'left';
app.AutoFocusStepSizeumEditFieldLabel.HorizontalAlignment = 'left';
% 640 nm Analog tools: only moved (CLAUDE.md rule 7)
put(app.Mode640nmDropDownLabel,  pTop, [362 98 62 22]);
put(app.Mode640nmDropDown,       pTop, [426 98 80 22]);
app.Mode640nmDropDownLabel.Text = 'Mode 640';
app.Mode640nmDropDownLabel.HorizontalAlignment = 'left';
put(app.ListofLaserPowerstogenerateHDRimageMin1Max20Label, pTop, [8 74 350 18]);
app.ListofLaserPowerstogenerateHDRimageMin1Max20Label.Text = 'Laser powers for the HDR image (min 1, max 20)';
put(app.HDPRTable,               pTop, [8 4 350 66]);
app.HDPRTable.ColumnWidth = {80, 80, 80, 80};
put(app.SvAFG2Button,            pTop, [362 72 70 22]);
put(app.StopAnalogButton,        pTop, [436 72 70 22]);
% start / reset imaging
put(app.ResetImagingButton,         pTop, [362 42 144 24]);
put(app.startimagealltilesButton,   pTop, [362 4 144 32]);
app.startimagealltilesButton.FontSize = 12;
app.startimagealltilesButton.FontWeight = 'bold';
app.startimagealltilesButton.BackgroundColor = [0.47 0.67 0.19];
app.startimagealltilesButton.FontColor = [1 1 1];

%% 1 channel tuning
% (2026-11-20) the galvo left/right buttons and step drop-down are below each slider
stepItems = {'0.1', '0.05', '0.01', '0.005', '0.001'};   % galvo step (V) for the left/right buttons
put(app.galvo_XSliderLabel, p1, [6 T-26 50 22]);
put(app.galvo_XSlider,      p1, [62 T-14 175 3]);
app.galvo_XSlider.MajorTicks = -0.4:0.2:0.4;
app.galvo_XSlider.MinorTicks = -0.4:0.1:0.4;
ddX = uidropdown(p1, 'Items', stepItems, 'Value', '0.01', 'Position', [140 T-64 62 24]);
uibutton(p1, 'Text', char(9664), 'Position', [62 T-64 34 24], ...
    'ButtonPushedFcn', @(src, event) galvoStep(app, 'X', -str2double(ddX.Value)));
uibutton(p1, 'Text', char(9654), 'Position', [100 T-64 34 24], ...
    'ButtonPushedFcn', @(src, event) galvoStep(app, 'X',  str2double(ddX.Value)));

put(app.galvo_YSliderLabel, p1, [6 T-98 50 22]);
put(app.galvo_YSlider,      p1, [62 T-86 175 3]);
app.galvo_YSlider.MajorTicks = -0.6:0.3:0.6;
app.galvo_YSlider.MinorTicks = -0.6:0.1:0.6;
ddY = uidropdown(p1, 'Items', stepItems, 'Value', '0.01', 'Position', [140 T-136 62 24]);
uibutton(p1, 'Text', char(9664), 'Position', [62 T-136 34 24], ...
    'ButtonPushedFcn', @(src, event) galvoStep(app, 'Y', -str2double(ddY.Value)));
uibutton(p1, 'Text', char(9654), 'Position', [100 T-136 34 24], ...
    'ButtonPushedFcn', @(src, event) galvoStep(app, 'Y',  str2double(ddY.Value)));

put(app.Reset_galvo_XYButton, p1, [6 T-170 110 24]);
put(app.ShowGridCheckBox,     p1, [126 T-169 90 22]);

lens = app.ExcitationLensandDetectionLensPanel;
put(lens, p1, [6 T-272 240 92]);
lens.Title = 'Excitation and detection lens';
put(app.ExtStepsizeDropDownLabel, lens, [4 40 66 22]);
put(app.ExtStepsizeDropDown,      lens, [72 40 64 22]);
put(app.leftButtonExt,            lens, [142 40 44 22]);
put(app.rightButtonExt,           lens, [190 40 44 22]);
put(app.ObjStepsizeDropDownLabel, lens, [4 8 66 22]);
put(app.ObjStepsizeDropDown,      lens, [72 8 64 22]);
put(app.leftButtonObj,            lens, [142 8 44 22]);
put(app.rightButtonObj,           lens, [190 8 44 22]);
app.ExtStepsizeDropDownLabel.Text = 'Ext step';
app.ObjStepsizeDropDownLabel.Text = 'Obj step';
% (2026-11-20) arrows instead of 'left'/'right'; the callbacks are unchanged
% (left arrow = 1PR +step, position up; right arrow = 1PR -step, position down)
app.leftButtonExt.Text  = char(9664);
app.rightButtonExt.Text = char(9654);
app.leftButtonObj.Text  = char(9664);
app.rightButtonObj.Text = char(9654);

% (2026-11-20) both tables transposed (taller, narrower). UITable_path: 4x1, one row per
% item (refreshPathMotorTable; names set in startupFcn). The offset table is shown as
% OffsetView (rows = items, columns = colors); UITable_offset is hidden but still holds
% the data that the rest of the code reads (refreshOffsetView / offsetViewEdit in the app)
put(app.UITable_path,  p1, [6 T-398 170 120]);
app.UITable_path.FontSize = 11;
app.UITable_path.ColumnWidth = {76};
app.UITable_motor.Visible = 'off';
app.UITable_offset.Visible = 'off';
app.OffsetView = uitable(p1, 'Position', [6 T-530 240 126], 'Data', zeros(4, 4), ...
    'RowName', {'GalvoX'; 'GalvoY'; 'Det'; 'Ext'}, ...
    'ColumnName', {'488'; '561'; '640'; '730'}, 'ColumnEditable', true(1, 4), ...
    'ColumnWidth', {44, 44, 44, 44}, 'FontSize', 10, ...
    'CellEditCallback', @(src, event) offsetViewEdit(app, event));
put(app.saveoffsetfordifferentcolorButton, p1, [6 T-562 220 26]);

% Roll is not used: hidden (callbacks unchanged)
app.RollSlider.Visible = 'off';
app.RollSliderLabel.Visible = 'off';
app.RollScanButton.Visible = 'off';

%% 2 stage + paint
% (2026-11-20) arrow cross in the middle; the depth (Y) buttons below it, named by the
% sample's movement relative to the camera (Button_5 = Y - step = towards the camera,
% limited by Min Z; Button_6 = Y + step = away); the three step drop-downs together below,
% with the Paint buttons in a column next to them
put(app.Button,   p2, [97 T-48 56 44]);     % up    (X - step)
put(app.Button_3, p2, [37 T-94 56 44]);     % left  (Z + step)
put(app.Button_2, p2, [157 T-94 56 44]);    % right (Z - step)
put(app.Button_4, p2, [97 T-140 56 44]);    % down  (X + step)
put(app.Button_5, p2, [6 T-192 118 44]);
put(app.Button_6, p2, [128 T-192 118 44]);
app.Button_5.Text = 'Close to camera';
app.Button_6.Text = 'Away from camera';
app.Button_5.FontSize = 12;
app.Button_6.FontSize = 12;
app.Button_5.FontWeight = 'bold';
app.Button_6.FontWeight = 'bold';
app.Button_5.BackgroundColor = [1.00 0.80 0.55];
app.Button_6.BackgroundColor = [0.82 0.74 1.00];

put(app.Updown_stepDropDownLabel,    p2, [6 T-226 66 22]);
put(app.Updown_stepDropDown,         p2, [74 T-226 72 22]);
put(app.Leftright_stepDropDownLabel, p2, [6 T-252 66 22]);
put(app.Leftright_stepDropDown,      p2, [74 T-252 72 22]);
put(app.Inout_stepDropDownLabel,     p2, [6 T-278 66 22]);
put(app.Inout_stepDropDown,          p2, [74 T-278 72 22]);
app.Updown_stepDropDownLabel.Text = 'Up/Down';
app.Leftright_stepDropDownLabel.Text = 'Left/Right';
app.Inout_stepDropDownLabel.Text = 'Depth';
app.Updown_stepDropDownLabel.HorizontalAlignment = 'left';
app.Leftright_stepDropDownLabel.HorizontalAlignment = 'left';
app.Inout_stepDropDownLabel.HorizontalAlignment = 'left';

% (2026-11-20) Paint Up/Down/Left/Right hidden: with Paint on, the stage arrow buttons
% and the arrow keys do the Paint moves (paintMoveInstead / stageKeyPress in the app)
paint = app.PaintModePanel;
put(paint, p2, [154 T-306 92 110]);
put(app.PaintButton,     paint, [6 60 78 24]);
put(app.CenterButton,    paint, [6 32 78 24]);
put(app.SavepaintButton, paint, [6 4 78 24]);
app.UpButton.Visible = 'off';
app.LeftButton.Visible = 'off';
app.RightButton.Visible = 'off';
app.DownButton.Visible = 'off';

put(app.StagepositionLabel, p2, [6 T-340 90 22]);
put(app.GetPositionButton,  p2, [100 T-340 85 22]);
% the X/Y/Z labels and fields are cross-named in Design View: keep the pairs as shown there
put(app.XEditFieldLabel,           p2, [6 T-368 15 22]);
put(app.Stage_HardwareX_EditField, p2, [22 T-368 58 22]);
put(app.YEditFieldLabel,           p2, [84 T-368 15 22]);
put(app.Stage_HardwareZ_EditField, p2, [100 T-368 58 22]);
put(app.ZEditFieldLabel,           p2, [162 T-368 15 22]);
put(app.Stage_HardwareY_EditField, p2, [178 T-368 68 22]);
put(app.MinZEditFieldLabel, p2, [6 T-396 38 22]);
put(app.MinZEditField,      p2, [46 T-396 70 22]);

put(app.VerticaltileEditFieldLabel,   p2, [6 T-436 70 22]);
put(app.VerticaltileEditField,        p2, [78 T-436 35 22]);
put(app.HorizontaltileEditFieldLabel, p2, [118 T-436 88 22]);
put(app.HorizontaltileEditField,      p2, [208 T-436 35 22]);
put(app.CheckPointsEditFieldLabel,    p2, [6 T-464 78 22]);
put(app.CheckPointsEditField,         p2, [86 T-464 35 22]);
put(app.createscanpatterncenterButton, p2, [6 T-498 175 26]);
put(app.StatusLampLabel, p2, [184 T-496 40 22]);
put(app.StatusLamp,      p2, [226 T-495 20 20]);
put(app.GreensignalwillblockmotionexceptinzaxisLabel, p2, [6 T-524 240 22]);
app.GreensignalwillblockmotionexceptinzaxisLabel.Text = 'Green: only depth moves allowed';

%% 3 z bounds and focus per tile (full height, as wide as possible: many tiles)
put(app.movetotileSpinnerLabel, p3, [6 T3-30 70 22]);
put(app.movetotileSpinner,      p3, [80 T3-30 70 22]);
% (2026-11-20) start = smaller Y = sample close to the camera (was "Deep"),
% end = larger Y = away from the camera (was "Surface")
put(app.DeepLabel_2,                  p3, [6 T3-62 104 22]);
put(app.startofeachtileEditFieldLabel, p3, [108 T3-62 30 22]);
put(app.startofeachtileEditField,     p3, [140 T3-62 65 22]);
put(app.saveButton_3,                 p3, [212 T3-62 55 22]);
put(app.SurfaceLabel,                 p3, [6 T3-92 104 22]);
put(app.endofeachtileEditFieldLabel,  p3, [108 T3-92 30 22]);
put(app.endofeachtileEditField,       p3, [140 T3-92 65 22]);
put(app.saveButton_4,                 p3, [212 T3-92 55 22]);
app.DeepLabel_2.Text = 'Close to camera';
app.startofeachtileEditFieldLabel.Text = 'start';
app.SurfaceLabel.Text = 'Away from camera';
app.endofeachtileEditFieldLabel.Text = 'end';
put(app.savecheckpointsButton, p3, [6 T3-126 130 26]);
put(app.skiptilesButton,       p3, [142 T3-126 100 26]);
% (2026-11-20) Tile States box and label hidden: the tile table below shows the tiles. The
% box still holds the status text: start image all tiles checks that its first line ends
% with "Yes" (all tiles saved), so it is only hidden, not removed.
app.TileStatesTextAreaLabel.Visible = 'off';
app.TileStatesTextArea.Visible = 'off';
% (2026-11-20) per-tile focus of the detection (Obj) lens for the current tile and the
% current wavelength (setTileFocus / clearTileFocus in the app), the Focus editor window
% (focus by depth inside the current tile, selfmade/focusEditor.m), and the tile table
% (filled by refreshTileTable: start/end depth and the focus of each color per tile)
uibutton(p3, 'Text', 'Set tile focus', 'Position', [6 T3-160 130 26], ...
    'ButtonPushedFcn', @(src, event) setTileFocus(app));
uibutton(p3, 'Text', 'Tile focus = default', 'Position', [142 T3-160 150 26], ...
    'ButtonPushedFcn', @(src, event) clearTileFocus(app));
uibutton(p3, 'Text', 'Focus editor', 'Position', [298 T3-160 120 26], ...
    'ButtonPushedFcn', @(src, event) focusEditor(app));
app.TileFocusInfo = uilabel(p3, 'Position', [6 T3-188 412 22], ...
    'Text', 'Focus of the current tile and wavelength (Obj lens)');
app.TileTable = uitable(p3, 'Position', [6 48 412 T3-192-48], ...
    'ColumnName', {'#'; 'Start'; 'End'; '488'; '561'; '640'; '730'}, 'RowName', {}, ...
    'ColumnWidth', {30, 58, 58, 62, 62, 62, 62}, 'FontSize', 11, 'Data', cell(0, 7), ...   % # = tile
    'CellSelectionCallback', @(src, event) selectTileFromTable(app, event));   % click a row: go to that tile
put(app.importtilesButton, p3, [6 12 110 28]);
put(app.exporttilesButton, p3, [122 12 110 28]);

%% the two old panels are empty now
app.TakingimagesonMbyNtileswithzstacksPanel.Visible = 'off';
app.imageparametersPanel.Visible = 'off';

%% report components that are still on the window (not placed above)
names = properties(app);   % public properties: the components (the new panels are not among them)
left = {};
for i = 1:numel(names)
    try
        h = app.(names{i});
    catch
        continue;
    end
    if ~isa(h, 'matlab.graphics.Graphics') || ~isscalar(h) || ~isvalid(h) || isequal(h, fig)
        continue;
    end
    if isprop(h, 'Parent') && isequal(h.Parent, fig) && isprop(h, 'Visible') && strcmp(h.Visible, 'on')
        left{end+1} = names{i}; %#ok<AGROW>
    end
end
if ~isempty(left)
    fprintf('applyLayout: not placed (still at the Design View position): %s\n', strjoin(left, ', '));
end
end

function put(h, parent, pos)
h.Parent = parent;
h.Position = pos;
end
