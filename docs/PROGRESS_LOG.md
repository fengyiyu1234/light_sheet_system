# Progress log

Changes to the light-sheet control code, newest first. Each entry says what changed,
why, and where the backup is. Backups are in `_archive/`, which git does not track,
so they exist only on the disk where the edit was made.

---

## 2026-11-07: top bar reordered; Galvo_Z column removed from the offset table (0 V sent)

Request: Light Path and Shutter are hardly used, move them to the right; Laser Power and Filter
wheel are used often. Remove the Galvo_Z column of the offset table. Fengyi: Galvo_Z (light-sheet
roll) has always been 0 (a rotated sheet is no longer parallel to the focal plane), so all
colors use 0; agreed to write 0 in the imaging code instead of reading the table.

- `selfmade/applyLayout.m`: top bar row 2 left = Wavelength, "Power(mW)", "Filter" (labels
  shortened); Light Path + Shutter on the right of row 2. Enable/Disable Camera moved 20 px right
  (x 400-610); Save Image / AutoFocus in row 3 right narrowed slightly. Offset table: `ColumnName`
  set to `Offset, Galvo_X, Galvo_Y, Detection, Excitation` (Design View has 6 fixed names, which
  would otherwise be shown over the wrong columns), `ColumnWidth` 5 values.
- `.mlapp` (`appModel.mat` + `document.xml`):
  - `startupFcn`: after reading sheet 5, `app.state_offset.Galvo_Z = []` (if present), so
    `UITable_offset.Data` has 5 columns and `UITable_offsetCellEdit` indices still match
    `app.state_offset`. `ColumnEditable` = `[false true true true true]`. `states_record.xlsx`
    is unchanged (still has the column; it is not written back).
  - `startimagealltilesButtonPushed`: all 13 `app.UITable_offset.Data.Galvo_Z(k)` -> `0`
    (DAQ roll channel; the values were all 0 in `states_record.xlsx`, so the output is the same).
    This includes one shared line of the 640 nm block (line ~3147, before the imaging loop) and the
    error handler; the 640 nm Analog logic itself is not changed (approved by Fengyi, 2026-11-07).
    The imaging parameter file sheet `1_Offset` now has 5 columns.
- `appModel.mat` edited with R2019a by loading only `code` and `save -append` (R2019a cannot load
  the `StylesMetaData` objects in `components`); raw MAT elements compared: `components`,
  `appData` and the header element byte-identical, only `code` changed. Re-zipped with .NET in
  the original entry order. R2026b on this PC has no `matlab.exe` (incomplete install).
- Backup: `_archive/MMcodeOrcaV2/LightSheetControl_before_galvoz_topbar.mlapp`,
  `_archive/MMcodeOrcaV2/selfmade/applyLayout_before_galvoz_topbar.m`,
  `_archive/docs/PROGRESS_LOG_before_galvoz_topbar.md`, `_archive/docs/V5_app_guide_before_galvoz_topbar.md`.
- Checks: 72/72 code blocks verbatim in `document.xml`; no `UITable_offset.Data.Galvo_Z(k)` left;
  unzipped `.mlapp` matches the edited files; checkcode R2019a 346 -> 346 (only the 3 ALIGN
  notices moved); `applyLayout.m` 0 messages, ASCII; `minimumSupportedMATLABRelease` R2018a.
  Screenshot of a fake window (`createComponents` + `applyLayout`, R2019a): top bar does not
  overlap, labels not cut off; offset table shows 5 correct headers. Filter shows
  "reject 4..." for the multi-notch item (the dropdown is 88 px wide); the other filters fit.
  The offset table's horizontal scrollbar was there before this change too.
- **Not tested on the microscope.** To check there: layout as described; offset table shows 5
  columns with the right values; editing Galvo_X/Y, Detection, Excitation in the table still
  works; an imaging run works for every color (incl. 640 nm Serial and Analog).

---

## 2026-11-06: shutter stays open after Disable Camera and Paint off

Request: the shutter is hardly ever closed while using the UI, so Disable Camera should leave it
open; Paint may also leave it open; the shutter handling during imaging must not change.

- `.mlapp` (`appModel.mat` + `document.xml`):
  - `DisableCamButtonPushed`: the shutter-close block (`Shutterstate1 = 0`, `outputSingleScan`,
    `ShutterButton.Value = 0`) removed; it now only stops the live loop, closes the window and
    stops the camera. Lasers and shutter are left as they are.
  - `PaintButtonValueChanged`: Paint on sets `app.Shutterstate1 = 4` and `ShutterButton.Value = 1`
    and sends that (before: literal `4`, state not updated); Paint off no longer sends `0`
    (shutter stays open). Fixes the Paint part of bug 13.
  - `startimagealltilesButtonPushed` unchanged (640 nm Analog untouched).
- Edited by MATLAB script (whole old callback text found once in `document.xml`); re-zipped with
  .NET in the original entry order.
- Backup: `_archive/MMcodeOrcaV2/LightSheetControl_before_shutter_open.mlapp`,
  `_archive/docs/PROGRESS_LOG_before_shutter_open.md`, `_archive/docs/V5_app_guide_before_shutter_open.md`.
- Checks: 72/72 blocks of `appModel.mat` verbatim in `document.xml`; unzipped `.mlapp` matches the
  edited files; checkcode R2026b and R2019a: no new message (only ALIGN line shifts);
  `minimumSupportedMATLABRelease` R2018a.
- **Not tested on the microscope.** To check there: after Disable Camera and after Paint off the
  shutter is still open and the laser on; the Shutter button shows pressed after Enable / Paint on.

