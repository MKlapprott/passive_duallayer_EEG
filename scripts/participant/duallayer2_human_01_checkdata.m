%% duallayer2_human_01_checkdata.m
%
% Description:
%   This script performs an initial quality check on raw EEG data from
%   participants in the dual-layer project. For each participant, raw XDF
%   files are loaded, channel types are assigned (EEG, Noise, IMU), and 
%   basic preprocessing steps are applied. Problematic datasets are handled
%   with subject-specific adjustments. Bad channels are detected and stored,
%   and diagnostic plots are saved for inspection.
%
% Workflow:
%   - Define input/output paths and create folders for results and plots
%   - Load subject information from participant_info.xlsx
%   - Loop over participants:
%       * Load XDF EEG data (with subject-specific handling if needed)
%       * Assign channel types (EEG, Noise, MISC)
%       * Apply high-pass and low-pass filters
%       * Reject bad channels (automatic + manual overrides)
%       * Store subject-level metadata (ID, condition order, rejected channels)
%       * Save preprocessed dataset and channel RMS plots
%   - Remove empty entries from SUB structure
%   - Save subject information (SUB struct) to disk
%
% Inputs:
%   - Raw EEG files (.xdf) in PATHIN
%   - participant_info.xlsx with subject IDs and condition orders
%   - check.mat with preprocessing parameters:
%         * HPF1 : high-pass cutoff
%         * LPF  : low-pass cutoff
%         * std_threshold : bad-channel rejection threshold
%         * cleaningMethod / autoChRejMethod : cleaning settings
%
% Outputs:
%   - Preprocessed datasets per subject saved in CHECKPATH
%   - Diagnostic channel RMS plots saved in CHECKPLOTS
%   - SUB struct containing subject metadata and rejection info
%
% Dependencies:
%   - EEGLAB (for loading and preprocessing)
%   - autoRejCh_func_CL (custom function for channel rejection)
%   - my_badchannels (custom function for channel RMS plots)
%
%
% Author: Melanie, 2025


%% Preparations


close all; clear all; clc;                                                                          % start with fresh workspace

% set paths
MAINPATH = 'R:\Ferris-Lab\mklapprott\eegl\';                                                        % adjust this path to your local environment!!!
cd(MAINPATH)

