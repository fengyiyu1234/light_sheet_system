% Greenbaum Lab
% greenbaum@ncsu.edu, rspate@ncsu.edu
% init_hardware.m  (formerly LightSheet_10x_02032026_RunAll2.m)
% July 12, 2019
% Updated: September 24, 2024
% Script for operation of light sheet microscope
%
% HOW TO USE (2026-11 cleanup note):
%   1. Set MATLAB's current folder to MMcodeOrcaV2 (scanpattern.mat and
%      allpoints.mat are saved there; code paths are found automatically).
%   2. Run this script once. It creates `controlParameters` and `allLasers`
%      in the base workspace.
%   3. Then start LightSheetControl.mlapp (formerly
%      app_for_lightsheet_V2_main_autofocus_autopower_V5.mlapp);
%      the app reads both variables with evalin('base', ...).
%   About 950 lines of commented-out legacy code (old calibration and scan
%   routines) were removed from the end of this file. The full original is
%   _archive/MMcodeOrcaV2/LightSheet_10x_02032026_RunAll2_ORIGINAL_full.m
%

% Code folders are found relative to this script (MMcodeOrcaV2\), so the
% repo can be cloned into any folder.
appDir = fileparts(mfilename('fullpath'));
if isempty(appDir)   % e.g. code pasted into the command window
    appDir = fileparts(which('init_hardware'));
end
if isempty(appDir)
    error('Cannot find init_hardware.m: cd to the MMcodeOrcaV2 folder and run the script again.');
end
repoDir = fileparts(appDir);

% The old copy of the code (used by other people on this PC) is on the saved
% MATLAB path. Remove its folders for THIS MATLAB SESSION ONLY, so none of its
% functions can be called by mistake. No savepath: the saved path is not
% changed, and restarting MATLAB brings the old folders back.
oldCodeDir = 'D:\lightSheetsourcecode_twopath_multipower';
p = strsplit(path, pathsep);
oldEntries = p(startsWith(p, oldCodeDir, 'IgnoreCase', true) & ...
               ~startsWith(p, repoDir, 'IgnoreCase', true));
if ~isempty(oldEntries)
    rmpath(oldEntries{:});
    fprintf('Removed %d folder(s) of the old code from the path (this session only).\n', numel(oldEntries));
end
if startsWith(pwd, oldCodeDir, 'IgnoreCase', true) && ~startsWith(pwd, repoDir, 'IgnoreCase', true)
    error('The current folder is inside the old code (%s). cd to %s and run again.', oldCodeDir, appDir);
end
clear p oldEntries

addpath(fullfile(repoDir,'AfgCode'), ...
        fullfile(repoDir,'FilterWheel'), ...
        fullfile(repoDir,'OBISgeneral'), ...
        fullfile(repoDir,'UsefullFunctions','CalibrationFunctions'), ...
        fullfile(appDir,'selfmade'));
% (DCMotor, UsefullFunctions\PickTiles and MMcodeOrcaV2\wholezstackfiles were
%  removed from the path in the 2026-11 cleanup: nothing in this script or in
%  the V5 app uses them. The originals are in _archive/.)
% 
% % NuMorph + runtime helpers
% addpath('D:\emre\NuMorph-align');
% addpath(genpath('D:\emre\NuMorph-align\src'));
% addpath('D:\emre\rt_align_scaffold');


%% SETUP (initialize stages, galvos, camera, and shutter)
% run app_test
% Which lasers to use
% [488,561,640,730]; 
avilableLasers = [1 1 1 1];
lightSheetMode = false;

pixelSizeUm = 6.5;
tubeLensFocalDistance = 180; %mm
objectiveDesignedTubeLensFocal = 180; %mm
objectiveMag = 10;

% Parameters for MicroManager
% pathToCfgFile = 'C:\Program Files\Micro-Manager-1.4\configuration_05302019.cfg';
pathToCfgFile = 'C:\Program Files\Micro-Manager-1.4\configuration_03132026.cfg';
[mmc] = InitiateHardware(pathToCfgFile); 
cameraLabel = 'HamamatsuHam_DCAM';
stageLabel = 'XYStage';

