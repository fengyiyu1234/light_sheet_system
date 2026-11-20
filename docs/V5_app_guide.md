# App guide (`LightSheetControl.mlapp`)

This app was renamed in Nov 2026 from `app_for_lightsheet_V2_main_autofocus_autopower_V5.mlapp`;
the code is the same, and "V5" below refers to this app.

The app is a single App Designer class of about 6000 lines. About 1000 of those lines
are auto-generated UI layout (`createComponents`). The callbacks below are listed by name;
find them in App Designer's Code View or with Ctrl+F.

> `.mlapp` is a zip file, so `git diff` can't show changes to it. To read or diff the
> code outside App Designer, unzip it and read `matlab/document.xml`: the whole class
> is inside one `<![CDATA[ ... ]]>` block.

## 1. Start-up (`startupFcn`)

1. Runs `addpath` on the code folders, found relative to the app file (`fileparts(which(class(app)))`).
2. `controlParameters` and `allLasers` are taken from the base workspace (created by the init script).
3. Turns all 4 lasers off and moves the filter wheel to position 1.
4. Reads `states_record.xlsx` (from the app folder) into the GUI tables:

| Sheet | Property / UI table | Contents |
|---|---|---|
| 1 | `state_stage` | X Y Z T (overwritten with live stage values right away) |
| 2 | `state_path` | Galvo X/Y/Z voltage per path. Galvo X/Y of path 1 are shown in `UITable_path` (since 2026-11-05 one 1x4 table GalvoX / GalvoY / Excitation / Detection, filled by `refreshPathMotorTable`) |
| 3 | `state_motor` | Excitation (row 1, ExtLens1) / ExtLens2 (row 2) / detection (row 3) lens positions (mm). Rows 1 and 3 are shown in `UITable_path`; `UITable_motor` is hidden by `applyLayout` (2026-11-05) |
| 4 | `state_afg` / `UITable_afg` | AFG offset 1/2, ramp top/bottom (mV) per color |
| 5 | `state_offset` / `UITable_offset` | **Per-color calibration**: Galvo_X/Y/Z, Detectionlens, Excitionlens. Rows 1–4 = 488/561/640/730 |
| 7 | `HDPRTable` | 640 nm analog mode: power list (row 2) and exposure list (row 3) |

   **The app never writes this file back.** Values saved with "save offset for different color"
   or edited in the tables only last until the app closes. Each imaging run does save a
   snapshot (`imaging_params_<time>.xlsx` in the data folder); to keep a calibration,
   copy it into `states_record.xlsx` by hand.
5. Puts the AFG into DC at the stored offsets, reads both lens positions, and sets the camera exposure to 100 ms.

Sign convention: `Shutterstate1 = 4` (V) means the shutter is open, `0` means closed. Every hardware
write is `outputSingleScan(s1, [shutter, galvoX, galvoY, galvoZ])`.

## 2. UI panels and their callbacks

