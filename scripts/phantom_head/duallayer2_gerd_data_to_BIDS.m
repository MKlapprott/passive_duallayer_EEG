%% duallayer2_gerd_data_to_BIDS.m
%
% This script converts raw EEG and motion data from a dual-layer phantom head 
% setup into BIDS format, following the BIDS Extension Proposal (BEP) for 
% motion data. The raw EEG data originates from XDF files, which are first 
% converted to EEGLAB .set format with appropriate channel metadata (EEG, Noise, MISC). 
% Motion platform data (translational and rotational movements) is processed from .txt files.
%
% The script prepares BIDS-compliant files and metadata for both EEG and motion modalities:
% - EEG data is exported via EEGLAB’s bids_export function.
% - Motion data is structured following BIDS motion modality conventions using FieldTrip.
%
% Customizations:
% - Paths must be adjusted to the user's local directory structure.
% - The script assumes a specific folder naming convention (folders containing 'stim').
% - Measurement-specific metadata (e.g., condition labels) is read from an external Excel sheet.
% 
% Dataset context:
% - Simulated ERP (N1/P3 complex) measurements on a phantom head.
% - Movements include rest, translational and rotational motions at various speeds, and walking.
%
% IMPORTANT:
% - Requires EEGLAB (with bids-matlab tools) and FieldTrip (for motion BIDS export).
% - Ensure paths and filenames in the script are correct for your environment.
% - Motion data export relies on an unofficial BIDS extension (BEP motion).
%
% Script Workflow:
% 1. Load and preprocess EEG and motion data.
% 2. Save cleaned EEG (.set) and motion (.tsv) files.
% 3. Prepare BIDS metadata (dataset_description.json, README, CHANGES, participants.tsv, etc.).
% 4. Export EEG data to BIDS structure.
% 5. Export motion data to BIDS structure.
%
% Author: Melanie, 2025

%% Preparations

close all; clear all; clc;                                                                          % start with fresh workspace

% set paths


MAINPATH = 'Q:\Neuro\data\projects\all_gait\dual-layerCap\dual-layer-2024_25\eegl\';                                                        % adjust this path to your local environment!!!
cd(MAINPATH)