---

## 2026-11-06: where the shutter opens/closes (question only); bug 13 found

Question from Fengyi: is the shutter always open except for the Shutter button? Does wavelength
"None" close it?

- Read the code: shutter = DAQ `Board0/Ao1`, 4 V open / 0 V closed, sent as the first value of
  every `outputSingleScan` on `s1`; state in `app.Shutterstate1` (0 at startup).
  Opens: Shutter button, Enable Camera, Light Path = path1, Paint on, imaging (per channel).
  Closes: Shutter button, Disable Camera, Paint off, imaging (between channels, at the end, on error).
  Wavelength (incl. "None"), galvo sliders/buttons, Reset galvo and the path table only resend
  the current `app.Shutterstate1`; "None" switches the lasers off but does not touch the shutter.
- Found bug 13 (added to `V5_app_guide.md` 6.1): Paint and imaging set the shutter directly
  without updating `app.Shutterstate1`, so a later galvo move / wavelength change can reopen it.
- Backup: `_archive/docs/*_before_cam_top.md` (taken before the previous entry; only this entry
  and one table row added since). No code changed; nothing to test on the microscope.

---

## 2026-11-06: saving directory at the top, Enable/Disable Camera large in the centre; Disable Camera leaves lasers on

Request: put the data output path setting at the very top; put Enable/Disable Camera at the top,
near the centre (used very often); Disable Camera switched the lasers off, which is inconvenient:
decouple the two.

- `selfmade/applyLayout.m`: top bar 75 -> 107 px high. Row 1: "Image saving directory" +
  path field + "Open Path" (moved from panel 4). Rows 2-3: Enable / Disable Camera as two
  large buttons (103 x 58, bold 12 pt) in the centre (x 380-590); left of them light path,
  wavelength, Shutter / exposure, contrast, AFG_scan; right of them laser power, filter wheel /
  Save Image, AutoFocus. Panels 1-3 moved down 32 px (contents unchanged); panel 4 32 px lower
  (`T4` 210 -> 178), HDR table moved down into the freed row.
- `.mlapp` (`appModel.mat` + `document.xml`):
  - `DisableCamButtonPushed`: the loop that switched all 4 lasers off is removed. It still stops
    the live loop, closes the window, stops the camera and closes the shutter (so no light on
    the sample). Lasers are switched off with wavelength "None" (unchanged), and the imaging
    run still switches them off at the end. New: `ShutterButton.Value = 0`.
  - `EnableCamButtonPushed` (path 1): new `ShutterButton.Value = 1` after the shutter state is
    set (the button now shows the real shutter state). Laser switching in Enable unchanged.
  - No change to `startimagealltilesButtonPushed` or other 640 nm Analog code.
- Edited by MATLAB script (whole old callback text found once in `document.xml`, replaced in both
  files); re-zipped with .NET in the original entry order.
- Backup: `_archive/MMcodeOrcaV2/LightSheetControl_before_cam_decouple.mlapp`,
  `_archive/MMcodeOrcaV2/selfmade/applyLayout_before_cam_top.m`,
  `_archive/docs/PROGRESS_LOG_before_cam_top.md`, `_archive/docs/V5_app_guide_before_cam_top.md`.
- Checks: editable section, startup and all 70 callbacks of `appModel.mat` appear verbatim in
  `document.xml` (72/72 blocks); unzipped new `.mlapp` matches the edited files; checkcode
  R2026b and R2019a: no new message (only the 3 ALIGN line shifts); `applyLayout.m` 0 messages,
  still ASCII; `minimumSupportedMATLABRelease` R2018a. Screenshot of a fake window built from
  `createComponents` + `applyLayout` (R2026b): nothing overlaps, "Disable Camera" not cut off.
- **Not tested on the microscope.** To check there: layout as described; Disable Camera closes
  the live window and the shutter but the laser stays on (OBIS LED); Enable Camera again shows
  an image at once; the Shutter button shows pressed after Enable and released after Disable.

---

## 2026-11-05: Show Grid and AFG scan swap places

Request: swap the positions of the "Show Grid" check box and the "AFG scan" button in the UI.

- `selfmade/applyLayout.m` only (the layout is set at startup, the `.mlapp` is unchanged):
  `AFG_scanButton` now in the top bar at `[325 8 85 22]` (where Show Grid was);
  `ShowGridCheckBox` now in panel 1 next to "Reset galvo XY" at `[126 T-121 85 22]`.
  Callbacks unchanged.
- Backup: `_archive/MMcodeOrcaV2/selfmade/applyLayout_before_swap_grid_afg.m`,
  `_archive/docs/PROGRESS_LOG_before_swap_grid_afg.md`.
- Checks: checkcode R2026b 0 messages; file still ASCII.
- **Not tested on the microscope.** To check there: the two controls appear in the swapped
  places, the text is not cut off, and both still work.

---

## 2026-11-05: path and motor tables merged into one 1x4 table

Request: the path table (Path / Galvo_X / Galvo_Y) and the lens table (Lens / Position(mm))
were too redundant; replace them with one table with columns GalvoX, GalvoY, Excitation,
Detection (header + one row).

- New public method `refreshPathMotorTable(app)`: `UITable_path.Data` =
  `[state_path.Galvo_X(1), state_path.Galvo_Y(1), state_motor.MotorPosition_mm_(1), state_motor.MotorPosition_mm_(3)]`
  (path 1, ExtLens1, detection lens). All 4 `UITable_path.Data = app.state_path` and 6
  `UITable_motor.Data = app.state_motor` lines now call it (the two in `startupFcn` became one
  call). `app.state_path` / `app.state_motor` themselves are unchanged (DAQ output, offsets,
  autofocus still use them).
