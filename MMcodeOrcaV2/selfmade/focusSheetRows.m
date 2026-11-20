function rows = focusSheetRows(checkpoints, defaultFocus, selected)
% FOCUSSHEETROWS  Contents of sheet 10_Focus of imaging_params_*.xlsx.
%   rows = focusSheetRows(checkpoints, defaultFocus, selected) returns a cell
%   array with a header row and one row per imaged tile and selected color:
%     Tile, Color, From_um, To_um, DetLens_mm, Source
%   From_um / To_um : the depth range the focus is used for (tile start .. end,
%                     one row per depth segment, see focusSegments).
%   DetLens_mm      : detection lens position used for imaging.
%   Source          : 'segment' (Focus editor), 'tile' ("Set tile focus") or
%                     'default' (offset table).
%   checkpoints  = app.checkpoints_multipletile
%   defaultFocus = Detection column of the offset table (4 values, 488/561/640/730)
%   selected     = 4 logical values: colors to image (W488nm .. W730nm check boxes)
%   Skipped and unsaved tiles are not imaged and have no rows.
%   (2026-11-20, MATLAB R2019a compatible.)

colors = {'488nm', '561nm', '640nm', '730nm'};
sources = {'default', 'tile', 'segment'};      % focusSegments source 0, 1, 2
defaultFocus = double(defaultFocus(:)');
selected = logical(selected(:)');
rows = {'Tile', 'Color', 'From_um', 'To_um', 'DetLens_mm', 'Source'};
for i = 1:numel(checkpoints)
    c = checkpoints(i);
    if ~(isfield(c, 'saved') && isequal(c.saved, true)) || (isfield(c, 'skip') && isequal(c.skip, true))
        continue;
    end
    for k = find(selected)
        segs = focusSegments(checkpoints, i, k, c.start_pos, c.end_pos, defaultFocus);
        for s = 1:size(segs, 1)
            rows(end+1, :) = {i, colors{k}, segs(s,1), segs(s,2), segs(s,3), sources{segs(s,4)+1}}; %#ok<AGROW>
        end
    end
end
end
