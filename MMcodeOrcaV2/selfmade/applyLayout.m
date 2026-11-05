function applyLayout(app)
% APPLYLAYOUT  Rearrange LightSheetControl by workflow (called once from startupFcn).
%
%   (2026-11-04) The Design View layout is not changed. At startup this function
%   creates 5 panels and moves the existing components into them (only Parent,
%   Position and a few display properties change; callbacks are untouched):
%     top bar : light path, wavelength, power, filter, shutter, camera, exposure, ...
%     1 Channel tuning : galvo X/Y (slider + left/right + step), lenses, path/motor/offset tables
%     2 Stage + Paint (XY) : stage arrows and steps, stage position, Paint, tile grid
%     3 Z per tile : move to tile, start/end, save checkpoints, Tile States
%     4 Acquisition : colors, power/exposure, z step, 640 nm tools, directory, start
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

colTop = [0.90 0.90 0.90];
col1   = [0.88 0.96 0.88];          % 1 channel tuning: green
col2   = [0.88 0.93 1.00];          % 2 stage + paint: blue
col3   = [1.00 0.97 0.85];          % 3 z per tile: yellow
col4   = [1.00 1.00 1.00];          % 4 acquisition: white

pTop = uipanel(fig, 'Position', [5 880 950 75], 'BackgroundColor', colTop);
p1 = uipanel(fig, 'Title', '1. Channel tuning (galvo, lenses, offsets)', ...
    'Position', [5 245 313 630], 'BackgroundColor', col1, 'FontWeight', 'bold');
p2 = uipanel(fig, 'Title', '2. Stage + Paint (XY bounds)', ...
    'Position', [323 245 313 630], 'BackgroundColor', col2, 'FontWeight', 'bold');
p3 = uipanel(fig, 'Title', '3. Z bounds per tile', ...
    'Position', [641 245 314 630], 'BackgroundColor', col3, 'FontWeight', 'bold');
p4 = uipanel(fig, 'Title', '4. Acquisition', ...
    'Position', [5 5 950 235], 'BackgroundColor', col4, 'FontWeight', 'bold');
T  = 605;                            % top of the usable area inside p1..p3 (630 minus the title)
T4 = 210;                            % same for p4

%% top bar
put(app.LightPathDropDownLabel, pTop, [8 40 60 22]);
put(app.LightPathDropDown,      pTop, [70 40 70 22]);
put(app.WavelengthLabel,        pTop, [150 34 160 34]);   % coloured by wavelength; the dropdown sits on it
put(app.Lightwavelight,         pTop, [225 40 80 22]);
put(app.LaserPowermWEditFieldLabel, pTop, [320 40 100 22]);
put(app.LaserPower,             pTop, [422 40 40 22]);
put(app.FilterwheelDropDownLabel, pTop, [475 40 67 22]);
put(app.Filterwheel,            pTop, [544 40 110 22]);
put(app.ShutterButton,          pTop, [665 40 70 22]);
put(app.EnableCam,              pTop, [745 40 95 22]);
put(app.DisableCam,             pTop, [845 40 97 22]);
put(app.Exposure_timeEditFieldLabel, pTop, [8 8 86 22]);
put(app.Exposure_timeEditField, pTop, [96 8 55 22]);
put(app.ImagecontrastLabel,     pTop, [165 8 85 22]);
put(app.Imagecontrast,          pTop, [252 8 55 22]);
put(app.ShowGridCheckBox,       pTop, [325 8 85 22]);
put(app.SaveImage,              pTop, [420 8 130 22]);
put(app.AutoFocusDropDownLabel, pTop, [570 8 66 22]);
put(app.AutoFocusDropDown,      pTop, [640 8 130 22]);

%% 1 channel tuning
stepItems = {'0.1', '0.05', '0.01', '0.005', '0.001'};   % galvo step (V) for the left/right buttons
put(app.galvo_XSliderLabel, p1, [6 T-32 50 22]);
put(app.galvo_XSlider,      p1, [62 T-20 115 3]);
app.galvo_XSlider.MajorTicks = -0.4:0.2:0.4;
app.galvo_XSlider.MinorTicks = -0.4:0.1:0.4;
ddX = uidropdown(p1, 'Items', stepItems, 'Value', '0.01', 'Position', [250 T-32 56 24]);
uibutton(p1, 'Text', char(9664), 'Position', [185 T-32 30 24], ...
    'ButtonPushedFcn', @(src, event) galvoStep(app, 'X', -str2double(ddX.Value)));
uibutton(p1, 'Text', char(9654), 'Position', [217 T-32 30 24], ...
    'ButtonPushedFcn', @(src, event) galvoStep(app, 'X',  str2double(ddX.Value)));

put(app.galvo_YSliderLabel, p1, [6 T-82 50 22]);
put(app.galvo_YSlider,      p1, [62 T-70 115 3]);
app.galvo_YSlider.MajorTicks = -0.6:0.3:0.6;
app.galvo_YSlider.MinorTicks = -0.6:0.1:0.6;
ddY = uidropdown(p1, 'Items', stepItems, 'Value', '0.01', 'Position', [250 T-82 56 24]);
uibutton(p1, 'Text', char(9664), 'Position', [185 T-82 30 24], ...
    'ButtonPushedFcn', @(src, event) galvoStep(app, 'Y', -str2double(ddY.Value)));