- `startupFcn`: `UITable_path.ColumnName = {'GalvoX'; 'GalvoY'; 'Excitation'; 'Detection'}`,
  all 4 columns editable (set in code, so the Design View table was not changed).
- `UITable_pathCellEdit` rewritten: columns 1-2 set galvo X/Y of path 1 (same checks and DAQ
  output as before; the path-2 branch is gone since path 2 is not shown); columns 3-4 send
  `1PA` to ExtLens1 / the detection lens (same 0.00001-10 mm check as the old
  `UITable_motorCellEdit`) and then **read the real position with `readLensPos`** into
  `state_motor` (the old motor table never updated `state_motor` after an edit). On a rejected
  value the table is refreshed back to the stored value before the error.
- `selfmade/applyLayout.m`: `UITable_path` at `[6 T-284 300 56]`, column widths 70/70/76/76;
  `UITable_motor` hidden (`Visible off`; its callback is now unused); the offset table and
  "save offset" button moved up 37 px into the freed space.
- Edited by script (`appModel.mat` editable section + startup + callbacks, and `document.xml`;
  every replacement found the same number of times in both); re-zipped with .NET in the
  original entry order. Note for scripts: `strsplit(..., newline)` must use
  `'CollapseDelimiters', false`, otherwise blank lines are dropped and the check fails.
- Backup: `_archive/MMcodeOrcaV2/LightSheetControl_before_merge_tables.mlapp`,
  `_archive/MMcodeOrcaV2/selfmade/applyLayout_before_merge_tables.m`,
  `_archive/docs/*_before_merge_tables.md`.
- Checks: editable section, startup and all 70 callbacks of `appModel.mat` appear verbatim in
  `document.xml`; the unzipped new `.mlapp` matches the edited files; checkcode R2026b
  366 -> 366 and R2019a 347 -> 347 (only line shifts of the 3 ALIGN notices); applyLayout 0
  messages; `minimumSupportedMATLABRelease` R2018a. A test uitable with the same settings shows
  header + one row without a scroll bar (R2026b).
- **Not tested on the microscope.** To check there: the table shows the four values at
  startup; moving the galvo sliders/◀▶, the lens ◀/▶ buttons and choosing a colour update it;
  typing a value in each of the four cells moves the galvo / lens and the cell then shows the
  read-back position.

---

## 2026-11-05: Tenengrad autofocus waits for the lens after its last move (bug 4)

Request: fix "Tenengrad autofocus has no wait after its final lens move".

- `dynamic_focus`, Tenengrad branch: after each of the three `1PA` moves at the end (final
  move to the fitted peak; move back when the peak is at the edge of the scan; move back in
  the `catch`) it now calls `readLensPos(app.controlParameters.sDetLens)`, which waits until
  two position reads in a row agree (motor stopped; 10 s timeout with a warning). Chosen
  instead of a fixed `pause`, because the move back from the edge of the scan can be up to
  120 um (about 0.6 s at `1VA0.2`). The scan loop (`pause(0.15)` per 5 um step) and the
  Entropy branch are unchanged.
- `dynamic_focus` is also called in the 640 nm Analog imaging, so that mode now waits the same
  way after autofocus; no line of `startimagealltilesButtonPushed` was changed.
- Small side effect: if `readLensPos` fails (unreadable motor reply, `getpos` error) after the
  final move, the `catch` moves the lens back to the offset, as for any other error there.
- Edited by script (`appModel.mat` editable section + `document.xml`, each text found once);
  re-zipped with .NET in the original entry order (MATLAB R2026b on the workstation has no Java).
- Backup: `_archive/MMcodeOrcaV2/LightSheetControl_before_tenengrad_wait.mlapp`;
  `_archive/docs/*_before_tenengrad_wait.md`.
- Checks: editable section, startup and all 70 callbacks of `appModel.mat` appear verbatim in
  `document.xml`; the unzipped new `.mlapp` matches the edited files byte for byte; checkcode
  365 -> 365; `minimumSupportedMATLABRelease` R2018a.
- **Not tested on the microscope.** To check there: after a Tenengrad autofocus during imaging,
  the command window shows "Autofocus complete. Moved to: ..." and imaging goes on without a
  `readLensPos:notSettled` warning; the first slices of the tile are not blurred.

---

## 2026-11-05: microscope test of skip tile (commit cc5a716): data checked, no problems

Request: Fengyi ran a test on the microscope with the code before the UI change; check the data
in `W:\Fengyi\test_tscff6` for problems.

- Code version: the run started 2026-11-04 15:47, so it used commit `cc5a716` (skip button
  added). That version has no tile export/import or log file, so the missing `Tiles`/`Grid`
  sheets and `matlab_log_*.txt` are expected. **`bb6395f` (export/import tiles, Paint grid,
  log) and the new layout (`applyLayout`) are still not tested on the microscope.**
- Run: 2 x 2 tiles, 488 / 561 / 640 Analog (power5 and power15) / 730, z step 20 um, one tile
  skipped (`9_Skipped_Grid`); 72 min (4306 s).