% Assign Serial Ports
portExt1 = 'COM7'; % Excitation stage
%portExt2 = 'COM10';
portDet = 'COM15'; % Detection stage
portFWDet = 'COM11'; % Filter wheel (detection)

%portObis488nm = 'COM5'; % 488nm Laser
%portObis561nm = 'COM6'; % 561nm Laser
%portObis640nm = 'COM4'; % 640nm Laser
%portObis730nm = 'COM17'; % 730nm Laser

portObis488nm = 'COM4'; % 488nm Laser
%portObis488nm = 'COM17'; % 488nm Laser
%portObis561nm = 'COM5'; % 561nm Laser
%portObis640nm = 'COM6'; % 640nm Laser
portObis730nm = 'COM17'; % 730nm Laser
%portObis730nm = 'COM4'; % 730nm Laser

%0727 fengyi
portObis561nm = 'COM5'; % 561nm Laser
portObis640nm = 'COM6'; % 640nm Laser

%portExt2 = 'COM19';

% Initiate the filter wheel
[sFWDet] = InitFW(portFWDet);
% 1 is empty
% 2 is for 525-39 mm
% 3 is for 593/40-25 mm
% 4 is for 676/37-25
% 5 is for 785/62
% 6 is for semrock multi band notch filter 405/10, 488, 561, 635/9 Semrock Part Number: NF03-405/488/561/635E-25
sFWExt = 0;
% Init stages
% Path 1 excitation
[sExtLens1] = InitTheMotor(portExt1); 
% Path 2 excitation
% [sExtLens2] = InitTheMotor(portExt2); 
% Detection objective
[sDetLens] = InitTheMotor(portDet); 
% Arbitrary function generator
[afg] = EstablishComAfg();
[afg2] = EstablishComAfg2();
disp(['AFG Buffer Size: ' num2str(afg.OutputBufferSize)]);
disp(['AFG2 Buffer Size: ' num2str(afg2.OutputBufferSize)]);
% Establish connection to the MCC DAQ (make sure channels are correct)
s1 = daq.createSession('mcc');
shutter1 = addAnalogOutputChannel(s1,'Board0', 'Ao1', 'Voltage');
galvoX1 = addAnalogOutputChannel(s1,'Board0', 'Ao2', 'Voltage');
galvoY1= addAnalogOutputChannel(s1,'Board0', 'Ao3', 'Voltage');
galvoZ1= addAnalogOutputChannel(s1,'Board0', 'Ao0', 'Voltage');

%In multi color light sheet mode is not implemented
expWindowHeight = 30; %pixels, it should be calculated as the size of the FWHM of the light sheet

controlParameters = struct('MMC', mmc, 'cameraLabel', cameraLabel, 'stageLabel', stageLabel, ...
    'sFWDet', sFWDet,'sFWExt',sFWExt, 'sExtLens1', sExtLens1,'sDetLens',...
    sDetLens,'afg', afg,'afg2', afg2,'shutter1',shutter1, 'galvoX1',galvoX1,'galvoY1',galvoY1,'s1',s1);

% Put the AFG voltage at zero
[dcValueAfterWrite] = SetAfgDCValue(afg, 0);
fwrite(afg, ':output1 off;');
fwrite(afg, ':output2 off;');

[dcValueAfterWrite2] = SetAfg2DCValue(afg2, 0);
% fwrite(afg2, ':output1 off;');
% fwrite(afg2, ':output2 off;');
fprintf(afg2, 'C1:OUTP OFF');
fprintf(afg2, 'C2:OUTP OFF');

% Set the Thorlabs galvos to 0 (mcc)
outputSingleScan(s1, [0,0,0,0]);

%Set the light path to excitation 1
path1Excitation = 1;
path2Excitation = 2;
% shutters.open(path1Excitation);
% shutters.close(path2Excitation);
curPath = 1;

downSampleFactor = 1;
mmc.setTimeoutMs(50000);
mmc.getTimeoutMs()
% to store many images in the camera buffer
mmc.setCircularBufferMemoryFootprint(1024);

