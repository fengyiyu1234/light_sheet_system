# CLAUDE.md

Notes for Claude Code (local CLI and claude.ai/code). Tracked in git, so every machine and
the web version see the same file.

## Project
MATLAB control code for a light-sheet microscope (Micro-Manager + OBIS lasers + AFG + motors).
Maintainer: Fengyi Yu. The user writes in Chinese; reply in Chinese.

- Main app: `MMcodeOrcaV2/LightSheetControl.mlapp` (App Designer, zipped).
- Hardware init script: `MMcodeOrcaV2/init_hardware.m`.
- Helpers: `MMcodeOrcaV2/selfmade/`, `OBISgeneral/`, `AfgCode/`, `FilterWheel/`, `UsefullFunctions/`.
- `_archive/`: unused old code and backups; not in git, exists only on this drive.
- Docs: `README.md`, `docs/V5_app_guide.md` (app structure, known bugs in section 6),
  `docs/PROGRESS_LOG.md` (history of every change, newest first).

## Start of every session
Read `docs/PROGRESS_LOG.md` first (at least the newest entries and the TODO list). It is the
project memory; Claude Code's own memory is per machine and per path and is usually empty here.

## Copies of the code
- Research drive (this folder; was `Y:\Fengyi\lightsheet_system` on the workstation,
  `/Volumes/DeepDesign/Fengyi/lightsheet_system` on the Mac). Edits are made here.
- Microscope PC: `D:\lightSheetsourcecode_twopath_multipower` (old copy, other people still use it;
  do not change its MATLAB path permanently). It has NOT been updated with the new code yet.
- claude.ai/code works on a GitHub clone: `_archive/` and the ignored files (images, `.mat`)
  are not there, so backups cannot be made in `_archive/` from the web; rely on git history.
- Nothing here can be run on the microscope from this machine: changes are "not tested on the
  microscope" until the user says so.

## Rules for editing
1. Before changing a file (local copy only), copy it to `_archive/<same relative path>/<name>_before_<what>.<ext>`.
2. `.mlapp` edits: the code is stored twice, in `matlab/document.xml` and in
   `appdesigner/appModel.mat`. Both must match after an edit (previous entries rebuilt
   `appModel.mat` from `document.xml` and compared callbacks). Run `checkcode` and compare the
   warning count with the previous one.
3. UI controls (adding/removing buttons) must be done by the user in App Designer Design View;
   write the needed steps as a TODO instead.
4. After every change, add an entry at the top of `docs/PROGRESS_LOG.md` in the same format:
   request, what changed, backup path, checks, and whether it was tested on the microscope.
5. If a bug is fixed or found, update the table in `docs/V5_app_guide.md` section 6.
6. Do not commit or push unless the user asks.