- Checked (MATLAB script, all 4420 images): every tile folder has 221 images,
  2048x2048 uint16, z 272000-316000 in steps of 200; blank frames are all zero and are
  exactly where the xlsx start/end say (196 slices -> 10 at the start + 15 at the end; 216 ->
  5 at the end; 221 -> none; skipped tile -> all 221 blank, written in about 1 min with no
  imaging, then the run went on to the next tile). No two consecutive identical frames
  (centre 256x256), so no repeated camera frames. 640 Analog: both power folders complete
  and written together; median brightness ratio about 2.6-2.7 for power 15/5.
- Not a code problem: some 561 / 640 / 730 frames have saturated pixels (65535) in the
  centre region. `Total Duration String` is read back by Excel as a time (0.0498 day).
- Bug 9 (xlsx grid orientation) cannot be judged from a 2 x 2 grid; the grid values do match
  the images tile by tile. Check with a non-square grid (e.g. 2 x 3).
- Result: skip tile (fill blank) and the multi-tile run of `cc5a716` **tested on the
  microscope, OK**.
- Backup: `_archive/docs/PROGRESS_LOG_before_skip_test_record.md`. No code changed.

---

## 2026-11-04: new window layout (applyLayout), galvo ◀/▶ + step, larger Tile States

Request: implement the UI plan with method A (automatic layout at startup). The window should
take half of the 24" screen (to watch the camera while adjusting); Live View / Paint stay
separate windows but open on the right half; galvo X/Y keep the sliders plus ◀/▶ and a step
dropdown (default 0.01 V); Roll is not used (hide); Galvo_Z is not needed; Tile States should be
bigger (40-50 tiles), with the rest scrolling.

- New `MMcodeOrcaV2/selfmade/applyLayout.m` (ASCII only, for R2019a): sets the window to
  `[1 41 960 960]`, creates 5 panels (top bar, 1 channel tuning, 2 stage + Paint, 3 z per tile,
  4 acquisition) and moves the existing components into them (`Parent`/`Position`, plus a few
  display properties: slider ticks, table font size and column widths, three step labels
  shortened to Up/Down, Left/Right, In/Out, one Power/Exposure label per row, green bold
  start button, Courier New in Tile States). Creates the galvo ◀/▶ buttons and step dropdowns
  (0.1/0.05/0.01/0.005/0.001 V). Hides `RollSlider`(+Label), `RollScanButton`, the two
  emptied panels, and the Galvo_Z columns (`ColumnWidth` 0; the data is still sent to the
  DAQ). Prints any component it did not place.
- `.mlapp` (both `document.xml` and `appModel.mat`):
  - `startupFcn`: `applyLayout(app)` after the export/import bindings.
  - New public method `galvoStep(app, axisName, delta)`: moves the slider by delta (rounded to
    1e-4, clamped to `Limits`), then calls `galvo_X/YSliderValueChanged`.
  - `updateTileStatus`: line 3 is now "Saved n/N, not saved: ..."; then every tile, two per
    line (`start -- end`, `skip`, or `---` if not saved). Line 1 is unchanged (the imaging
    button checks its last letter).
  - `EnableCamButtonPushed` / `PaintButtonValueChanged`: figure position
    `[100 100 800 800]` / `[100 100 1024 1024]` -> `[965 45 945 945]`.
  - No change to `startimagealltilesButtonPushed` or other 640 nm Analog code.
- Backup: `_archive/MMcodeOrcaV2/LightSheetControl_before_applyLayout.mlapp`;
  `_archive/docs/*_before_applyLayout.md`.
- Checks: fake window built from `createComponents` in R2026a on the workstation and
  screenshotted (all components placed, nothing overlapping). Every block of `appModel.mat`
  (70 callbacks, startup, editable section) appears verbatim in `document.xml`; only
  `EnableCamButtonPushed`, `PaintButtonValueChanged`, `startupFcn` and the editable section
  changed; `startimagealltilesButtonPushed` is identical. Class loads (`meta.class`),
  `galvoStep` is public. checkcode 366 -> 365 (only line-number shifts in 3 ALIGN notices);
  `applyLayout.m` 0 messages; `minimumSupportedMATLABRelease` R2018a.
- Not checked: R2019a behaviour of `ColumnWidth` 0 and of reparenting into new panels;
  appearance with Windows display scaling other than 100 %.
- **Not tested on the microscope.** To check there: window fits the left half; galvo ◀/▶
  move the galvo and update the path table; the keyboard shortcuts (k/l/space...) still work
  when the focus is in a panel; Tile States with many tiles; Live View / Paint open on the right.

---

## 2026-11-04: UI plan: method A chosen, Roll hidden, Live View / Paint window position (plan only)

Answers from Fengyi: (1) method A (automatic layout at startup); (2) default galvo step 0.01 V;
(3) Roll is not used, can be hidden; (4) asked whether Live View / Paint would be separate or
embedded, and how Paint would handle samples of different size.

- `docs/UI_redesign_plan.md`: method A marked as chosen; `RollSlider`(+Label) and `RollScanButton`
  go to a "hidden" row (callbacks unchanged); new section 6.1: Live View (`[100 100 800 800]`)
  and Paint (`[100 100 1024 1024]`, taller than a 1080 screen) are separate `figure` windows
  that open over the control window. Proposal: keep them separate, only change the initial
  position to the right half of the screen; they stay movable/resizable, and Paint scales the
  stitched image to the window (`imshow`), so sample size is not limited by the window.
- Backup: `_archive/docs/UI_redesign_plan_before_answers_1_3.md`,
  `_archive/docs/PROGRESS_LOG_before_answers_1_3.md`.
- No code changed; nothing to test on the microscope.

---

## 2026-11-04: UI plan: galvo X/Y keep the sliders, add ◀/▶ + step dropdown (plan only)