%% LASER SETUP (initiate the lasers based on availability)

fprintf(sExtLens1,['1PA','4.56']);

disp('laser set up...')
%488 nm 
if (avilableLasers(1))
    [s488nm] = InitObis(portObis488nm);    
end
%561 nm 
if (avilableLasers(2))
    [s561nm] = InitObis(portObis561nm);    
end
%640 nm
if (avilableLasers(3))
    [s640nm] = InitObis(portObis640nm);    
end
% 730 nm
if (avilableLasers(4))
    [s730nm] = InitObis(portObis730nm);    
end
%Define lasers parameters
%Control type:
%PS - power supply
%OBIS - OBIS software
%FW - filter wheel

%The two rows format is for the second light path
laserParameters = struct('wavelength', 405, 'maxPower', 50, 'available', false, 'filterEmission', 1,...
    'filterAF', 1,'filterExcitation', 1,'posExtLens', [0; 0], 'posDetLens', [0; 0], 'symmetry',...
    [97; 97], 'Delay', [0 0 0 0 0 0; 0 0 0 0 0 0], 'OptimalDelay', [0; 0], 'FrameRates', [50 25 15 10 7 5], 'serialPort',0,'ControlType','PS',...
    'minVoltage',-600, 'maxVoltage',600, 'chromaticAberrationDetLens', 0.01, 'newFreq', 0);

numOfActiveLasers = sum(avilableLasers);
allLasers = laserParameters;
indAllLasers = 0;

%488 laser
if (avilableLasers(1))
    laser488nm = laserParameters;
    laser488nm.wavelength = 488;
    laser488nm.maxPower = 30; %mW
    laser488nm.available = true;
    laser488nm.filterEmission = 1;
    laser488nm.filterAF = 1;
    laser488nm.filterExcitation = 2;
    laser488nm.posExtLens = [-0.05,4.10992];
    laser488nm.posDetLens = [-.0249,-0.0549];
    laser488nm.symmetry = [80; 90.1]; 
    laser488nm.Delay = [11.86 25.4 39.52 75.1 84.6 118.01; 11.86 25.5 39.52 75.2 77.3 118.01];
    laser488nm.OptimalDelay = [25.4; 25.5];
    laser488nm.FrameRates = [50 25 15 10 7 5];
    laser488nm.serialPort = s488nm;
    laser488nm.ControlType = 'OBIS';
    laser488nm.minVoltage = [-529; -394];
    laser488nm.maxVoltage = [527;350];
    laser488nm.chromaticAberrationDetLens = 0.01;
    indAllLasers = indAllLasers + 1;
    allLasers(indAllLasers) = laser488nm;    
end


%561 laser 
if (avilableLasers(2))
    laser561nm = laserParameters;
    laser561nm.wavelength = 561;
    laser561nm.maxPower = 30;
    laser561nm.available = true;
    laser561nm.filterEmission = 3;
    laser561nm.filterAF = 1;
    laser561nm.filterExcitation = 3;
    laser561nm.posExtLens = [0.04997; -1.62];
    laser561nm.posDetLens = [0.00; 0.00];
    laser561nm.symmetry = [94.9; 97.5]; %[92.4 92.4 91.4 91.3 91.5 91.4]
    laser561nm.Delay = [12.16 25.4 40.62 60.9 87.1 121.8; 12.16 25.6 40.62 60.9 87.1 121.8]; %ms
    laser561nm.OptimalDelay = [25.4; 25.6]; %ms
    laser561nm.FrameRates = [50 25 15 10 7 5];
    laser561nm.serialPort = s561nm;
    laser561nm.ControlType = 'OBIS';
    laser561nm.minVoltage = [-650; -650];
    laser561nm.maxVoltage = [650; 650];
    laser561nm.chromaticAberrationDetLens = 0.01;
    indAllLasers = indAllLasers + 1;
    allLasers(indAllLasers) = laser561nm;    
end