PATHIN = [MAINPATH, 'rawdata\participants\'];                                                       % path to raw data (changed from task-Flanker!!!)
PATHOUT = [MAINPATH, 'derivatives\participants\']; 

CHECKPATH = [PATHOUT, 'duallayer2_human_01_first-Check\'];
if ~isfolder(CHECKPATH)                                                                             % if the path doesn't exist yet, create it
    mkdir(CHECKPATH)
end

CHECKPLOTS = [CHECKPATH, 'plots\'];
if ~isfolder(CHECKPLOTS)                                                                            % if the path doesn't exist yet, create it
    mkdir(CHECKPLOTS)
end

file_paths = dir(fullfile(PATHIN));                                                                 % get access to all folder names
file_paths = file_paths(contains({file_paths.name}, '_'));


subs_info = readtable([MAINPATH, 'participant_info.xlsx']);
subs = table2cell(subs_info(:,1));                                                                  % extract subject names
conds = table2cell(subs_info(:,5:9));                                                               % extract conditions
load('check.mat'); 
load('SUBS.mat');

%% Start data check


for sub = 14%:length(file_paths)

    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;                                                        % start EEGLAB

    % start by sorting out some special snowflakes -----------------------------------------------

    if strcmp(file_paths(sub).name, 'sub_03')
        
        PATHINSUB = [PATHIN, file_paths(sub).name, '\'];
        cd(PATHINSUB)
        
        files = dir(fullfile(PATHINSUB, '*.xdf'));                                                  % get access to data sets - EEG

        for file = 1:length(files)
            file_name = files(file).name;
        
            EEG = pop_loadxdf([PATHINSUB, file_name], 'streamtype', 'EEG', 'exclude_markerstreams', {}); % load data
            EEG = pop_chanedit(EEG, 'lookup',[MAINPATH, 'DualLayer64.elp'], 'filetype', 'besa');
            [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG);                                    % store data set
        end
        
        EEG = pop_mergeset( ALLEEG, [3  2  1], 0); 
    else

        PATHINSUB = [PATHIN, file_paths(sub).name, '\'];
        cd(PATHINSUB)

        files = dir(fullfile(PATHINSUB, '*.xdf'));                                                  % get access to data sets - EEG
        file_name = files.name;
    
        EEG = pop_loadxdf([PATHINSUB, file_name], 'streamtype', 'EEG', 'exclude_markerstreams', {}); % load data
        EEG = pop_chanedit(EEG, 'lookup',[MAINPATH, 'DualLayer64.elp'], 'filetype', 'besa');
        EEG.setname = strjoin(['dualLayer2_', num2str(sub), '_', subs_info{sub, 'ID'}],'');         % give data set a name

    end                                                                                             % end sorting out subjetcs
 
    EEG.data = double(EEG.data);

    SUB(sub).ID = file_paths(sub).name;
    SUB(sub).conds_order1 = conds{sub, 1};
    SUB(sub).conds_order2 = conds{sub, 2};
    SUB(sub).conds_order3 = conds{sub, 3};
    SUB(sub).conds_order4 = conds{sub, 4};
    SUB(sub).conds_order5 = conds{sub, 5};


    % prepare data & start quality check ---------------------------------------------------------

    [EEG.chanlocs(find(contains({EEG.chanlocs.labels}, 'R'))).type] = deal('Noise');                % assign the Noise label to the Noise electrodes
    [EEG.chanlocs(find(~contains({EEG.chanlocs.labels}, 'R'))).type] = deal('EEG');                 % assign the Noise label to the Noise electrodes
    [EEG.chanlocs(find(contains({EEG.chanlocs.labels}, 'Acc'))).type] = deal('MISC');               % assign the MISC label to the IMU channels
    [EEG.chanlocs(find(contains({EEG.chanlocs.labels}, 'Gyro'))).type] = deal('MISC');              % assign the MISC label to the IMU channels
    [EEG.chanlocs(find(contains({EEG.chanlocs.labels}, 'Quat'))).type] = deal('MISC');              % assign the MISC label to the IMU channels

    EEG = pop_eegfiltnew(EEG, 'locutoff', check.HPF1);                                              % initial high-pass filter
    EEG = pop_eegfiltnew(EEG, 'hicutoff', check.LPF);                                               % low-pass filter

    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);                                             % store data set


    EEG.urchanlocs = EEG.chanlocs(1:32);                                                            % save scalp chanlocs for later

    % channel rejection 
    my_badchannels(EEG, subs_info, sub)                                                             % illustrate channels RMS
    
    if strcmp(SUB(sub).ID, 'sub_13')
        badEEGch = [find(strcmp({EEG.chanlocs.labels}, 'FT9')), find(strcmp({EEG.chanlocs.labels}, 'FT10')), ...
            find(strcmp({EEG.chanlocs.labels}, 'TP9')), find(strcmp({EEG.chanlocs.labels}, 'TP10')), ...
            find(strcmp({EEG.chanlocs.labels}, 'Fp1R'))];
        Total_rej_1 = [find(strcmp({EEG.chanlocs.labels}, 'FT9')), find(strcmp({EEG.chanlocs.labels}, 'FT10')), ...
            find(strcmp({EEG.chanlocs.labels}, 'TP9')), find(strcmp({EEG.chanlocs.labels}, 'TP10'))];
        badNoiseCh = find(strcmp({EEG.chanlocs.labels}, 'Fp1R'));
        EEG = pop_select( EEG,'nochannel', sort(badEEGch));
    else
        [EEG, Total_rej_1, badEEGch, badNoiseCh] = autoRejCh_func_CL(EEG,check.std_threshold);          % Reject bad channels
    end

    if strcmp(SUB(sub).ID, 'pilot_04') || strcmp(SUB(sub).ID, 'sub_05') || strcmp(SUB(sub).ID, 'sub_07') ...
            || strcmp(SUB(sub).ID, 'sub_10') || strcmp(SUB(sub).ID, 'sub_11') || strcmp(SUB(sub).ID, 'sub_12') % here, C4 is a flat channel
        badEEGch = find(strcmp({EEG.chanlocs.labels}, 'C4'));
        EEG = pop_select( EEG,'nochannel', badEEGch);
    end
    
    cleaningMethod = horzcat(check.cleaningMethod,check.autoChRejMethod);                           % define cleaning method

    EEG_chans = find(strcmpi('EEG',{EEG.chanlocs.type}));                                           % redefine scalp channels
    Noise_chans = find(strcmpi('Noise',{EEG.chanlocs.type}));                                       % redefine noise channels

    EEG.badchans = sort(badEEGch);

    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);                                             % store data set
    
    SUB(sub).rej_chans = Total_rej_1;                                                               % save number rejected channels
    SUB(sub).rej_EEGchans = sort(badEEGch);                                                         % rejected channels
    SUB(sub).rej_Noisechans = badNoiseCh;                                                           % rejected channels
    SUB(sub).rej_chans_expl = 'EEG, EMG, Noise chans';
        
    % save data set & Figure            
    SUBCHECKPATH = [CHECKPATH, file_paths(sub).name, '\'];                                          % create path for subject
    
    if ~isfolder(SUBCHECKPATH)
        mkdir(SUBCHECKPATH);
    end

    cd(SUBCHECKPATH);
    EEG = pop_saveset(EEG, 'filename', [EEG.setname, '_preproc-firstCheck_eeg'], 'filepath', SUBCHECKPATH);    % save data set
    cd(CHECKPLOTS);
    saveas(gca, [num2str(sub), '_', file_paths(sub).name, '-ChanRMS.png']);                         % save plot
    close;

end                                                                                                 % end loop over subjects

%%
fun = @(s) all(structfun(@isempty, s));
idx = arrayfun(fun, SUB);
SUB(idx) = [];

save([MAINPATH,'SUBS'],'SUB');                                                                      % save information

%% end