Request: keep the galvo X/Y sliders, add left/right buttons next to them, with an adjustable step
size chosen from a dropdown.

- `docs/UI_redesign_plan.md` section 3.1 rewritten: sliders stay visible; ◀/▶ add/subtract the
  step (clamped to the slider `Limits`), write `galvo_X/YSlider.Value` and call the existing
  `galvo_X/YSliderValueChanged`; one step dropdown each for X and Y (0.1 / 0.05 / 0.01 / 0.005 /
  0.001 V, default 0.01, to be confirmed). The planned value field and `syncGalvoFields` are
  dropped; `UITable_path` stays visible to show the exact value. Open questions renumbered.
- Backup: `_archive/docs/UI_redesign_plan_before_keep_slider.md`,
  `_archive/docs/PROGRESS_LOG_before_keep_slider.md`.
- No code changed; nothing to test on the microscope.

---

## 2026-11-04: UI plan updated: galvo X/Y step buttons, Galvo_Z hidden (plan only)

Request: the screen is an ordinary 24" monitor; Galvo_Z is not needed; galvo X/Y sliders are hard
to set precisely and take space, use arrow buttons + step size like the lenses instead.

- `docs/UI_redesign_plan.md`: new sections 3.1 (galvo X/Y as value field + ◀/▶ + step dropdown;
  sliders kept but hidden, because several callbacks read/write their `.Value`; new buttons write
  the slider value and call the existing `galvo_X/YSliderValueChanged`, plus a `syncGalvoFields`
  helper) and 3.2 (Galvo_Z column hidden in the tables only; its data is still sent to the DAQ by
  every `outputSingleScan`, so it cannot be deleted). Screen size noted; open questions updated.
- Found: `save_checkpointButtonPushed` references nonexistent `galvo_ZSlider` / `galvo_Xview`;
  it is not bound to any control (dead code).
- Backup: `_archive/docs/UI_redesign_plan_before_galvo_steps.md`,
  `_archive/docs/PROGRESS_LOG_before_galvo_steps_plan.md`.
- No code changed; nothing to test on the microscope.

---

## 2026-11-04: colleague's test controls removed; export/import tiles buttons bound

Request: remove the controls Fengyi does not use (all except Show Grid); keep the 640 nm Analog
mode (two light intensities for the 640 nm channel, for poor antibody penetration) unchanged.

- Fengyi in Design View (R2026b, Mac): deleted `SaveImAFG2Button`, `SaveImCamButton`,
  `TestTriggerButton`, `AFG_Manual_mWEditField` (+ label), `RunAutoFocusButton` and the
  "Live View Buttons" panel (`ShowGridCheckBox` moved onto the main window, callback still bound);
  added `importtilesButton` ("import tiles") and `exporttilesButton` ("export tiles") in the
  M-by-N tiles panel, without callbacks.
- By script: deleted the 5 callbacks left unassociated (`RunAutoFocusButtonPushed`,
  `SaveImAFG2ButtonPushed`, `SaveImCamButtonPushed` with its nested helpers,
  `TestTriggerButtonPushed`, `AFG_Manual_mWEditFieldValueChanged`; 558 lines) from both
  `document.xml` and `appModel.mat`. `startupFcn` now sets
  `exporttilesButton.ButtonPushedFcn = @(src, event) exportTiles(app)` and the same for
  `importtilesButton` / `importTiles`, so no Design View callback is needed. (If callbacks are
  added in Design View later, remove these two lines.)
- Not done, on purpose: `isAnalogMode` is kept, because removing it means editing
  `StopAnalogButtonPushed` (part of the 640 nm analog tools). No change to the 640 nm Analog code.
- Backup (the Design View save, before the script): 
  `_archive/MMcodeOrcaV2/LightSheetControl_before_remove_test_callbacks.mlapp`; docs:
  `_archive/docs/*_before_remove_test_callbacks.md`.
- Checks: every remaining block verified verbatim in `document.xml` (70 callbacks, startup,
  editable section); `startimagealltilesButtonPushed`, `SvAFG2ButtonPushed`,
  `StopAnalogButtonPushed`, `ShowGridCheckBoxValueChanged` and the editable section are byte-for-byte
  unchanged, and no other callback changed; checkcode 378 -> 365, no new messages (3 ALIGN notices
  moved); `minimumSupportedMATLABRelease` R2018a.
- **Not tested on the microscope.**

---

## 2026-11-04: UI redesign plan (plan only, no code changed)

Request: redesign the UI to follow the workflow (tune galvo/detection per channel -> Paint for
the xy bounds -> z bounds tile by tile -> acquire); the controls left on the UI are the ones in use.

- New `docs/UI_redesign_plan.md`: layout mockup (top bar + 4 numbered sections), which component
  goes to which section, three ways to implement it (recommended: `selfmade/applyLayout.m`
  called from `startupFcn`, which moves the existing components into new panels at run time),
  and open questions (method, screen resolution of the microscope PC, layout changes).
  Written in Chinese, so the discussion can continue on another PC.
- Noted: `SaveImAFG2Button`, `SaveImCamButton`, `TestTriggerButton` were removed from the UI,
  but their callbacks still reference them (dead code).
- Backup: `_archive/docs/PROGRESS_LOG_before_ui_plan.md`.
- No code changed; nothing to test on the microscope.

---

## 2026-11-04: export/load tile list (xlsx), tile grid in Paint, command-window log file

