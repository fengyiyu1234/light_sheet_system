# Light-sheet microscope control (Greenbaum Lab, NCSU)

MATLAB control software for the lab's light-sheet microscope: Hamamatsu ORCA camera
through Micro-Manager 1.4, ASI Tiger stage, Newport lens motors, 4 Coherent OBIS
lasers, a filter wheel, an MCC DAQ (shutter + galvos) and two function generators.

The current production GUI is
`MMcodeOrcaV2/LightSheetControl.mlapp` (renamed in Nov 2026 from
`app_for_lightsheet_V2_main_autofocus_autopower_V5.mlapp`; the code is the same).
For a walkthrough of what the app does internally, see [docs/V5_app_guide.md](docs/V5_app_guide.md).

## How to start the microscope

1. In MATLAB (the app was written for R2019a), `cd` into `MMcodeOrcaV2`.
   The app reads `states_record.xlsx` from the current folder.
2. Run `init_hardware.m` (formerly `LightSheet_10x_02032026_RunAll2.m`). It opens every hardware connection and
   puts two variables in the base workspace:
   - `controlParameters`: a struct of hardware handles (see below)
   - `allLasers`: a 1x4 struct array, 488 / 561 / 640 / 730 nm, with `.serialPort` and `.maxPower`
3. Open and run `LightSheetControl.mlapp`.
   Its `startupFcn` gets both variables with `evalin('base', ...)`, so step 2 has to come first.

> Both the init script and the app's `startupFcn` call `addpath` with
> **`D:\lightSheetsourcecode_twopath_multipower\...`**, which is where the code lives
> on the microscope PC. If you check the repo out somewhere else, change those paths.

## Repository layout (only files that are actually used)

```
MMcodeOrcaV2/
  LightSheetControl.mlapp             main GUI (App Designer)
  init_hardware.m                     hardware init script (run first)
  states_record.xlsx                  start-up calibration tables read by the app (see guide)
  magnify.m                           3rd-party magnifier used by the Live View window
  selfmade/
    getXYZposition.m                  read X/Y/Z from the ASI stage
    SetRelativePos.m                  relative X/Y/Z move + wait
    getpos.m                          parse Newport "1TP?" reply
    createScanpattern.m               build the M x N tile grid
AfgCode/          Tektronix AFG3022 (afg) + Siglent SDG1022X (afg2): connect, DC, ramp
OBISgeneral/      OBIS laser: init, on/off, set/check power, disconnect
FilterWheel/      detection filter wheel: init, get/set position
UsefullFunctions/CalibrationFunctions/
  InitiateHardware.m                  load Micro-Manager config -> mmc
  InitTheMotor.m                      open a Newport lens-motor serial port
  ShowAllRunningDevices.m             print loaded MM devices
config/
  configuration_03132026.cfg          backup copy of the Micro-Manager hardware config
```

MATLAB's `requiredFilesAndProducts` confirmed that the files above are all the init
script and the app need.
Required toolboxes: Image Processing, Wavelet (`wentropy` autofocus), Data Acquisition
(+ MCC support package), and Instrument Control (`visa`, `serial`). The Micro-Manager 1.4
Java API (`mmcorej`) must also be on the Java class path.

## Hardware map (from the init script)

| Handle (`controlParameters.`) | Device | Connection |
|---|---|---|
| `MMC` | Micro-Manager core: camera `HamamatsuHam_DCAM`, stage `XYStage:XY:31`, `ZStage:Z:32`, `ZStage:T:32` | `C:\Program Files\Micro-Manager-1.4\configuration_03132026.cfg` |
| `sExtLens1` | Excitation-lens motor (Newport) | COM7 |
| `sDetLens` | Detection-lens motor (Newport) | COM15 |
| `sFWDet` | Detection filter wheel | COM11 |
| `afg` | Tektronix AFG3022: ch1 = light-sheet galvo ramp, ch2 = DC offset | VISA USB |
| `afg2` | Siglent SDG1022X Plus: 640 nm analog-power / camera-trigger waveforms | VISA USB |
| `s1` | MCC DAQ session: Ao1 shutter, Ao2 galvo X, Ao3 galvo Y, Ao0 galvo Z | `outputSingleScan(s1,[shutter gx gy gz])` |
| `allLasers(1..4).serialPort` | OBIS 488 / 561 / 640 / 730 nm | COM4 / COM5 / COM6 / COM17 |

Filter wheel positions: 1 empty, 2 = 525/39, 3 = 593/40, 4 = 676/37, 5 = 785/62,
6 = Semrock multi-notch NF03-405/488/561/635E.

The init script loads the Micro-Manager config from `C:\Program Files\Micro-Manager-1.4\`;
`config/` holds a backup copy of it. If you change the hardware setup, update both.

**TODO:** copy `javaclasspath.txt` and `librarypath.txt` from the microscope PC's MATLAB
`prefdir` into `config/`. These files let MATLAB find the Micro-Manager Java API (`mmcorej`).

## `_archive/` (not tracked by git)

The November 2026 cleanup moved 261 unused files into `_archive/`, keeping their
original relative paths. `_archive/MANIFEST_moved_files.txt` lists every file. Main contents:

- ~30 older `.mlapp` versions. Features that the current app does **not** have:
  - V1–V3: auto laser power (`auto_laser_power_*`, HDPR acquisition)
  - M1: CMS4 multispectral-camera buttons
  - `autofocus_RTA_dev`: real-time tile alignment
- Older init/acquisition scripts (2017–2025), laser/camera test scripts, and Silios CMS4V experiments
- Deep-learning models (`*.pt`, about 200 MB), Python predictors, and the deformable-mirror wrapper
- Old calibration and DC-motor/joystick code, plus sample images and `.mat` data
- The full original init script: `MMcodeOrcaV2/LightSheet_10x_02032026_RunAll2_ORIGINAL_full.m`

To restore a file, move it back to the same relative path.