uibutton(p1, 'Text', char(9654), 'Position', [217 T-82 30 24], ...
    'ButtonPushedFcn', @(src, event) galvoStep(app, 'Y',  str2double(ddY.Value)));

put(app.Reset_galvo_XYButton, p1, [6 T-122 110 24]);
put(app.AFG_scanButton,       p1, [122 T-122 90 24]);

lens = app.ExcitationLensandDetectionLensPanel;
put(lens, p1, [6 T-222 300 90]);
put(app.ExtStepsizeDropDownLabel, lens, [6 40 78 22]);
put(app.ExtStepsizeDropDown,      lens, [86 40 62 22]);
put(app.leftButtonExt,            lens, [156 40 64 22]);
put(app.rightButtonExt,           lens, [226 40 64 22]);
put(app.ObjStepsizeDropDownLabel, lens, [6 8 78 22]);
put(app.ObjStepsizeDropDown,      lens, [86 8 62 22]);
put(app.leftButtonObj,            lens, [156 8 64 22]);
put(app.rightButtonObj,           lens, [226 8 64 22]);

% Galvo_Z is not used: its column stays in the data (it is sent to the DAQ) but is not shown
put(app.UITable_path,  p1, [6 T-325 150 96]);
app.UITable_path.FontSize = 12;
app.UITable_path.ColumnWidth = {44, 50, 50, 0};
put(app.UITable_motor, p1, [160 T-325 146 96]);
app.UITable_motor.FontSize = 12;
app.UITable_motor.ColumnWidth = {44, 84};
put(app.UITable_offset, p1, [6 T-475 300 145]);
app.UITable_offset.FontSize = 12;
app.UITable_offset.ColumnWidth = {48, 54, 54, 0, 64, 64};
put(app.saveoffsetfordifferentcolorButton, p1, [6 T-508 200 26]);

% Roll is not used: hidden (callbacks unchanged)
app.RollSlider.Visible = 'off';
app.RollSliderLabel.Visible = 'off';
app.RollScanButton.Visible = 'off';

%% 2 stage + paint
% arrow cluster, same relative positions as in Design View
arrows = {app.Button, app.Button_4, app.Button_3, app.Button_5, app.Button_6, app.Button_2};
for i = 1:numel(arrows)
    pos = arrows{i}.Position;
    put(arrows{i}, p2, [pos(1)-23, pos(2)-857+(T-135), pos(3), pos(4)]);
end
put(app.Updown_stepDropDownLabel,    p2, [184 T-40 56 22]);
put(app.Updown_stepDropDown,         p2, [242 T-40 66 22]);
put(app.Leftright_stepDropDownLabel, p2, [184 T-72 56 22]);
put(app.Leftright_stepDropDown,      p2, [242 T-72 66 22]);
put(app.Inout_stepDropDownLabel,     p2, [184 T-104 56 22]);
put(app.Inout_stepDropDown,          p2, [242 T-104 66 22]);
app.Updown_stepDropDownLabel.Text = 'Up/Down';
app.Leftright_stepDropDownLabel.Text = 'Left/Right';
app.Inout_stepDropDownLabel.Text = 'In/Out';

put(app.StagepositionLabel, p2, [6 T-170 90 22]);
put(app.GetPositionButton,  p2, [100 T-170 85 22]);
put(app.MinZEditFieldLabel, p2, [195 T-170 38 22]);
put(app.MinZEditField,      p2, [235 T-170 70 22]);
% the X/Y/Z labels and fields are cross-named in Design View: keep the pairs as shown there
put(app.XEditFieldLabel,           p2, [6 T-200 15 22]);
put(app.Stage_HardwareX_EditField, p2, [22 T-200 75 22]);
put(app.YEditFieldLabel,           p2, [105 T-200 15 22]);
put(app.Stage_HardwareZ_EditField, p2, [121 T-200 75 22]);
put(app.ZEditFieldLabel,           p2, [205 T-200 15 22]);
put(app.Stage_HardwareY_EditField, p2, [221 T-200 84 22]);

paint = app.PaintModePanel;
put(paint, p2, [6 T-375 300 160]);
put(app.PaintButton,     paint, [10 98 75 24]);
put(app.CenterButton,    paint, [10 56 75 24]);
put(app.SavepaintButton, paint, [10 14 75 24]);
put(app.UpButton,        paint, [158 96 60 34]);
put(app.LeftButton,      paint, [96 54 58 34]);
put(app.RightButton,     paint, [222 54 58 34]);
put(app.DownButton,      paint, [158 12 60 34]);