Requests: (1) a button that writes the saved tiles' start/end to an xlsx file, and a button that
reads such a file back as the imaging parameters of the current sample; (2) in Paint, show the
tile grid for a given Vertical x Horizontal tile count, with the tile overlap and correct
odd/even centring; (3) save everything printed in the command window (errors, warnings) as a
log in the output folder, because MATLAB sometimes crashes and closes; (4) what are the
colleague's test controls next to "Live View Buttons".

- **Tile list xlsx** (new `selfmade/writeTileList.m`, `selfmade/readTileList.m`; app methods
  `exportTiles`, `importTiles`). Sheet `Tiles`: one row per tile in scan-pattern order (Z
  fastest): `Tile, Saved, Skip, Start_um, End_um, X_um, Y_um, Z_um, LightPath, PlanX_um,
  PlanY_um, PlanZ_um`. Sheet `Grid`: `VerticalTiles, HorizontalTiles, ZStep_um, NumTiles,
  Written`. Loading replaces `xyzScanArray` and `checkpoints_multipletile`, sets the
  Vertical/Horizontal fields, turns the lamp green and updates the Tile States box, so
  "start image all tiles" can run directly. Coordinates are absolute (the sample must not
  have moved). The z step in the file is shown but not applied. `start image all tiles` also
  writes the two sheets into `imaging_params_*.xlsx`, so that file can be loaded too.
  **The two buttons do not exist yet** (see TODO).
- **Paint tile grid** (new `selfmade/paintTileGrid.m`, app method `drawPaintTileGrid`): after
  Paint, Up/Down/Left/Right and Center, and when the Vertical/Horizontal tile field changes
  (`ValueChangedFcn` set in `startupFcn`), the Paint view shows the V x H tiles that create scan
  pattern would make at the current stage position: orange 2048 px boxes with tile numbers,
  15 % overlap visible as bands, title line with the grid size in mm. Positions come from
  `createScanpattern`, so odd/even centring and numbering match the real scan pattern. 0 tiles =
  no grid. Not related to the Live View "Show Grid" checkbox (that is only a centre crosshair).
