# Patch 2026-11-04: high-priority bugs 1-3 (to apply in App Designer)

**Status: APPLIED on 2026-11-04 by script** (see `docs/PROGRESS_LOG.md`). Do not apply again.
This file is kept as a readable record of exactly what changed. Bug numbers refer to the
2026-11-04 version of `docs/V5_app_guide.md` section 6.1.

Backup of the app before the patch: `_archive/MMcodeOrcaV2/LightSheetControl_before_high_bugs.mlapp`.

Tip: use Ctrl+F in Code View to jump to each function name.

---

## Bug 1: 640 nm laser drops to 1 mW after Stop Analog / SvAFG2

`ChangePowerObis` takes `(port, power_mW, max_mW)`.

**`StopAnalogButtonPushed`**: 2 lines (one in the `if`, one in the `else`). Replace

```matlab
ChangePowerObis(lz640, 1, target_mW);
```
with
```matlab
ChangePowerObis(lz640, target_mW, app.allLasers(idx640).maxPower);
```

**`SvAFG2ButtonPushed`**, near the end, in "Restore Laser to CW Mode": 2 lines. Replace

```matlab
ChangePowerObis(lz, 1, target_mW);
```
with
```matlab
ChangePowerObis(lz, target_mW, app.allLasers(laser_idx).maxPower);
```

---

## Bug 2: Reset keeps the old save folder

**`ResetImagingButtonPushed`**: after the line

```matlab
app.pathEditField.Value = "";
```
add
```matlab
app.dirname = 'D:\Data';   % (2026-11-04) same as start-up, so imaging asks for a new folder
```

(`startimagealltilesButtonPushed` refuses to start while `app.dirname` is `'D:\Data'`.)

---

## Bug 3: the app hangs if the camera sends no frame

### 3a. New helper function

Paste this directly **after the `end` of `requestoneimagefromcamera`**, in the same
`methods` block:

```matlab
        function checkCameraTimeout(app, t0)
            % (2026-11-04) Stops waiting for a camera frame after 5 s + exposure time,
            % so a stuck camera raises an error instead of hanging the app.
            limit_s = 5 + app.controlParameters.MMC.getExposure()/1000;
            if toc(t0) > limit_s
                app.controlParameters.MMC.stopSequenceAcquisition;
                app.controlParameters.MMC.clearCircularBuffer;
                error('LightSheet:cameraTimeout', 'Camera timed out: no image after %.1f s.', limit_s);
            end
        end
```

### 3b. Seven wait loops

Each of these functions has exactly one loop that starts with

```matlab
while(app.controlParameters.MMC.getRemainingImageCount()>0 || app.controlParameters.MMC.isSequenceRunning())
```

Change each one to:

```matlab
cam_t0 = tic;   % (2026-11-04) camera timeout
while(app.controlParameters.MMC.getRemainingImageCount()>0 || app.controlParameters.MMC.isSequenceRunning())
    checkCameraTimeout(app, cam_t0);
    if app.controlParameters.MMC.getRemainingImageCount()>0
        ... (unchanged)
```

That is: one new line **before** the `while`, one new line as the **first line inside** it.

- [ ] `requestoneimagefromcamera` (used by Entropy autofocus)
- [ ] `PaintButtonValueChanged`
- [ ] `UpButtonPushed`
- [ ] `DownButtonPushed`
- [ ] `LeftButtonPushed`
- [ ] `RightButtonPushed`
- [ ] `CenterButtonPushed`

(`EnableCamButtonPushed` already has its own 5 s timeout; leave it.)

What happens on a timeout: the function raises an error.
- During multi-tile imaging (Entropy autofocus), the outer `catch` stops imaging and turns all lasers off.
- With the Run AutoFocus button, the error is caught and printed.
- In Paint, Up/Down/Left/Right and Center, the error is printed in the command window and the button does nothing.

---

## After applying

1. Save the app. In the MATLAB command window run
   `checkcode('MMcodeOrcaV2/LightSheetControl.mlapp')`. Expect no errors; the last count was
   about 368 warnings.
2. In `docs/PROGRESS_LOG.md`, remove "not applied yet" from the 2026-11-04 patch entry, and
   in `docs/V5_app_guide.md` 6.1 move bugs 1-3 to 6.2.
3. On the microscope, test:
   - Stop Analog with 640 nm selected. The power should match the UI, not 1 mW.
   - Reset. Start imaging should then ask for a folder.
   - Paint and Up/Down/Left/Right still work.
   - Optional: unplug or stop the camera and press Up. You should get an error after about 5 s, not a hang.