| Panel / control | Callback(s) | What it does |
|---|---|---|
| Wavelength dropdown | `LightwavelightValueChanged` | Turns on one laser and the others off, sets power, then applies that color's row of `UITable_offset` to the galvos and both lens motors |
| Laser Power | `LaserPowerValueChanged` | Sets the power of **all** lasers (clamped to 0–30 mW) |
| Shutter | `ShutterButtonValueChanged` | Opens/closes the shutter using the current color's galvo offset |
| galvo_X / galvo_Y sliders, Reset | `galvo_*SliderValueChanged`, `Reset_galvo_XYButtonPushed` | Writes galvo voltages directly. Since 2026-11-04 each slider also has ◀/▶ buttons and a step dropdown (0.1–0.001 V, default 0.01), created in `applyLayout`; they call `galvoStep(app, axis, delta)`, which moves the slider (clamped to its Limits) and runs the slider callback |
| Filter wheel | `FilterwheelValueChanged` | `pos=1..6` |
| Enable / Disable Camera | `EnableCamButtonPushed`, `DisableCamButtonPushed` | Live View: a blocking `while` loop in `EnableCam` that runs until `myhandles.continue = false`. Enable turns on the laser of the selected wavelength and opens the shutter (and sets the Shutter button). Since 2026-11-06 Disable **only stops the camera**: lasers and shutter stay as they are (lasers off with wavelength "None", shutter with the Shutter button). Since 2026-11-06 the two buttons are large, in the centre of the top bar |
| Live View tools | `ShowGridCheckBoxValueChanged`, `SnapHistogramButtonPushed`, `ImagecontrastValueChanged`, `Exposure_timeEditFieldValueChanged` | Tools that work while Live View is open. **Show Grid** shows a centre crosshair (since 2026-11-04 directly on the main window; the "Live View Buttons" panel and Run AutoFocus were removed) |
| Stage arrows ⏫⏬⍟⌾⏪⏩↺↻, step dropdowns, Get Position | `Button*_Pushed`, `*_stepDropDownValueChanged`, `GetPositionButtonPushed` | Relative stage moves. Moves are blocked while the status lamp is green (a scan pattern is active), except depth (Y) moves. Since 2026-11-09 also with the arrow keys (see keyboard shortcuts below). Since 2026-11-20 (`applyLayout`): ⏫⏬⏪⏩ larger in the middle of panel 2, step drop-downs in the corners (Up/Down step, Left/Right step, Depth step); the depth buttons are labelled **Close to camera** (⍟ `Button_5`, Y − step, limited by Min Z) and **Away from camera** (⌾ `Button_6`, Y + step). With Paint on (and its window open) the four arrow buttons do the Paint moves (`paintMoveInstead`), like the arrow keys |
| Excitation / Detection lens ◀ ▶ | `left/rightButtonExt/Obj`, `Ext/ObjStepsizeDropDown`, `lensButtonsOn` | Newport relative moves (`1PR`), then reads the position back with `readLensPos` (discards stale replies, waits until the motor stops). ◀ (`leftButton…`) = `+step` (position up), ▶ (`rightButton…`) = `-step` (position down); the arrows are set in `applyLayout` (Design View still says left/right). Since 2026-11-20 both buttons of a lens are disabled during its move; clicks made meanwhile do nothing |
| save offset for different color | `saveoffsetfordifferentcolorButtonPushed` | Reads both lens positions from the motors, then copies the galvo and lens values into the selected color's row of `UITable_offset` (in memory only). Since 2026-11-20 the offsets are shown and edited in the transposed table `OffsetView` |
| Paint Mode (Paint, Center, Save paint; Up/Down/Left/Right hidden since 2026-11-20) | `PaintButtonValueChanged`, `Up/Down/Left/RightButtonPushed` (called by the stage arrows / arrow keys when Paint is on), `CenterButtonPushed`, `SavepaintButtonPushed` | Builds a stitched overview on a 21x21-tile canvas (0.65 µm/px) to find the sample and center it. Paint moves need a step ≥ 40 µm (else a message and no move) |
| AFG_scan, Roll Scan / Roll slider | `AFG_scanButtonValueChanged`, `RollScan*`, `RollSlider*` | Turns the light-sheet ramp on AFG ch1 on or off; roll uses ch2 |
| **M-by-N tiles panel** | see section 3 | Multi-tile z-stack acquisition |
| 640 nm analog tools: StopAnalog, SvAFG2 | `StopAnalogButtonPushed`, `SvAFG2ButtonPushed` | **StopAnalog** returns the 640 nm laser to CW, sets `afg2` ch1/ch2 to 0 V DC and the camera to internal trigger (use it if 640 nm Analog imaging stops with an error). **SvAFG2** runs a full exposure x power matrix from `HDPRTable` column 3 at the current position. The colleague's test controls SaveImAFG2, SaveImCam, TestTrigger and AFG_Manual_mW were removed on 2026-11-04 (code in `_archive/MMcodeOrcaV2/LightSheetControl_before_remove_test_callbacks.mlapp`). `isAnalogMode` is still set by StopAnalog but never read. The 640 nm Analog *imaging* mode (Mode 640nm = Analog: two light intensities for the 640 nm channel) is in `startimagealltilesButtonPushed` and does not use these buttons; **do not change it** |
| Paint tile grid (2026-11-04) | `drawPaintTileGrid`, `selfmade/paintTileGrid.m` | In the Paint view, orange boxes show the Vertical x Horizontal tiles that create scan pattern would make at the current position (15 % overlap, numbered); redrawn after every Paint move and when the tile fields change |
| Tile focus + tile table (2026-11-20) | `setTileFocus`, `clearTileFocus`, `tileFocus`, `refreshTileTable` (buttons, label `TileFocusInfo` and table `TileTable` made in `applyLayout`, panel 3), `selfmade/tileFocusOf.m`, `tileTableData.m`, `focusSheetRows.m` | Per-tile focus of the detection (Obj) lens. **Set tile focus** reads the detection lens position and stores it for the current tile (move to tile) and the current wavelength, in `checkpoints_multipletile(t).tile_focus` (1x4, mm, NaN = default). **Tile focus = default** clears it. Works after create scan pattern, also before the tile's start/end are saved; not on skipped tiles. The table lists every tile: #, Start, End, and the focus of 488/561/640/730 (`default` = the color's Detection value in the offset table). Since 2026-11-20 the Tile States box is hidden (the table replaces it; unsaved tiles show `none` as Start/End). The hidden box still holds the status text that start image all tiles checks (line 1 ends with "Yes" when all tiles are saved) Clicking a row of the table asks "Move the stage to tile N?" and then does the same as move to tile (`selectTileFromTable`; nothing for the current tile or during imaging) |
| Focus editor (2026-11-20) | `selfmade/focusEditor.m` (button "Focus editor" in panel 3, made in `applyLayout`), `tileFocus(app, t, k, y)`, `isImaging`, `selfmade/tileFocusOps.m`, `focusAtDepth.m`, `focusSegments.m` | Separate window (classic figure, over panel 4) for the current tile (start/end must be saved): one bar per color from start (left) to end; grey = default, blue = tile focus, orange = depth segment; blue line = point, dashed = stage depth; the current wavelength's row is highlighted. Pick the point (click a bar, type it, or Use stage depth), adjust Obj, then **start -> point** / **point -> end** with the current lens or with Default. Later settings overwrite earlier ones; the point belongs to "point -> end". **Whole tile** = Set tile focus; Set tile focus and Tile focus = default remove that color's segments. Also Move stage here, Lens to focus here, Undo last (this window only), Refresh. Data: `checkpoints_multipletile(t).focus_ops` (rows `[k from to focus]`, NaN = default). Locked while imaging. The tile table shows `N seg` when a color has more than one part It always shows the current tile (move to tile) and wavelength; since 2026-11-20 it redraws by itself when either changes (`onCleanup` refresh in `movetotileSpinnerValueChanged` / `LightwavelightValueChanged`) |
| export tiles / import tiles (2026-11-04) | `exportTiles`, `importTiles` (bound to `exporttilesButton` / `importtilesButton` in `startupFcn`), `selfmade/writeTileList.m`, `readTileList.m` | xlsx with sheets `Tiles` (one row per tile: saved, skip, start/end, stage X/Y/Z, path, planned X/Y/Z, and since 2026-11-20 Focus488_mm..Focus730_mm, empty = default), `Grid` and (since 2026-11-20) `FocusSegments` (Tile, Color_nm, From_um, To_um, DetLens_mm per Focus editor operation); importing makes it the current scan pattern. `imaging_params_*.xlsx` also gets these sheets |
| command-window log (2026-11-04) | `startLog`, `selfmade/flushDiary.m` | `diary` to `<repo>\logs\` at start-up, moved to `<output folder>\matlab_log_<date>.txt` when the saving directory is chosen; written to disk every 30 s and after every tile |
| Window layout (2026-11-04) | `selfmade/applyLayout.m`, called in `startupFcn` | At start-up, moves the components into 5 panels by workflow (top bar, 1 channel tuning, 2 stage + Paint, 3 z per tile, 4 acquisition), window 960 x 960 on the left half of the screen; Live View and Paint open on the right half (`[965 45 945 945]`). Roll slider / Roll Scan are hidden. Top bar (2026-11-07): wavelength, laser power, filter wheel on the left; light path and shutter on the right. The offset table has no Galvo_Z column since 2026-11-07 (removed from `app.state_offset` at start-up; imaging sends 0 V on the roll channel). Design View still shows the old layout; components not placed by `applyLayout` are listed in the command window. Remove the `applyLayout(app)` line to go back **Layout v2 (2026-11-20):** 4 panels: a settings panel on top left (old top bar + panel 4: directory, laser/camera, light path, autofocus method, colors with power/exposure, z step, AF step, 640 nm mode and tools, HDR powers, reset/start), as wide as panels 1 (channel tuning) and 2 (stage + Paint) below it; panel 3 (z bounds and focus per tile) full height on the right, 430 px wide. Galvo buttons/step below each slider; lens buttons narrower; `UITable_path` is 4x1 (rows GalvoX, GalvoY, Excitation, Detection; `UITable_pathCellEdit` uses the row index); the offset table is shown transposed as `OffsetView` (rows GalvoX, GalvoY, Det, Ext; columns 488..730; edits go through `offsetViewEdit` into `app.state_offset` and the hidden `UITable_offset`, which the rest of the code still reads; `refreshOffsetView` after start-up and save offset). The Focus editor window now opens over the lower part of panel 3 |
| Tile States box (hidden since 2026-11-20) | `updateTileStatus` | Not visible any more (the tile table replaces it), but still filled: line 1: current tile and "save all checkpoints? Yes/No" (the imaging button checks the "s" at the end); line 2: min start / max end; line 3: saved count and tiles not saved; then every tile, two per line (`start -- end`, `skip` or `---`), fixed-width font |

Keyboard shortcuts (2026-11-09; `UIFigureKeyPress` → `stageKeyPress`, `keyMoveDone`):
- `↑`/`↓`/`←`/`→` move the stage like ⏫/⏬/⏪/⏩ (`ButtonPushed`, `Button_4Pushed`,
  `Button_3Pushed`, `Button_2Pushed`). While Paint is on and the Painting View is open they
  run the Paint Up/Down/Left/Right buttons instead (move + new image in the Paint view).
- They work in the control window, the Live View and the Painting View (both get the same
  `KeyPressFcn` when they are created).
- A key pressed while a key move is running is **dropped** (not queued; `app.keyMoveBusy`),
  so holding a key down moves only one step. Keys are also ignored during imaging
  (`app.imagingBusy`, since 2026-11-20).
- Nothing happens while the focus is in an edit field, drop-down, table, check box etc.
  (the key belongs to that control), or with Shift/Ctrl/Alt. Click on an empty part of the
  window first. Depth (Y) has no key.
- The same checks as the buttons apply (status lamp green: no move; Paint step < 40 µm: warning).
- The old shortcuts (`a`/`d` tile, `w`/`s` checkpoint, `i`/`o` depth, `k`/`l` save start/end,
  `space` save checkpoints, `←`/`→` detection lens) were switched off on 2026-11-03 and are
  still off; this list was not updated then.

## 3. Multi-tile imaging workflow

1. Set **Vertical tile / Horizontal tile** and press **create scan pattern(center)**.
   `createScanpattern` builds a V x H grid centered on the current position. The tile
   step is 0.65 µm/px x 2048 px x 85 % (15 % overlap), and the status lamp turns green.
2. For each tile, use **move to tile** (or `a`/`d`). Set **start** (`k`) and **end** (`l`)
   depth (stage Y; the start must be the smaller value), then press **save checkpoints** (`space`).
   For an **empty tile**, press **skip tile (fill blank)** instead (`skiptilesButton`, calls
   `skipCurrentTile`; added 2026-11-04). No start/end is needed. During imaging
   the tile is not imaged: `fillSkippedTile` writes an all-zero image for every layer of the
   global z grid, for every selected color, in the usual folders (X/Z from the position saved
   with the tile; the stage is not moved). Saving checkpoints on the tile later un-skips it.
   When every tile is saved, the struct is also written to `scanpattern.mat`.
   **Tile focus (2026-11-20):** where a color's default focus is wrong on a tile (e.g. a
   crack), move to the tile, choose the wavelength, adjust with Obj ◀ ▶ and press
   **Set tile focus**; the tile table shows the value. **Tile focus = default** undoes it.
   For different focus at different depths of one tile (after its start/end are saved), use
   the **Focus editor** window (see section 2).
3. Choose the colors (W488/W561/W640/W730), their Power_* / Exposure_* values, the z step,
   the AutoFocus step and method, and the 640 nm mode (Serial/Analog). Set the **Image saving directory**.
4. Press **start image all tiles**. This runs `startimagealltilesButtonPushed`, which:
   - (2026-11-20) after its checks, freezes the main window until it ends (normal end, Cancel or
     error): `freezeGui` greys out every enabled control (incl. the `applyLayout` panels/buttons and
     the tile table), arrow keys are ignored (`app.imagingBusy`) and the window's × only shows a
     message; `unfreezeGui` (via `onCleanup`) puts everything back, controls that were already off
     stay off. **Cancel** in the progress window still works (it is a separate window)
   - writes `imaging_params_<timestamp>.xlsx` (offsets, HDPR, AFG, powers, start/end/slice grids, settings,
     and since 2026-11-20 sheet `10_Focus`: Tile, Color, From_um, To_um, DetLens_mm, Source = tile/default
     for every imaged tile and selected color)
   - for each tile, then each selected color:
     1. switches lasers off, sets the galvo offset and filter wheel, waits 6 s
     2. moves the stage to the tile and its first depth
     3. turns the laser on at the set power, moves both lenses to the color's offsets, and opens the shutter
        (since 2026-11-20 the detection lens goes to `tileFocus(app, tile, color)`, i.e. the tile's
        focus if set, else the color's offset, and imaging waits with `readLensPos` until it has
        stopped; same for 640 nm Serial and Analog). Since 2026-11-20 (depth segments) this is the
        focus at the first depth, and before every layer the code checks `tileFocus(app, tile,
        color, depth)`: if the layer is in another Focus editor segment, the detection lens moves
        there and imaging waits with `readLensPos` (the lens does not move within a segment).
        The periodic autofocus is centred on the focus of the current segment.
     4. for every depth in a **global** z grid (`start_min : step : end_max`, cut to this tile's
        start..end): moves the stage, runs `dynamic_focus` every `focus_count` slices, snaps
        the image, and writes a TIFF
     5. fills the rest of the global z range with zero images so every tile's stack has the same length
   - at the end, turns the lasers off, returns the stage to the start position, and appends the total time to the xlsx

Output layout:

```
<dir>/<color>/<X>/<X>_<Z>/<X>_<Z>_<Y>.tiff        X,Z,Y = round(pos+30000)*10, zero-padded to 6 digits
<dir>/power<P>_exp<E>/640nm/...                   (640 nm analog mode: one tree per power x exposure)
```

## 4. Autofocus (`dynamic_focus`)

The search starts from the color's `Detectionlens` value in `UITable_offset`, not from the
current position. Since 2026-11-20 imaging passes a third argument, `dynamic_focus(app, channel,
center)`, with `tileFocus(...)`: the search (and the fall-back position) is centred on the tile's
focus if one is set. Without the third argument it uses the offset value as before. The two methods:
- **Entropy (Original)**: scan ±20 µm in 4 µm steps and take the Shannon entropy of the
  central 1000x1000 crop. The lens moves to the maximum only if the curve has a single peak;
  otherwise it returns to the offset.
- **Tenengrad (default)**: scan ±60 µm in 5 µm steps on a 4x-downsampled image, refine the peak
  with a parabolic fit, and return to the offset if the peak is at the edge of the range.
  After the final move (or the move back) it waits with `readLensPos` until the lens has stopped.

`DCTS` / `abslog2` / `calculate_sharpness` are helper metrics; `DCTS` is not used.

## 5. Dead code still inside the app

These callbacks exist in the code but no UI component is bound to them:
`MoveandStitch_3DButtonPushed`, `movetileButtonPushed`, `save_checkpointButtonPushed`,
`SaveImagetwopathButtonPushed`, `zstack_distanceumValueChanged`.
They also reference components that no longer exist (`galvo_Xview`, `Check_points`, `num_zstacks`, …).
Several properties are unused, for example `AFG_voltage1/2`, `ExtLens2_pos`,
`checkpoints_onetile`, `xinitPos1`, `scanrow`, `exposure_time`, `flag_request_af`, `flag_request_hist`.
All the `current_path == 2` branches are placeholders (`a=1;`), so only path 1 works.

## 6. Known bugs

Last checked against the code on 2026-11-04 (by reading the code; nothing was run on the
microscope). Priority: **High** = wrong hardware state or lost/misplaced data,
**Med** = a feature fails or the user can be misled, **Low** = cosmetic or log only.

### 6.1 Open

| # | Priority | Where | Problem | Effect |
|---|---|---|---|---|
| 6 | Med | `startimagealltilesButtonPushed`, outer `catch` | `exist('app.waitbar','var')` and `exist('app.wait_status','var')` are always false | After an imaging error the progress window stays open |
| 7 | Med | `RollScanButtonValueChanged` | `fwrite(controlParameters.afg, …)` is missing `app.` | Turning Roll Scan on errors before `output2 on` |
| 8 | Med | `PaintButtonValueChanged` | `zeros(2048*21, 2048*21)` (double, about 14.8 GB); `imshow` without `Parent` | Paint can run out of memory; the image can be drawn into the wrong figure |
| 9 | Low | `startimagealltilesButtonPushed`, Excel log | `reshape(x, V, H)`, but `createScanpattern` orders tiles z-fastest (H first); should be `reshape(x, H, V)'`. Same for the new `9_Skipped_Grid` sheet | The start/end/slice/skip grids in the xlsx are arranged wrong (the log only, not the images) |
| 10 | Low | zero-fill loops and `fillSkippedTile` | real file names use the *measured* Y; zero-fill uses the *nominal* grid Y | If the stage lands ±1 µm off, a zero image can be added next to the real slice |
| 12 | ? | `startimagealltilesButtonPushed` | AFG ramp always uses row 2 (561 nm) Top/Bottom for every color | Per-color ramp settings are ignored (may be intentional; ask before changing) |
| 13 | Low | `startimagealltilesButtonPushed` | imaging writes the shutter voltage directly (`[4,…]` / `[0,…]`) without updating `app.Shutterstate1` / `ShutterButton.Value`; galvo sliders/◀▶, Reset galvo, path table edit, wavelength change and Light Path resend `app.Shutterstate1` (found 2026-11-06). The Paint part was fixed 2026-11-06. Imaging is left unchanged on purpose (Fengyi, 2026-11-06) | After an imaging run the shutter is closed while the Shutter button may still show open; the next galvo move / wavelength change / Enable Camera opens it again (which is what Fengyi wants: the shutter is normally open) |