PATHIN = [MAINPATH, 'rawdata\gerd\'];                                                               % path to raw data (changed from task-Flanker!!!)
PATHOUT = [PATHIN, 'BIDS_prep\']; 

file_paths = dir(fullfile(PATHIN));                                                                 % get access to all folder names
file_paths = file_paths(contains({file_paths.name}, 'stim'));

measurement_info = readtable([MAINPATH, 'measurement_info.xlsx']);                                  % load initial info table
measurement_info = measurement_info(9:end, :);

eeglab

%% prepade data to be stored as BIDS
% Data was available as a .xdf, as this is not a supported file-format, data are saved as .set again.
% Channel infomation is adapted. Different file formats can be saved in the sourcedata folder!


for meas = 1:length(file_paths)

    PATHINSUB = [PATHIN, file_paths(meas).name, '\'];
    cd(PATHINSUB)

    % load data & start quality check ------------------------------------------------------------
    
    files = dir(fullfile(PATHINSUB, '*.xdf'));                                                      % get access to data sets - EEG
    file_name = files.name;

    EEG = pop_loadxdf([PATHINSUB, file_name], 'streamtype', 'EEG', 'exclude_markerstreams', {});    % load data
    EEG = pop_chanedit(EEG, 'lookup',[MAINPATH, 'DualLayer64.elp']);
    EEG.setname = strjoin(['dualLayer2_', num2str(meas), '_', measurement_info{meas, 'cond'}],'');  % give data set a name
    
    [EEG.chanlocs(find(contains({EEG.chanlocs.labels}, 'R'))).type] = deal('Noise');                % assign the Noise label to the Noise electrodes
    [EEG.chanlocs(find(contains({EEG.chanlocs.labels}, 'Acc'))).type] = deal('MISC');               % assign the MISC label to the IMU channels
    [EEG.chanlocs(find(contains({EEG.chanlocs.labels}, 'Gyro'))).type] = deal('MISC');              % assign the MISC label to the IMU channels
    [EEG.chanlocs(find(contains({EEG.chanlocs.labels}, 'Quat'))).type] = deal('MISC');              % assign the MISC label to the IMU channels

    pop_saveset(EEG, EEG.setname ,PATHOUT);


    files_mo = dir(fullfile(PATHINSUB, '*.txt'));                                                   % get access to data sets - motion
    file_name_mo = files_mo.name;

    if meas == 8 || meas == 9
        motion_data = readtable([PATHINSUB, file_name_mo], 'DecimalSeparator', ',');
        motion_data = motion_data(:,1:3);
        motion_data.Properties.VariableNames = {'trans', 'pitch', 'roll'};
    else
        motion_data = readtable([PATHINSUB, file_name_mo]);
        motion_data = motion_data(:,1:3);
        motion_data.Properties.VariableNames = {'trans', 'pitch', 'roll'};
    end
    cd(PATHOUT)
    writetable(motion_data, [EEG.setname, '.tsv'], 'FileType', 'text', 'Delimiter', '\t');


end




%% set up BIDS - EEG

% link to raw data files (EEG) -------------------------------------------------------------------

FILES = dir([PATHOUT,filesep, '*.set']);
nMeas = length(FILES);

data.file = {[FILES(1).folder filesep FILES(1).name], [FILES(2).folder filesep FILES(2).name], ...
    [FILES(3).folder filesep FILES(3).name], [FILES(4).folder filesep FILES(4).name], ...
    [FILES(5).folder filesep FILES(5).name], [FILES(6).folder filesep FILES(6).name], ...
    [FILES(7).folder filesep FILES(7).name], [FILES(8).folder filesep FILES(8).name], ...
    [FILES(9).folder filesep FILES(9).name]}; 
data.session = [1 2 3 4 5 6 7 8 9];    
data.run = [1 1 1 1 1 1 1 1 1];                                                                               


% general information for dataset_description.json file ------------------------------------------

generalInfo.Name = 'Passive Duallayer EEG - Phantom Head';
generalInfo.BIDSVersion = 'v1.10.0';
generalInfo.DatasetType = 'raw';
generalInfo.Authors = {'Melanie Klapprott';...
    'Stefan Debener';...
    'Daniel Ferris'};


% Content for README file ------------------------------------------------------------------------

README = sprintf( [ 'This simulation dataset consists of 9 recordings with 1 phantom head.\n'...
    'the phantom head was on a motion platform which simulated 8 different motions.\n' ...
    'the motions were rest, trans (up & down) at 3 different speeds, roll (left & right) at 3 different speeds, and walking.\n' ...
    'Each motion was performed once, except for walking which was performed twice.\n' ...
    'In each measurement, the head was stimulated with an N1 / P3 complex.\n\n' ...
    '- Melanie Klapprott (Summer 2025)' ]);

% Content for CHANGES file -----------------------------------------------------------------------

CHANGES = sprintf([ 'Revision history for passiveduallayerPhantomHead dataset\n\n' ...
    'version 1.0 beta - Summer 2025\n' ...
    ' - Initial release\n']);


% participant information for participants.tsv file ----------------------------------------------

pInfo = {'participant_id', 'species', 'age'; ...
    '1', 'Phantom Head', 'day 1'};

% session information for sessions.tsv file ------------------------------------------------------

sInfo = {'session_id'; ...
    '1';
    '2';
    '3';
    '4';
    '5';
    '6';
    '7';
    '8';
    '9'};

% Task information for xxxx-eeg.json file --------------------------------------------------------

tInfo.EEGReference = 'FCz';
tInfo.SamplingFrequency = 250;
tInfo.PowerLineFrequency = 50;
tInfo.SoftwareFilters = 'n/a';

tInfo.CapManufacturer = 'Easycap';
tInfo.CapManufacturersModelName = 'custom passive dual layer';
tInfo.AmpManufacturer = 'mbraintrain';
tInfo.AmpManufacturersModelName = 'PRO X';
tInfo.EEGChannelCount = 32;
tInfo.NoiseChannelCount = 32;
tInfo.MISCChannelCount = 10;

tInfo.TaskName = 'ERP simulation';
tInfo.TaskDescription = 'We stimulated a phantom head with a frontal and a parietal input to simulate an N1 / P3 complex';

tInfo.InstitutionName = 'University of Oldenburg';
tInfo.InstitutionalDepartmentName = 'Department of Psychology';


%% actual conversion

target_folder = [MAINPATH, 'BIDS_PhantomHead\'];

eeglab

bids_export(data, ...
    'targetdir', target_folder,...
    'taskName', 'stimulation',...
    'README', README,...
    'CHANGES', CHANGES,...
    'gInfo', generalInfo, ... 
    'tInfo', tInfo, ... 
    'pInfo', pInfo);


%% set up BIDS - Motion

FILES_mo = dir([PATHOUT,filesep, '*.tsv']);
target_folder = [MAINPATH, 'BIDS_PhantomHead\'];

% Information for xxxx-motion.json file ----------------------------------------------------------

cfg = [];

cfg.method = 'convert';
cfg.bidsroot = target_folder;  % write to the present working directory
cfg.sub = '1';

cfg.InstitutionName             = 'University of Oldenburg';
cfg.InstitutionalDepartmentName = 'Department of Psychology';
cfg.InstitutionAddress          = 'Ammerlaender Heerstrasse 114-118, 26129 Oldenburg';

% for dataset_description.json
cfg.dataset_description.Name                = 'ERP simulation';
cfg.dataset_description.BIDSVersion         = 'unofficial extension';
cfg.dataset_description.License             = 'n/a';
cfg.dataset_description.Authors             = 'Melanie Klapprott, Stefan Debener, Daniel Ferris';

cfg.README                  = sprintf( [ 'This simulation dataset consists of 9 recordings with 1 phantom head.\n'...
    'the phantom head was on a motion platform which simulated 8 different motions.\n' ...
    'the motions were rest, trans (up & down) at 3 different speeds, roll (left & right) at 3 different speeds, and walking.\n' ...
    'Each motion was performed once, except for walking which was performed twice.\n' ...
    'In each measurement, the head was stimulated with an N1 / P3 complex.\n\n' ...
    '- Melanie Klapprott (Summer 2025)' ]);
cfg.LICENSE                 = sprintf([ 'Revision history for passiveduallayerPhantomHead dataset\n\n' ...
    'version 1.0 beta - Summer 2025\n' ...
    ' - Initial release\n']);


% these are general fields

cfg.TaskDescription = 'We stimulated a phantom head on a motion platform with a frontal and a parietal input to simulate an N1 / P3 complex';
cfg.task = 'headmovement';

sessions = [1 2 3 4 5 6 7 8 9]; 
% contruct the correct fieldtrip dataset
%--------------------------------------------------------------------------
cfg.datatype    = 'motion';  
cfg.tracksys = 'platform';

cfg.motion.TrackingSystemName          = 'Whatever';
cfg.Manufacturer = 'Fraunhofer IDMT Oldenburg';
cfg.ManufacturersModelName = 'Motion Platform';

% specify channel details, this overrides the details in the original data structure
cfg.channels = [];
cfg.channels.name = {
  'trans'
  'pitch'
  'roll'
  };
cfg.channels.component= {
  'x'
  'y'
  'z'
  };
cfg.channels.type = {
  'ORI'
  'ORI'
  'ORI'
  };
cfg.channels.units = {
  'deg'
  'deg'
  'deg'
  };

cfg.channels.tracked_point = {
  'platform'
  'platform'
  'platform'
  };

% rename the channels in the data to match with channels.tsv
MotionftData.label = cfg.channels.name;

% time synch information in scans.tsv file
time_of_recording = datetime('now'); 
cfg.scans.acq_time  = datestr(time_of_recording, 'yyyy-mm-ddTHH:MM:SS.FFF');


% assign the data
cd(PATHOUT)
data(1).dat = readtable("dualLayer2_1_rest_stim.tsv",  "FileType","text",'Delimiter', '\t');
data(2).dat = readtable("dualLayer2_2_trans_slow_stim.tsv",  "FileType","text",'Delimiter', '\t');
data(3).dat = readtable("dualLayer2_3_trans_mid_stim.tsv",  "FileType","text",'Delimiter', '\t');
data(4).dat = readtable("dualLayer2_4_trans_fast_stim.tsv",  "FileType","text",'Delimiter', '\t');
data(5).dat = readtable("dualLayer2_5_roll_slow_stim.tsv",  "FileType","text",'Delimiter', '\t');
data(6).dat = readtable("dualLayer2_6_roll_mid_stim.tsv",  "FileType","text",'Delimiter', '\t');
data(7).dat = readtable("dualLayer2_7_roll_fast_stim.tsv",  "FileType","text",'Delimiter', '\t');
data(8).dat = readtable("dualLayer2_8_walking_stim1.tsv",  "FileType","text",'Delimiter', '\t');
data(9).dat = readtable("dualLayer2_9_walking_stim2.tsv",  "FileType","text",'Delimiter', '\t');


data_platform = [];
data_platform.label    = data(1).dat.Properties.VariableNames;
for idx = 1:length(FILES_mo)

    data_platform.trial{idx} = table2array(data(idx).dat)';    
    data_platform.time{idx}  = linspace(0, 300, height(data(idx).dat));

end

%% Actual Conversion

for idx = 1:length(FILES_mo)
    cfg.ses = num2str(sessions(idx));
    data2bids(cfg, data_platform);
end


%%

