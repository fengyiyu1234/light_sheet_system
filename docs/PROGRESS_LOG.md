# Progress log

Changes to the light-sheet control code, newest first. Each entry says what changed,
why, and where the backup is. Backups are in `_archive/`, which git does not track,
so they exist only on the disk where the edit was made.

---

## 2026-11-04: known-bugs table re-checked; local CLAUDE.md

- `docs/V5_app_guide.md` section 6 rewritten: every row was re-checked against the current
  app code. Split into "Open" (12 rows, with a priority) and "Fixed or disabled". New open rows:
  Reset keeps the old `app.dirname` (next run saves into the old folder), no camera timeout in
  `requestoneimagefromcamera`, Tenengrad autofocus has no wait after its final lens move,
  cancelling `uigetdir` sets `app.dirname = 0`, Paint canvas ~14.8 GB; the xlsx orientation
  bug also affects the new `9_Skipped_Grid` sheet.
- Added `CLAUDE.md` (notes for Claude Code: read this log first, backup/log rules). It is in
  `.gitignore`, so it stays on the research drive only.
- No code changed. Backup of the old guide: not needed (git has it).

---

## 2026-11-03: Paint tile count with overlap; centred scan pattern

Request: the tile count in the Painting View title ignored the 15% tile overlap, so it
under-counted the tiles that "create scan pattern" needs.

- New public methods in the app:
  - `scanOverlapPercent(app)`: returns 15. `createscanpatterncenterButtonPushed` now uses it
    instead of its own `overlap = 15`, so Paint and the scan pattern always use the same value.
  - `tilesNeeded(app, extent_px)`: tiles needed to cover `extent_px` pixels; n tiles cover
    2048 + (n-1)*2048*0.85 px.
- Paint, Up/Down/Left/Right and Center: the title (and the command-window print) shows the old
  value and the needed tile count in brackets, e.g. `vertical tile: 3 (4)  horizontal tile: 2.1 (3)`.
  The `V…_H…` numbers in the Save paint file name are unchanged (old value).
- `selfmade/createScanpattern.m`: tile offsets are now `(0:N-1) - (N-1)/2` steps, so the grid is
  centred on the current position for even tile counts too (before, an even grid was shifted
  half a step towards negative X/Z). Odd counts give the same positions as before; tile order
  is unchanged.
- Backups: `_archive/MMcodeOrcaV2/LightSheetControl_before_paint_tilecount.mlapp`,
  `_archive/MMcodeOrcaV2/createScanpattern_before_center.m`.