put(app.VerticaltileEditFieldLabel,   p2, [6 T-410 70 22]);
put(app.VerticaltileEditField,        p2, [78 T-410 35 22]);
put(app.HorizontaltileEditFieldLabel, p2, [124 T-410 82 22]);
put(app.HorizontaltileEditField,      p2, [208 T-410 35 22]);
put(app.CheckPointsEditFieldLabel,    p2, [6 T-440 78 22]);
put(app.CheckPointsEditField,         p2, [86 T-440 35 22]);
put(app.createscanpatterncenterButton, p2, [6 T-474 175 26]);
put(app.StatusLampLabel, p2, [190 T-472 40 22]);
put(app.StatusLamp,      p2, [234 T-471 20 20]);
put(app.GreensignalwillblockmotionexceptinzaxisLabel, p2, [6 T-500 300 22]);

%% 3 z per tile
put(app.movetotileSpinnerLabel, p3, [6 T-30 70 22]);
put(app.movetotileSpinner,      p3, [80 T-30 70 22]);
put(app.DeepLabel_2,                  p3, [6 T-62 34 22]);
put(app.startofeachtileEditFieldLabel, p3, [42 T-62 95 22]);
put(app.startofeachtileEditField,     p3, [140 T-62 65 22]);
put(app.saveButton_3,                 p3, [212 T-62 55 22]);
put(app.SurfaceLabel,                 p3, [6 T-92 47 22]);
put(app.endofeachtileEditFieldLabel,  p3, [53 T-92 85 22]);
put(app.endofeachtileEditField,       p3, [140 T-92 65 22]);
put(app.saveButton_4,                 p3, [212 T-92 55 22]);
put(app.savecheckpointsButton, p3, [6 T-126 130 26]);
put(app.skiptilesButton,       p3, [142 T-126 100 26]);
put(app.TileStatesTextAreaLabel, p3, [6 T-156 80 22]);
put(app.TileStatesTextArea,      p3, [6 48 300 T-160-48]);
app.TileStatesTextArea.FontName = 'Courier New';   % fixed width: the tile list is in columns
app.TileStatesTextArea.FontSize = 11;
put(app.importtilesButton, p3, [6 12 110 28]);
put(app.exporttilesButton, p3, [122 12 110 28]);

%% 4 acquisition
put(app.ChoosewhichcolortoimageLabel, p4, [6 T4-28 80 22]);
app.ChoosewhichcolortoimageLabel.Text = 'Colors';
colors = {'488', '561', '640', '730'};
for i = 1:4
    x = 90 + (i-1)*70;
    put(app.(['W' colors{i} 'nmCheckBox']),          p4, [x T4-28 68 22]);
    put(app.(['Power_' colors{i} 'EditField']),      p4, [x T4-56 50 22]);
    put(app.(['Exposure_' colors{i} 'EditField']),   p4, [x T4-84 50 22]);
    if i == 1   % one row label per row, the other labels are hidden
        put(app.(['Power_' colors{i} 'EditFieldLabel']),    p4, [6 T4-56 80 22]);
        put(app.(['Exposure_' colors{i} 'EditFieldLabel']), p4, [6 T4-84 80 22]);
        app.(['Power_' colors{i} 'EditFieldLabel']).Text = 'Power';
        app.(['Exposure_' colors{i} 'EditFieldLabel']).Text = 'Exposure';
    else
        app.(['Power_' colors{i} 'EditFieldLabel']).Visible = 'off';
        app.(['Exposure_' colors{i} 'EditFieldLabel']).Visible = 'off';
    end
end

put(app.z_step_sizeumLabel,                 p4, [380 T4-28 146 22]);
put(app.zstack_distanceum,                  p4, [530 T4-28 45 22]);
put(app.AutoFocusStepSizeumEditFieldLabel,  p4, [380 T4-56 146 22]);
put(app.AutoFocusStepSizeumEditField,       p4, [530 T4-56 45 22]);
app.z_step_sizeumLabel.HorizontalAlignment = 'left';
app.AutoFocusStepSizeumEditFieldLabel.HorizontalAlignment = 'left';

% 640 nm Analog tools: only moved (CLAUDE.md rule 7)
put(app.SvAFG2Button,            p4, [588 T4-24 79 22]);
put(app.Mode640nmDropDownLabel,  p4, [672 T4-24 72 22]);
put(app.Mode640nmDropDown,       p4, [748 T4-24 74 22]);
put(app.StopAnalogButton,        p4, [828 T4-24 85 22]);
put(app.ListofLaserPowerstogenerateHDRimageMin1Max20Label, p4, [588 T4-46 355 20]);
put(app.HDPRTable,               p4, [588 70 355 92]);
app.HDPRTable.ColumnWidth = {68, 68, 68, 68};

put(app.ImagesavingdirectoryButton, p4, [6 38 140 24]);
put(app.pathEditField,              p4, [152 38 690 24]);
put(app.OpenPathButton,             p4, [848 38 90 24]);
put(app.ResetImagingButton,         p4, [6 4 110 28]);
put(app.startimagealltilesButton,   p4, [700 3 238 32]);
app.startimagealltilesButton.FontSize = 14;
app.startimagealltilesButton.FontWeight = 'bold';
app.startimagealltilesButton.BackgroundColor = [0.47 0.67 0.19];
app.startimagealltilesButton.FontColor = [1 1 1];

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