### 6.2 Fixed or disabled

| Where | Problem | Status |
|---|---|---|
| `ImagesavingdirectoryButtonPushed` (was open bug 5) | cancelling `uigetdir` wrote `0` to `app.dirname` and `pathEditField` | Fixed 2026-11-04: cancel keeps the old folder (not tested on the microscope) |
| `RunAutoFocusButtonPushed` (was open bug 11) | wavelength "None" gave a dimension error in `dynamic_focus` | Gone 2026-11-04: the Run AutoFocus button and callback were removed (imaging always passes a real colour) |
| `StopAnalogButtonPushed`, `SvAFG2ButtonPushed` | `ChangePowerObis` arguments in the wrong order; 640 nm went to 1 mW | Fixed 2026-11-04 (not tested on the microscope) |
| `ResetImagingButtonPushed` | kept the old `app.dirname`, so the next run saved into the old folder | Fixed 2026-11-04 (not tested on the microscope) |
| camera frame-wait loops (`requestoneimagefromcamera`, Paint, Up/Down/Left/Right, Center) | no timeout; app hung if the camera sent no frame | Fixed 2026-11-04: `checkCameraTimeout` (not tested on the microscope) |
| `dynamic_focus`, Tenengrad branch (was open bug 4) | the final `1PA` move and the two revert moves had no wait, so the first images could be taken while the lens was moving | Fixed 2026-11-05: `readLensPos` after each of the three moves (not tested on the microscope) |
| `dynamic_focus` (Entropy) | extra `1TP?` left a stale reply in the serial buffer; lens position reads lagged | Fixed 2026-11-03 (query removed; `readLensPos.m` added) |
| `selfmade/getpos.m` | scientific-notation replies parsed wrongly | Fixed 2026-11-03 |
| lens ◀ ▶ buttons (`left/rightButtonExt/Obj`) | a click during a move ran inside the running callback (during the `pause` in `readLensPos`), so moves overlapped; reported 2026-11-20 as "the left/right direction sometimes reverses" (the code direction never changed: left = +, right = -; the old code on D: also showed stale positions, one or more steps behind) | Fixed 2026-11-20: both buttons of the lens are disabled until the move has finished; clicks queued meanwhile are dropped (not tested on the microscope). Not covered: wavelength change / autofocus moving the same lens at the same time |
| `createscanpatterncenterButtonPushed` | kept tile data from the previous pattern | Fixed 2026-11-03 |
| `SnapHistogramButtonPushed` | used the missing `app.TargetIntensityEditField` | Disabled 2026-11-03 (code commented out) |
| `UIFigureKeyPress` → `movenexttile` / `moveprevioustile` / `movenextcheck` / `moveprevcheck` | used the missing `app.movecheckpoints1x6Spinner` | Disabled 2026-11-03 (key handler commented out; the four helpers are now dead code). Since 2026-11-09 the handler only runs the arrow-key stage moves (`stageKeyPress`); the old keys stay off. The shortcut list in section 2 still showed the old keys until 2026-11-09 |
| `UITable_pathCellEdit` | used the missing `app.galvo_ZSlider` | Disabled 2026-11-03 (Galvo_Z column locked, branch commented out); rewritten 2026-11-05 for the merged table (no Galvo_Z column) |

Note: `save_checkpointButtonPushed` still uses `app.galvo_ZSlider`, but no button calls
it (dead code), so it does not cause errors.

## 7. Refactoring ideas for future updates

- The four color blocks in `startimagealltilesButtonPushed` (about 900 lines) are almost
  identical. They could become one `acquireChannel(app, idx, tile_index, positions)` function.
- The 488/561/640/730 to index mapping is repeated in about 8 places. One helper, e.g.
  `idx = colorIndex(app.Lightwavelight.Value)`, would replace them.
- Hard-coded constants (0.65 µm/px, 2048 px, 15 % overlap, 6 s filter-wheel wait, the 640 nm
  analog calibration `calib_V/calib_P`, power caps 20/30/50 mW) could live in one config struct
  or in `states_record.xlsx`.
- Add a "save calibration" button that writes `UITable_offset`/`UITable_afg` back to `states_record.xlsx`.
- Replace `evalin('base', …)` with a hardware-init function that returns `controlParameters`.
- `serial()` and `daq.createSession` are deprecated in recent MATLAB versions.
  The replacements are `serialport` and `daq("mcc")`.
