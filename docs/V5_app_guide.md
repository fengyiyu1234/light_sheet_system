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
| 2 | `state_path` / `UITable_path` | Galvo X/Y/Z voltage for the current path |
| 3 | `state_motor` / `UITable_motor` | Excitation / detection lens positions (mm) |
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
| galvo_X / galvo_Y sliders, Reset | `galvo_*SliderValueChanged`, `Reset_galvo_XYButtonPushed` | Writes galvo voltages directly |
| Filter wheel | `FilterwheelValueChanged` | `pos=1..6` |
| Enable / Disable Camera | `EnableCamButtonPushed`, `DisableCamButtonPushed` | Live View: a blocking `while` loop in `EnableCam` that runs until `myhandles.continue = false` |
| Live View buttons | `RunAutoFocusButtonPushed`, `ShowGridCheckBoxValueChanged`, `SnapHistogramButtonPushed`, `ImagecontrastValueChanged`, `Exposure_timeEditFieldValueChanged` | Tools that work while Live View is open |
| Stage arrows ⏫⏬⍟⌾⏪⏩↺↻, step dropdowns, Get Position | `Button*_Pushed`, `*_stepDropDownValueChanged`, `GetPositionButtonPushed` | Relative stage moves. Moves are blocked while the status lamp is green (a scan pattern is active), except depth (Y) moves |
| Excitation / Detection lens | `left/rightButtonExt/Obj`, `Ext/ObjStepsizeDropDown` | Newport relative moves (`1PR`), then reads the position back (`1TP?`) |
| save offset for different color | `saveoffsetfordifferentcolorButtonPushed` | Copies the current galvo and lens values into the selected color's row of `UITable_offset` (in memory only) |
| Paint Mode (Paint, Up/Down/Left/Right, Center, Save paint) | `PaintButtonValueChanged`, `Up/Down/Left/RightButtonPushed`, `CenterButtonPushed`, `SavepaintButtonPushed` | Builds a stitched overview on a 21x21-tile canvas (0.65 µm/px) to find the sample and center it |
| AFG_scan, Roll Scan / Roll slider | `AFG_scanButtonValueChanged`, `RollScan*`, `RollSlider*` | Turns the light-sheet ramp on AFG ch1 on or off; roll uses ch2 |
| **M-by-N tiles panel** | see section 3 | Multi-tile z-stack acquisition |
| 640 nm analog tools: SaveImAFG2, SaveImCam, TestTrigger, AFG_Manual_mW, StopAnalog, SvAFG2 | same names + `Pushed`/`ValueChanged` | Development tools for driving the 640 nm laser in analog mode from the Siglent `afg2`, with hardware camera triggering. `SvAFG2` runs a full exposure x power matrix from `HDPRTable` column 3 |

Keyboard shortcuts (`UIFigureKeyPress`):
- `a`/`d`: previous/next tile
- `w`/`s`: next/previous checkpoint
- `i`/`o`: stage depth −/+
- `k`/`l`: save tile start/end
- `space`: save checkpoints
- `←`/`→`: detection lens

## 3. Multi-tile imaging workflow

1. Set **Vertical tile / Horizontal tile** and press **create scan pattern(center)**.
   `createScanpattern` builds a V x H grid centered on the current position. The tile
   step is 0.65 µm/px x 2048 px x 85 % (15 % overlap), and the status lamp turns green.
2. For each tile, use **move to tile** (or `a`/`d`). Set **start** (`k`) and **end** (`l`)
   depth (stage Y; the start must be the smaller value), then press **save checkpoints** (`space`).
   When every tile is saved, the struct is also written to `scanpattern.mat`.
3. Choose the colors (W488/W561/W640/W730), their Power_* / Exposure_* values, the z step,
   the AutoFocus step and method, and the 640 nm mode (Serial/Analog). Set the **Image saving directory**.
4. Press **start image all tiles**. This runs `startimagealltilesButtonPushed`, which:
   - writes `imaging_params_<timestamp>.xlsx` (offsets, HDPR, AFG, powers, start/end/slice grids, settings)
   - for each tile, then each selected color:
     1. switches lasers off, sets the galvo offset and filter wheel, waits 6 s
     2. moves the stage to the tile and its first depth
     3. turns the laser on at the set power, moves both lenses to the color's offsets, and opens the shutter
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
current position. The two methods:
- **Entropy (Original)**: scan ±20 µm in 4 µm steps and take the Shannon entropy of the
  central 1000x1000 crop. The lens moves to the maximum only if the curve has a single peak;
  otherwise it returns to the offset.
- **Tenengrad (default)**: scan ±60 µm in 5 µm steps on a 4x-downsampled image, refine the peak
  with a parabolic fit, and return to the offset if the peak is at the edge of the range.

`DCTS` / `abslog2` / `calculate_sharpness` are helper metrics; `DCTS` is not used.

## 5. Dead code still inside the app

These callbacks exist in the code but no UI component is bound to them:
`MoveandStitch_3DButtonPushed`, `movetileButtonPushed`, `save_checkpointButtonPushed`,
`SaveImagetwopathButtonPushed`, `zstack_distanceumValueChanged`.
They also reference components that no longer exist (`galvo_Xview`, `Check_points`, `num_zstacks`, …).
Several properties are unused, for example `AFG_voltage1/2`, `ExtLens2_pos`,
`checkpoints_onetile`, `xinitPos1`, `scanrow`, `exposure_time`, `flag_request_af`, `flag_request_hist`.
All the `current_path == 2` branches are placeholders (`a=1;`), so only path 1 works.

## 6. Known bugs (found by reading the code; not yet fixed)

| Where | Problem | Effect |
|---|---|---|
| `SnapHistogramButtonPushed` | uses `app.TargetIntensityEditField`, which does not exist | The histogram always fails ("Error plotting histogram") |
| `movenexttile` / `moveprevioustile` / `movenextcheck` / `moveprevcheck` | use `app.movecheckpoints1x6Spinner`, which does not exist | Keys `a` `d` `w` `s` raise an error |
| `UITable_pathCellEdit` | uses `app.galvo_ZSlider`, which does not exist | Editing the Galvo_Z column of the path table raises an error, and the Z voltage is never sent |
| `RollScanButtonValueChanged` | `fwrite(controlParameters.afg, …)` is missing `app.` | Turning Roll Scan on errors before `output2 on` |
| `StopAnalogButtonPushed`, end of `SvAFG2ButtonPushed` | `ChangePowerObis(lz, 1, target_mW)`: arguments in the wrong order (the signature is `(port, power_mW, max_mW)`) | The 640 nm laser goes back to **1 mW**, not the UI power |
| `startimagealltilesButtonPushed`, `catch` | `exist('app.waitbar','var')` is always false | After an error the progress window stays open |
| `startimagealltilesButtonPushed`, Excel log | `reshape(all_starts, V, H)`, but `createScanpattern` orders tiles z-fastest (H first) | The start/end/slice grids in the xlsx are arranged wrong (the log only, not the images) |
| `startimagealltilesButtonPushed` | AFG ramp always uses row 2 (561 nm) Top/Bottom for every color | Per-color ramp settings are ignored (may be intentional) |
| zero-fill loops | real file names use the *measured* Y; zero-fill uses the *nominal* grid Y | If the stage lands ±1 µm off, a zero image can be added next to the real slice |
| `RunAutoFocusButtonPushed` with wavelength "None" | `'None' == '488'` dimension error | The error is caught and nothing happens |

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
