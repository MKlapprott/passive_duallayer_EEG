%% duallayer2_gerd_02_checkdata.m
%
% Description:
%   This script loads phantom head EEG datasets with added noise and performs 
%   initial preprocessing and quality checks. The workflow applies filtering, 
%   re-referencing, and automatic channel rejection, while also storing metadata 
%   about rejected channels for each measurement and noise condition.
%
% Workflow:
%   - Define input/output paths and load measurement info
%   - Loop across measurement sessions and noise conditions
%   - Apply filtering (high-pass and low-pass)
%   - Identify and reject bad channels (automated + visual check)
%   - Save preprocessed EEG datasets and diagnostic plots
%   - Collect summary information in a MEASUREMENTS structure
%
% Inputs:
%   - EEG .set files located in PATHIN (phantom head with simulated noise)
%   - 'measurement_info.xlsx' containing metadata
%   - 'check.mat' containing preprocessing parameters:
%         * check.HPF, check.LPF        : filter cutoffs
%         * check.NOCHANS               : channels to exclude
%         * check.std_threshold         : threshold for auto channel rejection
%         * check.noise_conds           : noise condition labels
%   - Functions:
%         * my_badchannels()            : custom function to illustrate bad channels
%         * autoRejCh_func_CL()         : custom function for automatic channel rejection
%
% Outputs:
%   - Preprocessed EEG datasets (.set) stored in CHECKPATH
%   - Diagnostic plots (channel RMS, etc.) stored in CHECKPLOTS
%   - MEASUREMENTS.mat containing metadata on channel rejections
%
% Dependencies:
%   - EEGLAB (for EEG preprocessing and data management)
%   - Custom functions: my_badchannels, autoRejCh_func_CL
%
% Author: Melanie, 2025

%% Preparations

close all; clear all; clc;                                                                          % start with fresh workspace

% set paths

MAINPATH = 'Q:\Neuro\data\projects\all_gait\dual-layerCap\dual-layer-2024_25\eegl\';               % adjust this path to your local environment!!!
cd(MAINPATH)

PATHIN = [MAINPATH, 'derivatives\gerd\duallayer2_gerd_00_Noise\'];                                  % path to noise data
PATHOUT = [MAINPATH, 'derivatives\gerd\']; 

CHECKPATH = [PATHOUT, 'duallayer2_gerd_01_first-Check\'];
if ~isfolder(CHECKPATH)                                                                             % if the path doesn't exist yet, create it
    mkdir(CHECKPATH)
end

CHECKPLOTS = [CHECKPATH, 'plots\'];
if ~isfolder(CHECKPLOTS)                                                                            % if the path doesn't exist yet, create it
    mkdir(CHECKPLOTS)
end

file_paths = dir(fullfile(PATHIN));                                                                 % get access to all folder names
file_paths = file_paths(3:11, :);

% load parameters

measurement_info = readtable([MAINPATH, 'measurement_info.xlsx']);                                  % load initial info table
measurement_info = measurement_info(9:end, :);
load('check.mat');


%% start data check

for meas = 1:length(file_paths)

    PATHINSUB = [PATHIN, strjoin([num2str(meas), '_', measurement_info{meas, 'cond'}],''), '\'];
    cd(PATHINSUB)

    MEASUREMENTS(meas).ID = file_paths(meas).name;                                                  % collect initial information & store them in structure
       

    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;                                                 % start EEGLAB

    % load data ------------------------------------------------------------------------------

    files = dir(fullfile(PATHINSUB, '*.set'));                                                  % get access to data sets
    file_name = files.name;

    EEG = pop_loadset([PATHINSUB, file_name]);                                                  % load data
    EEG.setname = strjoin(['dualLayer2_', num2str(meas), '_', measurement_info{meas, 'cond'}],''); % give data set a name

    EEG = pop_select( EEG, 'nochannel', check.NOCHANS);                                         % select relevant channels
    nchan = EEG.nbchan;                                                                         % update number of channels   

    EEG.setname = strjoin(['dualLayer2_', num2str(meas), '_', measurement_info{meas, 'cond'}],''); 


    EEG = pop_eegfiltnew(EEG, 'locutoff', check.HPF);                                           % use HPF to remove drift
    EEG = pop_eegfiltnew(EEG, 'hicutoff', check.LPF);                                           % use HPF to smoothe data

    EEG_chans = find(strcmpi('EEG',{EEG.chanlocs.type}));                                       % redefine scalp channels
    Noise_chans = find(strcmpi('Noise',{EEG.chanlocs.type}));                                   % redefine noise channels

    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );                                    % store in ALLEEG
    EEG.urchanlocs = EEG.chanlocs(1:length(EEG_chans));                                               % save original chanlocs for later

    

    % channel rejection ----------------------------------------------------------------------

    my_badchannels(EEG, measurement_info, meas)                                                 % illustrate bad channels
    [EEG, Total_rej_1] = autoRejCh_func_CL(EEG,check.std_threshold, Noise_chans);                            % Reject bad channels, 1st iteration
       
    cleaningMethod = horzcat(check.cleaningMethod,check.autoChRejMethod);                       % define cleaning method

    
    MEASUREMENTS(meas).rej_chans = [Total_rej_1];                                               % save number rejected channels
    MEASUREMENTS(meas).rej_chans_expl = 'EEG, Noise chans';

    EEG = rerefC2CN2NExt2Ext_func(EEG,1);
        
    % save data set & Figure            
    SUBCHECKPATH = [CHECKPATH, file_paths(meas).name, '\'];                                     % create path for subject
    
    if ~isfolder(SUBCHECKPATH)
        mkdir(SUBCHECKPATH);
    end

    cd(SUBCHECKPATH);
    EEG = pop_saveset(EEG, 'filename', [EEG.setname, '_preproc-firstCheck_eeg'], 'filepath', SUBCHECKPATH);    % save data set
    cd(CHECKPLOTS);
    exportgraphics(gca, [file_paths(meas).name,  '-ChanRMS.png']);     % save plot
    close;
        
end                                                                                                 % end loop across measurements


save([MAINPATH,'MEAS'],'MEASUREMENTS');                                                             % save information

%% end


