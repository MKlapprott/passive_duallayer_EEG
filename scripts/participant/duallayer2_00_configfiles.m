%% duallayer2_00_config.m
%
% set up some parameters here, so that the scripts later will be less messy.
%
%
% Author: Melanie, Summer 2025

clear all; close all; clc

MAINPATH = 'Q:\Neuro\data\projects\all_gait\dual-layerCap\dual-layer-2024_25\eegl\';                                                        % path where all the config files should be saved
cd(MAINPATH)

%% parameters for initial check of the data

check.HPF = 0.3;                                                                                    % ERP cut-off for high-pass filter
check.HPF1 = 1;                                                                                     % initial cut-off for high-pass filter (participants only)
check.LPF = 30;                                                                                     % cut-off for low-pass filter
check.std_threshold = 3;                                                                            % cut-off for bad channel detection
check.autoChRejMethod = [num2str(check.std_threshold),'std'];                                       % how many stds as a criterion
check.cleaningMethod = '';                                                                          % pre-allocate cleaning method
check.NOCHANS = {'AccX','AccY','AccZ','GyroX','GyroY','GyroZ', 'QuatW','QuatX','QuatY','QuatZ'};    % channels to be ignored (xdf style)

save('check.mat', 'check');


%% parameters for iCanClean algorithm

params.windowLength = 4;                                                                            % Duration (s) of the sliding window to be cleaned
params.statsWindow = 4;                                                                             % Duration (s) of the window used to compute CCA stats
params.cleanWindow = 4;                                                                             % Duration (s) of the data cleaned per step
params.rhoSqThres_source = 0.9;                                                                    % components above this R^2 are removed
params.cleanXwith = 'Y';                                                                            % Clean EEG (X) using reference data (Y)
params.cleanYwith = 'no';                                                                           % Clean reference (Y) using reference data (Y)
params.giveCleaningUpdates = 1;                                                                     % Print cleaning status to console
params.plotStatsOn = 0;                                                                             % Plot VAF and correlation stats during cleaning
params.useBoundary = 0;                                                                             % Ignore 'boundary' events in data process through them)
params.stepSize = 1;                                                                                % Step size (s) between cleaning iterations
params.extraTime_pre = 0;                                                                           % Extra time added before cleaning window to match statsWindow length
params.extraTime_post = 0;                                                                          % Extra time added after cleaning window

params.rerefX = 'no';                                                                               % don't re-reference X (EEG data)
params.filtX = 'no';                                                                                % no filter on X
params.filtXtype = 'no';                                                                            % no filter on X
params.filtXfreq = [];                                                                              % Frequency range for filtering X
params.rerefY = 'no';                                                                               % don't re-reference Y (reference data)
params.filtY = 'no';                                                                                % no filter on X
params.filtYtype = 'no';                                                                            % no filter on Y
params.filtYfreq = [];                                                                              % Frequency range for filtering Y
params.calcCCAonWholeData = 0;                                                                      % perform CCA in sliding windows (adaptive cleaning)
params.useExternCalibData = 0;                                                                      % don't use external calibration dataset for noise model
params.indExternCalibData = 1;                                                                      % Index of cal. dataset ignored if useExternCalibData = 0
params.RTBool = 0;                                                                                  % offline processing
params.visualizeResults = 0;                                                                        % don't show GUI visualization of results
params.plotVAF = 0;                                                                                 % don't plot Variance Accounted For (VAF) maps

save('params.mat', 'params');


%% parameters for dipfit

df.gridA = [-85,-77.6087,-70.2174,-62.8261,-55.4348,-48.0435,-40.6522,-33.2609,-25.8696, ...
    -18.4783,-11.087,-3.69565,3.69565,11.087,18.4783,25.8696,33.2609,40.6522,48.0435, ...
    55.4348,62.8261,70.2174,77.6087,85];
df.gridB = [-85,-77.6087,-70.2174,-62.8261,-55.4348,-48.0435,-40.6522,-33.2609,-25.8696, ...
    -18.4783,-11.087,-3.69565,3.69565,11.087,18.4783,25.8696,33.2609,40.6522,48.0435, ...
    55.4348,62.8261,70.2174,77.6087,85];
df.gridC = [0,7.72727,15.4545,23.1818,30.9091,38.6364,46.3636,54.0909,61.8182,69.5455,77.2727,85];

save('df_params.mat', 'df');

%% parameters for epoching & erp calculation

erp.REJ = 5;                                                                                        % threshold for epoch rejection
erp.FROM = -0.2;                                                                                    % epoch start (s)
erp.TO = 0.8;                                                                                       % epoch end (s)
erp.N1_st = 80;                                                                                    % start of N1 window
erp.N1_sp = 150;                                                                                    % end of N1 window
erp.P3_st_gerd = 200;                                                                               % start of P3 window
erp.P3_sp_gerd = 400;                                                                               % end of P3 window
erp.P3_st = 300;                                                                                    % start of P3 window
erp.P3_sp = 600;                                                                                    % end of P3 window

erp.gerd_events = {'resting_stim', 'UpDown_slow', 'UpDown_mid', 'UpDown_fast', ...
    'LeftRight_slow', 'LeftRight_mid', 'LeftRight_fast', 'walking_stim', 'walking_stim'};

erp.rec_conds = {'Rest', 'Trans (Slow)', 'Trans (Mid)', 'Trans (Fast)', 'Roll (Slow)', 'Roll (Mid)', ...
    'Roll (Fast)', 'Walking 1', 'Walking 2'};
erp.rec_conds_save = {'01_Rest', '02_Trans_Slow', '03_Trans_Mid', '04_Trans_Fast', '05_Roll_Slow', '06_Roll_Mid', ...
    '07_Roll_Fast', '08_Walking_1', '09_Walking_2'};

erp.sum_conds = {'rest', 'slow', 'mid', 'fast', 'walk'};

erp.EVENTS = {'sta', 'tar'};
erp.events_save = {'standard', 'target'};
erp.runs = [1,2,4,5,1,2,4,5];


save('erp.mat', 'erp');