%640 laser 
if (avilableLasers(3))
    laser640nm = laserParameters;
    laser640nm.wavelength = 640;
    laser640nm.maxPower = 30;
    laser640nm.available = true;
    laser640nm.filterEmission = 4;
    laser640nm.filterAF = 1;
    laser640nm.filterExcitation = 4;
    laser640nm.posExtLens = [-0.07, 4.23992];
    laser640nm.posDetLens = [-0.0049, -0.0249];
    laser640nm.symmetry = [80.1; 90.1]; %[92.4 92.4 91.4 91.3 91.5 91.4]
    laser640nm.Delay = [12.16 25.5 75 75.3 87.1 121.8; 12.16 25.4 75 75.2 87.1 121.8]; %ms
    laser640nm.OptimalDelay = [25.5; 25.4]; %ms
    laser640nm.FrameRates = [50 25 15 10 7 5];
    laser640nm.serialPort = s640nm;
    laser640nm.ControlType = 'OBIS';
    laser640nm.minVoltage = [-549;-414];
    laser640nm.maxVoltage = [513;319];
    laser640nm.chromaticAberrationDetLens = 0.01;
    indAllLasers = indAllLasers + 1;
    allLasers(indAllLasers) = laser640nm;    
end

%730nm laser 
if (avilableLasers(4))
    laser730nm = laserParameters;
    laser730nm.wavelength = 730;
    laser730nm.maxPower = 30;
    laser730nm.available = true;
    laser730nm.filterEmission = 5;
    laser730nm.filterAF = 1;
    laser730nm.filterExcitation = 5;
    laser730nm.posExtLens = [-0.07, 4.23992];
    laser730nm.posDetLens = [-0.0049, -0.0249];
    laser730nm.symmetry = [80.1; 90.1]; %[92.4 92.4 91.4 91.3 91.5 91.4]
    laser730nm.Delay = [12.16 25.5 75 75.3 87.1 121.8; 12.16 25.4 75 75.2 87.1 121.8]; %ms
    laser730nm.OptimalDelay = [25.5; 25.4]; %ms
    laser730nm.FrameRates = [50 25 15 10 7 5];
    laser730nm.serialPort = s730nm;
    laser730nm.ControlType = 'OBIS';
    laser730nm.minVoltage = [-549;-414];
    laser730nm.maxVoltage = [513;319];
    laser730nm.chromaticAberrationDetLens = 0.01;
    indAllLasers = indAllLasers + 1;
    allLasers(indAllLasers) = laser730nm;    
end

SwitchOnOffObis(allLasers(1).serialPort,0); 
SwitchOnOffObis(allLasers(2).serialPort,0); 
SwitchOnOffObis(allLasers(3).serialPort,0);
SwitchOnOffObis(allLasers(4).serialPort,0);

ChangePowerObis(allLasers(1).serialPort,1,5);
ChangePowerObis(allLasers(2).serialPort,1,5);
ChangePowerObis(allLasers(3).serialPort,1,5);
ChangePowerObis(allLasers(4).serialPort,1,5);

disp('            ...done')

%% OPTIONAL: recover lasers stuck in analog-modulation mode
% Uncomment and run this section manually only if a laser was left in
% AM/analog mode (e.g. after the V5 app's 640 nm analog acquisition crashed).


% % In case any laser stuck in Analog Mode, Run This
% disp('Forcing all lasers to standard CW mode...');
% for k = 1:4
%     if allLasers(k).available
%         lz_port = allLasers(k).serialPort;
%         try
%             % Clear buffer
%             while lz_port.BytesAvailable > 0; fscanf(lz_port); end
%             
%             % Force to Constant Wave Power (CWP)
%             fprintf(lz_port, 'SYST:COMM:PROM OFF');                
%             fprintf(lz_port, 'SOURce:AM:STATe OFF');
%             fprintf(lz_port, 'SOURce:AM:INTernal CWP'); 
%             fprintf(lz_port, 'SOURce:AM:STATe ON');   
%             fprintf(lz_port, 'SYST:COMM:PROM ON');
%             
%         catch
%             disp(['Warning: Could not force CW mode on laser ', num2str(k)]);
%         end
%     end
% end
% disp('             ...ok');