- **Log**: app method `startLog` uses `diary`. At start-up the log goes to `<repo>\logs\`
  (added to `.gitignore`); choosing "Image saving directory" (and start image all tiles, if
  needed) moves it to `<output folder>\matlab_log_<date>.txt`, copying the session so far into
  it. `selfmade/flushDiary.m` (diary off/on) writes it to disk every 30 s (timer
  `LightSheetLogTimer`) and after every tile; on an imaging error the full `getReport` stack is
  printed into the log.
- Bug 5 fixed on the way: cancelling "Image saving directory" no longer sets `app.dirname = 0`.
- Colleague's controls explained (answer only, nothing removed): see TODO.
- Edited by script (16 edits: editable section, `startupFcn`, `ImagesavingdirectoryButtonPushed`,
  `startimagealltilesButtonPushed`, Paint/Up/Down/Left/Right/Center), both `document.xml` and
  `appModel.mat`; every block verified verbatim in `document.xml`; only these 8 callbacks +
  startup + editable section changed. Zip entry order kept.
- Backups: `_archive/MMcodeOrcaV2/LightSheetControl_before_tilelist_grid_log.mlapp`,
  `_archive/docs/PROGRESS_LOG_before_tilelist_grid_log.md`,
  `_archive/docs/V5_app_guide_before_tilelist_grid_log.md`, `_archive/gitignore_before_logs.txt`.
- Checks: checkcode 378 (was 370): the 8 new ones are `datestr`/`now` "not recommended" (used the
  same way elsewhere; fine on R2019a); 3 ALIGN notices only moved. New `.m` files: 0 messages
  except `datestr`/`now`. `minimumSupportedMATLABRelease` still R2018a. Tested on the Mac (R2026b):
  xlsx write -> read round trip (saved, skipped, unsaved tiles; adding the sheets to an existing
  file keeps its other sheets; V x H mismatch gives an error); `paintTileGrid` for 1-4 x 1-4 tiles
  (grid centred on the current position, centres 0.85 x 2048 px apart); the grid drawing code on
  a fake Paint figure (3 x 4 and 2 x 2, redraw replaces the old grid); `flushDiary` puts the text
  on disk while the diary stays on.
- **Not tested on the microscope**, and not opened in App Designer yet.

---

## 2026-11-04: Tile States box shows each saved tile's z range; no command-window print

Request: when saving tile z start/end, show each tile's range in the "Saved Tiles List" line,
e.g. `Saved Tiles List: 1(-200 -- 1000)`; do not print to the terminal.

- `updateTileStatus`: line 3 of `TileStatesTextArea` is now
  `Saved Tiles List: 1(-200 -- 1000)  2(skip)  3(... -- ...)` (start_pos -- end_pos per saved
  tile; skipped tiles still show `(skip)`). The `fprintf` block that printed the tiles to the
  command window was removed. Lines 1-2 unchanged (line 1 still ends with "Yes"/"No", which the
  imaging button checks).
- Edited by script (both `document.xml` and `appModel.mat`; note: `strsplit` needs
  `'CollapseDelimiters', false`, otherwise blank lines are lost). Editable section 685 -> 667 lines,
  verified verbatim in `document.xml`, all callbacks match.
- Backup: `_archive/MMcodeOrcaV2/LightSheetControl_before_tile_range_list.mlapp`.
- Checks: checkcode 370 warnings, same messages as before; `minimumSupportedMATLABRelease` R2018a.
- Not tested on the microscope.

---

## 2026-11-04: "skip tile (fill blank)" button added in Design View

Request: add the skip-tile button (TODO from 2026-11-03).

- Fengyi added the button in App Designer Design View (Mac, R2026b) next to "save checkpoints":
  component `skiptilesButton`, callback `skiptilesButtonPushed` = `skipCurrentTile(app);`.
  The 2026-11-03 TODO is done. The unused controls (TODO list) are not deleted yet.
- Backup: `_archive/MMcodeOrcaV2/LightSheetControl_before_add_skip_button.mlapp` (taken from
  git HEAD after the edit, since the edit was made before the backup).
- Checks: callback present in both `document.xml` and `appModel.mat`; checkcode 370 warnings
  before and after (HEAD also had 370; the 367 in older entries was before later edits), no new
  ones; `minimumSupportedMATLABRelease` still R2018a.
- Not tested on the microscope.

---

## 2026-11-04: code cloned to the microscope PC; config files checked

Request: clone the repo to `D:\Fengyi\light_sheet_system` on the microscope PC and add the
missing config files.

- Cloned `main` to `D:\Fengyi\light_sheet_system` on the microscope PC (fine-grained token,
  this repo only). The old copy `D:\lightSheetsourcecode_twopath_multipower` is unchanged.
- `config/configuration_03132026.cfg`: copied the PC's
  `C:\Program Files\Micro-Manager-1.4\configuration_03132026.cfg` over it; git showed no change,
  so the repo copy was already the real file. It is the only cfg on that PC. The earlier warning
  (identical to the 2019 `configuration_05302019.cfg`) only means the hardware config was not
  changed since 2019; it was not a wrong copy.
- `config/javaclasspath.txt` added from the PC's MATLAB `prefdir` (committed from the PC).
  There is no `librarypath.txt` on that PC.
- README `config/` section and TODO list updated.
- No code changed; nothing to test on the microscope.

---

## 2026-11-04: plan for splitting the app code (TODO only, no code changed)

Request: the control code feels too long; is splitting it worth it?

Size now (code in `matlab/document.xml`): 6153 lines, 99 functions. `createComponents`
(943 lines) is generated by App Designer and is left alone. The long hand-written ones:
`startimagealltilesButtonPushed` 1186 lines (488/561/640/730 each have a near-copy of
laser setup -> calibration -> imaging loop -> waitbar -> zero filling; 640 Analog also has
the waveform/AFG part), `SvAFG2ButtonPushed` 329, `SaveImCamButtonPushed` 213,
`EnableCamButtonPushed` 170. `Up/Down/Left/Right` (about 63 lines each) are copies that
differ mainly in the step sign.

Decision: test the current code on the microscope first, so there is a known-good version.
Then split one piece at a time, testing each step. The main reason to split is that logic in
`selfmade/*.m` can be edited without syncing `document.xml` and `appModel.mat` and can be
tested on the Mac with a fake app; a fix in the colour blocks also has to be made only once.

Found while reading: `UpButtonPushed` sets the camera exposure to 40 ms
(`setProperty('HamamatsuHam_DCAM','Exposure',40)`); Down/Left/Right do not. Not yet known
whether this is intended (see TODO).

- Backup: `_archive/docs/PROGRESS_LOG_before_refactor_todo.md`.
- No code changed; nothing to test on the microscope.

---

## 2026-11-04: fixed high-priority bugs 1-3 (applied by script)

Request: fix the three High bugs in `docs/V5_app_guide.md` 6.1, without manual copy-paste.

- Bug 1: `StopAnalogButtonPushed` / `SvAFG2ButtonPushed`: `ChangePowerObis(port, target_mW, maxPower)`
  (4 lines; the arguments were in the wrong order, so the 640 nm laser went to 1 mW).
- Bug 2: `ResetImagingButtonPushed` also sets `app.dirname = 'D:\Data'` (start-up value), so imaging
  asks for a new folder after Reset.
- Bug 3: new method `checkCameraTimeout(app, t0)` (error after 5 s + exposure); called in the 7
  frame-wait loops: `requestoneimagefromcamera`, Paint, Up/Down/Left/Right, Center.
  (`EnableCamButtonPushed` already had a 5 s timeout.)
- How: MATLAB R2026b (Mac) script edited `code` in `appdesigner/appModel.mat` (9 callbacks + editable
  section; each edit had to match exactly); `matlab/document.xml` got the same text; the other zip
  entries were copied unchanged. The steps are kept in `docs/patches/2026-11-04_high_priority_bugs.md`.
- Backup: `_archive/MMcodeOrcaV2/LightSheetControl_before_high_bugs.mlapp`.
- Checks: all 76 code blocks in `appModel.mat` (editable section, startup, 74 callbacks) appear
  verbatim in `document.xml`; only the 9 intended callbacks + editable section changed;
  `checkcode`: 369 messages, as before (3 existing ALIGN notices moved by the inserted lines),
  no syntax errors; `minimumSupportedMATLABRelease` still R2018a. **Not yet opened in App Designer;
  not tested on the microscope.**

---

## 2026-11-04: known-bugs table re-checked; local CLAUDE.md

- `docs/V5_app_guide.md` section 6 rewritten: every row was re-checked against the current
  app code. Split into "Open" (12 rows, with a priority) and "Fixed or disabled". New open rows:
  Reset keeps the old `app.dirname` (next run saves into the old folder), no camera timeout in
  `requestoneimagefromcamera`, Tenengrad autofocus has no wait after its final lens move,
  cancelling `uigetdir` sets `app.dirname = 0`, Paint canvas ~14.8 GB; the xlsx orientation
  bug also affects the new `9_Skipped_Grid` sheet.
- Added `CLAUDE.md` (notes for Claude Code: read this log first, backup/log rules). It is
  tracked in git so claude.ai/code can read it; `.gitignore` only excludes
  `.claude/settings.local.json`.
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
- **TODO (Fengyi):** (done 2026-11-04) add the button "skip tile (fill blank)" next to "save checkpoints" in
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
  (Update 2026-11-04: checked on the microscope PC, it is the real file; see the newer entry.)
  **Warning (old):** this copy is byte-identical to the 2019 `configuration_05302019.cfg`, so
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
- [x] (done 2026-11-04) (added 2026-11-04) In App Designer Design View, add two buttons (e.g. in the M-by-N tiles
      panel, next to "save checkpoints"), add a ButtonPushed callback to each and type one line:
      "export tiles" -> `exportTiles(app);`, "load tiles" -> `importTiles(app);`. Save, then check
      `minimumSupportedMATLABRelease` is still R2018a.
- [x] (done 2026-11-04) (added 2026-11-04, decided by Fengyi) Delete the colleague's test controls next to "Live
      View Buttons" in Design View: `SaveImAFG2Button`, `SaveImCamButton`, `TestTriggerButton`,
      `AFG_Manual_mWEditField` (+ label), `RunAutoFocusButton`. Keep `ShowGridCheckBox`, `SvAFG2`
      and `StopAnalog`. Then (Claude, by script) delete the callbacks left behind and the
      property `isAnalogMode` (only those callbacks use it). Checked: none of these controls
      is used by the 640 nm Analog imaging.
      **Do not change the 640 nm Analog mode** (Mode 640nm = Analog in "start image all tiles":
      the 640 nm channel is imaged at two light intensities, for samples with poor antibody
      penetration; very important to Fengyi). No auto-restore in the imaging `catch` either.
- [ ] In App Designer Design View, delete the unused controls and save:
      `UITable_afg`, `SnapHistogramButton`, `save_DButton`, `nm_D488`, `nm_D561`,
      `nm_D640`, `nm_DEditFieldLabel`, `nm_DEditField_2Label`, `nm_DEditFieldLabel_2`,
      `Button_7`, `Button_8`, `Rotation_stepDropDown`, `Rotation_stepDropDownLabel`,
      `Stage_HardwareT_EditField`, `TEditFieldLabel`. Then delete any callbacks they
      leave behind.
- [x] Check `config/configuration_03132026.cfg` against the microscope PC (done 2026-11-04:
      identical, it is the only cfg there).
- [x] Copy `javaclasspath.txt` from the microscope PC's MATLAB `prefdir` into `config/`
      (done 2026-11-04; that PC has no `librarypath.txt`).
- [ ] Delete the old `app_for_lightsheet_V2_main_autofocus_autopower_V5.mlapp` if it is still there.
- [ ] Make the first git commit and push to `github.com/fengyiyu1234/light_sheet_system` (private).
- [ ] Copy the updated files to the microscope PC and test: start-up, Live View, autofocus
      (both methods), create scan pattern, and a short multi-tile run.
      (2026-11-05: multi-tile run with skip tile OK on commit `cc5a716`. Still to test:
      `bb6395f` export/import tiles, Paint grid, log file; the `applyLayout` window;
      bug 9 with a non-square grid.)
- [x] Update the known-bugs table in `docs/V5_app_guide.md` (done 2026-11-04).
- [ ] Check on the microscope whether pressing Up changes the exposure to 40 ms (only
      `UpButtonPushed` sets it), and decide whether to keep that line.
- [ ] Split the app code (added 2026-11-04). **Start only after the microscope test above
      passes** and that version is committed. One step at a time; test each step before the next:
  1. [ ] Merge `Up/Down/Left/Right` into one method `moveTile(app, dx, dz)`; each callback
         becomes one line. Small and low-risk, so it is a good first try of the workflow.
  2. [ ] In `startimagealltilesButtonPushed`, move the imaging of one tile for one colour into
         one function (488/561/730 share it; 640 Analog keeps its own extra part). Biggest gain:
         a fix is then made once, not four times.
  3. [ ] Split the other long callbacks (`SvAFG2ButtonPushed`, `SaveImCamButtonPushed`,
         `EnableCamButtonPushed`) only when they next need a change.
  - Prefer plain `.m` files in `selfmade/` for the moved logic, so they can be edited without
    syncing `appModel.mat` and tested on the Mac with a fake app.

### Known bugs still open
- `StopAnalogButtonPushed` and the end of `SvAFG2ButtonPushed` call
  `ChangePowerObis(lz, 1, target_mW)` with the arguments in the wrong order, so the
  640 nm laser goes back to 1 mW.
- `RollScanButtonValueChanged` writes to `controlParameters.afg` without `app.`, so
  Roll Scan errors out.
- (fixed 2026-11-05) Tenengrad autofocus does not pause after its final lens move.
- The `catch` block of `startimagealltilesButtonPushed` checks
  `exist('app.waitbar','var')`, which is always false, so the progress window stays
  open after an error.
- In the imaging log xlsx, the start/end/slice grids are reshaped in the wrong
  orientation. This affects the log only, not the images.
- Paint Mode allocates a very large canvas (about 14.8 GB), and `imshow` is called
  without `Parent`.
- Others are listed in `docs/V5_app_guide.md`, section 6. (Reset save folder, camera
  timeout and cancelling `uigetdir` were fixed on 2026-11-04.)