- Checks: `appModel.mat` rebuilt from `document.xml` (7 callbacks + editable section changed,
  as intended; a re-check finds no differences). `checkcode`: 0 syntax errors, 369 messages before
  and after. `tilesNeeded` (the app's own code) was checked for extents from 1 to 12 tiles: n tiles
  cover the extent and n-1 do not. `createScanpattern` was checked for 1-4 x 1-3 grids: the mean
  position is the current position. **Not tested on the microscope yet.**

---

## 2026-11-03: skip empty tiles (fill blank)

Request: after Paint, some tiles are empty, but each tile still needed a start/end at least
100 um apart, so empty tiles were imaged anyway. Now a tile can be marked as skipped.

- New public methods in the app:
  - `skipCurrentTile(app)`: marks the tile in `movetotileSpinner` as saved + skipped
    (`skip = true`, `start_pos`/`end_pos` = NaN, X/Y/Z from the stage now).
  - `skippedTiles(app)`: logical column, true for skipped tiles.
  - `updateTileStatus(app, tile_index)`: the status/text/print code that used to be at the end
    of `savecheckpointsButtonPushed`, now shared; shows skipped tiles as `n(skip)` / `n: skipped`.
    "min start / max end" now uses all saved imaged tiles (it used only tiles 1..current).
  - `fillSkippedTile(app, tile_index, zero_image)`: writes all-zero images for every layer of
    the global z grid (min start .. max end of the imaged tiles), for every selected color
    (640 nm Analog: every power/exposure folder). Folder and file names follow the imaging
    code; X/Z come from the saved position, the stage is not moved.
- `createscanpatterncenterButtonPushed`: every tile starts with `skip = false`.
- `savecheckpointsButtonPushed`: sets `skip = false` (re-saving un-skips a tile), then calls
  `updateTileStatus`.
- `startimagealltilesButtonPushed`: global `start_min`/`end_max` and the time estimate use the
  imaged tiles only; skipped tiles call `fillSkippedTile` and `continue` (no lasers, filter
  wheel, stage or autofocus); stops if every tile is skipped; Excel log gets sheet
  `9_Skipped_Grid` (1 = skipped).
- **TODO (Fengyi):** add the button "skip tile (fill blank)" next to "save checkpoints" in
  Design View; its callback is one line: `skipCurrentTile(app);`. Until then, the feature can
  only be reached from code.
- Backup: `_archive/MMcodeOrcaV2/LightSheetControl_before_skip_tile.mlapp`.
- Checks: `appModel.mat` rebuilt from `document.xml` (3 callbacks + editable section changed,
  as intended). `checkcode`: no errors; 368 warnings (was 360), the new ones are the same
  "tile_index is also a property name" notice as the old code. The four methods were run with a
  fake app on a 2x2 grid with tile 3 skipped: status text and prints correct, the imaging
  "all saved" check passes, 33 layers x 3 folders (488 + two 640 Analog folders) = 99 blank
  2048x2048 uint16 images with the expected names; re-saving tile 3 un-skipped it.
  **Not tested on the microscope yet.**

---

## 2026-11-03: reliable lens position reads (Ryan's "obj buttons don't update the table" bug)

Report (Ryan Garry, Oct 8-9): moving the objective with the left/right buttons moved the
focus, but the detection lens position in the table was not updated, so later samples were
blurry. It happened after imaging, and restarting the GUI did not fix it.

Cause:
1. Before the 2026-11 fix, `dynamic_focus` (Entropy) sent a `1TP?` and never read the reply.
   Each autofocus during imaging left one old position in the serial input buffer, so the
   buttons (send `1TP?`, read one line) showed an old position. The serial object lives in
   `controlParameters` in the base workspace, so restarting the GUI kept the buffer.
   Removing that query (see the 2026-11-03 cleanup entry) fixes the source.
2. (Possible, probably minor.) The buttons wait a fixed `pause(0.5)` (`pause(1)` for the
   excitation lens) before reading. `InitTheMotor` sends `1VA0.2` (0.2 units/s, assumed mm/s;
   not verified on the controller: it is sent right after `1OR`, check with `1VA?`). At that
   speed the largest steps (objective 0.01 mm, excitation 0.1 mm) finish within the pause,
   so this only matters if the real velocity is much lower. Cause 1 explains the report.

Change:
- New `MMcodeOrcaV2/selfmade/readLensPos.m`: discards the serial input buffer before every
  `1TP?` and reads until two reads in a row agree (motor stopped; 10 s timeout with a warning).
- Uses it in the app: `left/rightButtonObj`, `left/rightButtonExt`, `startupFcn`, and the
  position sync after `RunAutoFocusButtonPushed`.
- `saveoffsetfordifferentcolorButtonPushed` now reads both lens positions from the motors
  before saving, instead of trusting the motor table.
- Backup: `_archive/MMcodeOrcaV2/LightSheetControl_before_readLensPos.mlapp`.
- Checks: `appModel.mat` was rebuilt from `document.xml` (75 callbacks, 7 changed, as
  intended). `checkcode`: no errors, 360 warnings (was 369). `readLensPos` was tested with a
  simulated motor (stale replies in the buffer, motor still moving): it returned the final
  position. **Not tested on the real motors yet.**

---

## 2026-11-03: relative code paths (repo can be cloned into any folder)

- `init_hardware.m` and the app's `startupFcn` no longer `addpath` the hard-coded
  `D:\lightSheetsourcecode_twopath_multipower\...` folders. They find the folders from their
  own location instead (`mfilename('fullpath')` in the script, `which(class(app))` in the app).
- The app reads `states_record.xlsx` from its own folder, not from the current folder.
- Removed from the app's `addpath`: `DCMotor`, `UsefullFunctions\PickTiles`,
  `MMcodeOrcaV2\wholezstackfiles` (unused, already in `_archive/`).
- Still in the current folder: the outputs `scanpattern.mat` and `allpoints.mat`.
- The old copy `D:\lightSheetsourcecode_twopath_multipower` must stay on the saved MATLAB path
  because other people still use it. `init_hardware.m` therefore removes its folders with
  `rmpath` for the current session only (no `savepath`), and stops with an error if the
  current folder is inside the old copy. Restarting MATLAB restores the old path.
- Backups: `_archive/MMcodeOrcaV2/LightSheetControl_before_relative_paths.mlapp`,
  `_archive/MMcodeOrcaV2/init_hardware_before_relative_paths.m`.
- Checks: `appModel.mat` and `document.xml` match; `checkcode` shows the same warning count
  (369). The path logic was tested from a different current folder. Not tested on the microscope yet.

---

## 2026-11-03: print tile start/end depth when saving checkpoints

- `savecheckpointsButtonPushed`: the command window used to show only the list of saved
  tile numbers (`text_saved_list = 'Saved Tiles List: 1 2 3'`). It now prints the tile just
  saved with its start/end depth and stage X/Y/Z, then every saved tile as `n: start ~ end`.
  The Tile States text box in the app is unchanged.
- Backup: `_archive/MMcodeOrcaV2/LightSheetControl_before_tile_zprint.mlapp`.
- Checks: the code in `appModel.mat` and `document.xml` matches; `checkcode` reports no
  syntax errors. Not tested on the microscope yet.

---

## 2026-11-03: repo cleanup, renames, first bug fixes

Maintainer: Fengyi Yu. Edits were made on the analysis workstation copy
(`Y:\Fengyi\lightsheet_system`). The microscope PC copy
(`D:\lightSheetsourcecode_twopath_multipower`) has **not** been updated yet.

### Repository cleanup
- Moved 261 unused files (old app versions, test scripts, models, sample data) into
  `_archive/`, keeping their relative paths. Nothing was deleted. The full list is in
  `_archive/MANIFEST_moved_files.txt`.
- Checked with `matlab.codetools.requiredFilesAndProducts` that the remaining 21 files
  are everything the init script and the app need.
- Added `README.md`, `docs/V5_app_guide.md` and `.gitignore`. The `.gitignore` excludes
  `_archive/`, images, `.mat` files and runtime outputs.
- Added `config/configuration_03132026.cfg` as a backup of the Micro-Manager config.
  **Warning:** this copy is byte-identical to the 2019 `configuration_05302019.cfg`, so
  it is probably not the file the microscope really uses. Replace it with the copy from
  the microscope PC (see TODO).

### Renames
| Old name | New name |
|---|---|
| `MMcodeOrcaV2/app_for_lightsheet_V2_main_autofocus_autopower_V5.mlapp` | `MMcodeOrcaV2/LightSheetControl.mlapp` |
| `MMcodeOrcaV2/LightSheet_10x_02032026_RunAll2.m` | `MMcodeOrcaV2/init_hardware.m` |

`init_hardware.m` was also trimmed to about 310 lines. Its `addpath` now lists only the
folders that are used. Unused hardware blocks were removed, and the laser analog-mode
recovery code is kept as an optional section. The untrimmed original is
`_archive/MMcodeOrcaV2/LightSheet_10x_02032026_RunAll2_ORIGINAL_full.m`.

### Bug fixes
| Where | Problem | Fix |
|---|---|---|
| `LightSheetControl.mlapp`, `dynamic_focus` (Entropy autofocus) | Sent an extra `1TP?` query to the detection-lens motor and never read the reply. Each Entropy autofocus left one stale reply in the serial buffer, so every later lens-position read returned an old value, and the lag grew with each call. | Removed that query. |
| `selfmade/getpos.m` | Parsed motor replies in scientific notation wrongly: `1TP1.5e-04` was read as 1.5 mm. | Parses the whole number, and raises an error on an unreadable reply instead of returning a wrong value. Normal replies give the same result as before. |
| `createscanpatterncenterButtonPushed` | Creating a new scan pattern kept the tile start/end data from the previous pattern. | Clears `app.checkpoints_multipletile` and resets the tile-status text. |

### Features disabled (not used any more)
The code was commented out, not deleted, so it can be restored.

- **save_D** (`save_DButtonPushed`)
- **Rotation / T stage**: `Button_7Pushed`, `Button_8Pushed` and
  `Rotation_stepDropDownValueChanged`, plus the T-position reads in `startupFcn` and
  `GetPositionButtonPushed`
- **AFG table** (`UITable_afgCellEdit`). Offsets edited in the table were never applied
  anyway. The AFG parameters still load from `states_record.xlsx` sheet 4 into
  `app.state_afg` and are used as before. The imaging log
  (`imaging_params_*.xlsx`, sheet `3_AFG`) is now written from `app.state_afg`.
- **Histogram** (`SnapHistogramButtonPushed`). It always failed because
  `TargetIntensityEditField` does not exist.
- **Keyboard shortcuts** (`UIFigureKeyPress`). Keys `a`/`d`/`w`/`s` failed because
  `movecheckpoints1x6Spinner` does not exist.
- **Galvo_Z column** of the path and offset tables. The column is locked, and the edit
  branch that used the missing `galvo_ZSlider` is commented out.

The code no longer refers to the UI controls of these features, so they can now be
deleted in App Designer (see TODO).

### Backups made today (`_archive/MMcodeOrcaV2/`)
- `LightSheetControl_before_1TP_fix.mlapp`
- `LightSheetControl_before_hide_saveD_rotation.mlapp`
- `LightSheetControl_before_afg_hist_keys_galvoZ_scanpattern.mlapp`
- `LightSheetControl_before_remove_refs.mlapp`
- `selfmade/getpos_before_fix.m`

### Checks
After each `.mlapp` edit, the code in `appModel.mat` and in `document.xml` was compared:
75 callbacks, no differences. `checkcode` reported no syntax errors and the same
number of warnings as before (367). None of the changes have been tested on the
microscope yet.

### TODO
- [ ] In App Designer Design View, delete the unused controls and save:
      `UITable_afg`, `SnapHistogramButton`, `save_DButton`, `nm_D488`, `nm_D561`,
      `nm_D640`, `nm_DEditFieldLabel`, `nm_DEditField_2Label`, `nm_DEditFieldLabel_2`,
      `Button_7`, `Button_8`, `Rotation_stepDropDown`, `Rotation_stepDropDownLabel`,
      `Stage_HardwareT_EditField`, `TEditFieldLabel`. Then delete any callbacks they
      leave behind.
- [ ] Replace `config/configuration_03132026.cfg` with the real file from the microscope PC
      (`C:\Program Files\Micro-Manager-1.4\configuration_03132026.cfg`).
- [ ] Copy `javaclasspath.txt` and `librarypath.txt` from the microscope PC's MATLAB
      `prefdir` into `config/`.
- [ ] Delete the old `app_for_lightsheet_V2_main_autofocus_autopower_V5.mlapp` if it is still there.
- [ ] Make the first git commit and push to `github.com/fengyiyu1234/light_sheet_system` (private).
- [ ] Copy the updated files to the microscope PC and test: start-up, Live View, autofocus
      (both methods), create scan pattern, and a short multi-tile run.
- [x] Update the known-bugs table in `docs/V5_app_guide.md` (done 2026-11-04).

### Known bugs still open
- `StopAnalogButtonPushed` and the end of `SvAFG2ButtonPushed` call
  `ChangePowerObis(lz, 1, target_mW)` with the arguments in the wrong order, so the
  640 nm laser goes back to 1 mW.
- `RollScanButtonValueChanged` writes to `controlParameters.afg` without `app.`, so
  Roll Scan errors out.
- Tenengrad autofocus does not pause after its final lens move.
- The `catch` block of `startimagealltilesButtonPushed` checks
  `exist('app.waitbar','var')`, which is always false, so the progress window stays
  open after an error.
- In the imaging log xlsx, the start/end/slice grids are reshaped in the wrong
  orientation. This affects the log only, not the images.
- Paint Mode allocates a very large canvas (about 14.8 GB), and `imshow` is called
  without `Parent`.
- Others are listed in `docs/V5_app_guide.md`, section 6: Reset does not clear the
  save folder, cancelling `uigetdir` is not handled, and there is no camera timeout.
