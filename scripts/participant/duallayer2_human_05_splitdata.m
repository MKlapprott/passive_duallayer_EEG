%% duallayer2_human_05_splitdata.m
%
% Description:
%   This script re-processes participant EEG data by re-applying iCanClean (ICC) 
%   and ICA weights from previously identified bad components. After cleaning 
%   and correcting the data, it splits continuous EEG recordings into task-specific 
%   segments for downstream analyses.
%
% Workflow:
%   - Load ICA datasets with bad components for each participant
%   - Re-load raw EEG data from XDF files
%   - Apply preprocessing:
%       * Channel type assignment (EEG, Noise, MISC)
%       * High-pass filtering
%       * Bad channel removal and interpolation
%   - Apply iCanClean (ICC) optionally and remove bad ICs
%   - Apply ICA weights from reference dataset
%   - Remove bad ICs and interpolate bad channels
%   - Save cleaned and ICA-corrected datasets
%   - Split datasets into individual task runs according to event triggers
%   - Save split datasets for both ICC and no-ICC conditions
%
% Inputs:
%   - Raw EEG XDF files (participants folder)
%   - ICA datasets and bad ICs from previous scripts
%   - SUBS.mat containing participant info and previously identified bad channels/ICs
%
% Outputs:
%   - *_ICC-ICAcorr.set and *_trad-ICAcorr.set (cleaned, ICA-corrected data)
%   - Split EEG datasets per run and condition for each participant
%
% Dependencies:
%   - EEGLAB with iCanClean
%   - SUBS.mat, check.mat, params.mat
%
%
% Author: Melanie, 2025

%% Preparations

clear all; close all; clc;

MAINPATH = 'Q:\Neuro\data\projects\all_gait\dual-layerCap\dual-layer-2024_25\eegl\';                                                        % adjust this path to your local environment!!!
PATHIN = [MAINPATH, 'rawdata\participants\'];
PATHOUT = [MAINPATH, 'derivatives\participants\'];
ICAPATH = [PATHOUT, 'duallayer2_human_03_iCA\'];                                                    % path for ICA data 

ICCPATH = [PATHOUT, 'duallayer2_human_04_iCC_ICA-corr\'];                                           % path for ICC & ICA corrected data data 

if ~isfolder(ICCPATH)                                                                               % if the path doesn't exist yet, create it
    mkdir(ICCPATH)
end

SPLITPATH = [PATHOUT, 'duallayer2_human_05_splitdata\'];                                            % path for ICA data 

if ~isfolder(SPLITPATH)                                                                             % if the path doesn't exist yet, create it
    mkdir(SPLITPATH)
end

cd(MAINPATH)
subs_info = readtable([MAINPATH, 'participant_info_ana.xlsx']);
conds = table2cell(subs_info(:,5:9));                                                               % extract conditions
load('check.mat');
load('params.mat');
load('SUBS.mat');


%% Start loading & re-running iCanClean + applying ICA weights


for sub = 1:length(SUB)

    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;                                                     % start EEGLAB

    SUBICAPATH = [ICAPATH, SUB(sub).ID, '\badICs\'];                                                % go to ICA path
    cd(SUBICAPATH)
    ica_files = dir( fullfile( SUBICAPATH,'\*.set'));                                               % listing data sets
    
    for idx = 1:2
        EEG = pop_loadset([SUBICAPATH, ica_files(idx).name]);                                       % load files with ICA weights & bad components
        [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);                                         % store data set
    end


    SUBPATH = [PATHIN, SUB(sub).ID, '\'];                                                           % go to raw data path for re-processing data
    cd(SUBPATH)
    cur_file = dir( fullfile( SUBPATH,'\*.xdf'));                                                   % listing data sets
    
    SUBICCPATH = [ICCPATH, SUB(sub).ID, '\'];                                                       % create path subject iCC+ICA
    
    if ~isfolder(SUBICCPATH)
        mkdir(SUBICCPATH)
    end

    do_iCC = [true, false];                                                                         % one line with and one line without iCanClean

    for idx = 1:length(do_iCC)                                                                      % loop across the two processing lines
        
        if do_iCC(idx)

            % data preparation -------------------------------------------------------------------

            if strcmp(SUB(sub).ID, 'sub_03')
        
                for file = 1:length(cur_file)
                    file_name = cur_file(file).name;
                
                    EEG = pop_loadxdf([SUBPATH, file_name], 'streamtype', 'EEG', 'exclude_markerstreams', {});    % load data
                    EEG = pop_chanedit(EEG, 'lookup',[MAINPATH, 'DualLayer64.elp']);
                    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG);                                        % store data set
                end
                
                EEG = pop_mergeset( ALLEEG, [5  4  3], 0); 
            else
            
                EEG = pop_loadxdf([SUBPATH, cur_file.name]);                                            % load
                EEG = pop_chanedit(EEG, 'lookup',[MAINPATH, 'DualLayer64.elp']);                        % add channel locations
                EEG.setname = ['dualLayer2_', num2str(sub), '_', SUB(sub).ID];                      % give data set a name
            end
        
            [EEG.chanlocs(find(contains({EEG.chanlocs.labels}, 'R'))).type] = deal('Noise');        % assign the Noise label to the Noise electrodes
            [EEG.chanlocs(find(~contains({EEG.chanlocs.labels}, 'R'))).type] = deal('EEG');         % assign the EEG label to the EEG electrodes
            [EEG.chanlocs(find(contains({EEG.chanlocs.labels}, 'Acc'))).type] = deal('MISC');       % assign the MISC label to the IMU channels
            [EEG.chanlocs(find(contains({EEG.chanlocs.labels}, 'Gyro'))).type] = deal('MISC');      % assign the MISC label to the IMU channels
            [EEG.chanlocs(find(contains({EEG.chanlocs.labels}, 'Quat'))).type] = deal('MISC');      % assign the MISC label to the IMU channels

            all_starts = find(strcmp({EEG.event.type}, '1 instruction'));
            all_ends = find(strcmp({EEG.event.type}, '5 end_block'));
        
            EEG = pop_eegfiltnew(EEG, 'locutoff', check.HPF);                                       % high-pass filter
            EEG = pop_eegfiltnew(EEG, 'hicutoff', 30);                                              % low-pass filter

            EEG.urchanlocs = EEG.chanlocs(1:32);                                                    % save scalp chanlocs for later
        
            [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);                                     % store data set
        
            rej_chans = [SUB(sub).rej_EEGchans', SUB(sub).rej_Noisechans];
            EEG.badchans = SUB(sub).rej_EEGchans;

            % if strcmp(SUB(sub).ID, 'sub_05')
            %     rej_chans = [find(strcmp({EEG.chanlocs.labels}, 'C4')), find(strcmp({EEG.chanlocs.labels}, 'F8')), ...
            %         find(strcmp({EEG.chanlocs.labels}, 'FT10'))];
            % elseif strcmp(SUB(sub).ID, 'sub_10')
            %     rej_chans = [find(strcmp({EEG.chanlocs.labels}, 'C4')), find(strcmp({EEG.chanlocs.labels}, 'F7')), ...
            %         find(strcmp({EEG.chanlocs.labels}, 'F8'))];
            % end

            EEG = pop_select(EEG, 'nochannel', sort(rej_chans));

            EEG = rerefC2CN2NExt2Ext_func(EEG,1);                                                           % re-reference

             % ICC -------------------------------------------------------------------------------
            
            fprintf('==== %s STARTING: ICANCLEAN ====\n',EEG.setname);
            EEG_chans = find(strcmpi('EEG',{EEG.chanlocs.type}));                                   % get EEG channel indices
            Noise_chans = find(strcmpi('Noise',{EEG.chanlocs.type}));                               % get Noise channel indices          
            
            EEG = iCanClean(EEG, EEG_chans, Noise_chans, 0, params);                                % perform iCanClean

            % apply ICA weights ------------------------------------------------------------------

            go_chans = EEG.chanlocs(strcmp({EEG.chanlocs.type},'EEG'));                             % mark EEG channels
            go_labels = {go_chans.labels};       
            EEG = pop_select( EEG, 'channel',go_labels);                                            % only keep EEG channels
            [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);                                     % store data set

            EEG = pop_editset(EEG, 'run', [], 'icaweights', 'ALLEEG(1).icaweights', 'icasphere', 'ALLEEG(1).icasphere'); % apply weights from ALLEEG(1) on this data set
            EEG.setname = [EEG.setname, '_ICC-ICAweights'];
            [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
        
            % remove bad components --------------------------------------------------------------

            EEG.badics = ALLEEG(1).badics;                                                          % get bad ICs
            
            if ~isempty(EEG.badics)                                                                 % if bad ICs, remove them from data
                EEG = pop_subcomp( EEG,EEG.badics, 0, 0);
                disp(['Removing components: ', mat2str(EEG.badics)])
            end
    
            try
                if ~isempty(EEG.badchans)                                                           % if there are bad channels...   
                    EEG = pop_interp(EEG, EEG.urchanlocs , 'spherical');                            % and interpolate them using urchanlocs        
                end
            end
 
            % save data set ----------------------------------------------------------------------

            cd(SUBICCPATH);
            EEG = pop_saveset(EEG, 'filename', ['dualLayer2_', num2str(sub), '_', SUB(sub).ID, '_ICC-ICAcorr'], 'filepath', SUBICCPATH); % save data set

        else                                                                                        % repeat the procedure without iCanClean
            
            fprintf('==== %s NO ICANCLEAN ====\n',EEG.setname);
            
            % data preparation -------------------------------------------------------------------
            
            if strcmp(SUB(sub).ID, 'sub_03')
        
                for file = 1:length(cur_file)
                    file_name = cur_file(file).name;
                
                    EEG = pop_loadxdf([SUBPATH, file_name], 'streamtype', 'EEG', 'exclude_markerstreams', {});    % load data
                    EEG = pop_chanedit(EEG, 'lookup',[MAINPATH, 'DualLayer64.elp']);
                    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG);                                        % store data set
                end
                
                EEG = pop_mergeset( ALLEEG, [11  10  9], 0); 
            else
            
                EEG = pop_loadxdf([SUBPATH, cur_file.name]);                                        % load
                EEG = pop_chanedit(EEG, 'lookup',[MAINPATH, 'DualLayer64.elp']);                    % add channel locations
                EEG.setname = ['dualLayer2_', num2str(sub), '_', SUB(sub).ID];                      % give data set a name
            end
        
        
            [EEG.chanlocs(find(contains({EEG.chanlocs.labels}, 'R'))).type] = deal('Noise');        % assign the Noise label to the Noise electrodes
            [EEG.chanlocs(find(~contains({EEG.chanlocs.labels}, 'R'))).type] = deal('EEG');         % assign the EEG label to the EEG electrodes
            [EEG.chanlocs(find(contains({EEG.chanlocs.labels}, 'Acc'))).type] = deal('MISC');       % assign the MISC label to the IMU channels
            [EEG.chanlocs(find(contains({EEG.chanlocs.labels}, 'Gyro'))).type] = deal('MISC');      % assign the MISC label to the IMU channels
            [EEG.chanlocs(find(contains({EEG.chanlocs.labels}, 'Quat'))).type] = deal('MISC');      % assign the MISC label to the IMU channels

            all_starts = find(strcmp({EEG.event.type}, '1 instruction'));
            all_ends = find(strcmp({EEG.event.type}, '5 end_block'));
        
            EEG = pop_eegfiltnew(EEG, 'locutoff', check.HPF);                                       % high-pass filter
            EEG = pop_eegfiltnew(EEG, 'hicutoff', 30);                                              % low-pass filter


            EEG.urchanlocs = EEG.chanlocs(1:32);                                                    % save scalp chanlocs for later
        
            [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);                                     % store data set
        
            rej_chans = [SUB(sub).rej_EEGchans', SUB(sub).rej_Noisechans];
            EEG.badchans = SUB(sub).rej_EEGchans;

            % if strcmp(SUB(sub).ID, 'sub_05')
            %     rej_chans = [find(strcmp({EEG.chanlocs.labels}, 'C4')), find(strcmp({EEG.chanlocs.labels}, 'F8')), ...
            %         find(strcmp({EEG.chanlocs.labels}, 'FT10'))];
            % elseif strcmp(SUB(sub).ID, 'sub_10')
            %     rej_chans = [find(strcmp({EEG.chanlocs.labels}, 'C4')), find(strcmp({EEG.chanlocs.labels}, 'F7')), ...
            %         find(strcmp({EEG.chanlocs.labels}, 'F8'))];
            % end


            EEG = pop_select(EEG, 'nochannel', sort(rej_chans));

            % NO ICC -----------------------------------------------------------------------------
            % apply ICA weights ------------------------------------------------------------------

            go_chans = EEG.chanlocs(strcmp({EEG.chanlocs.type},'EEG'));                             % mark EEG channels
            go_labels = {go_chans.labels};       
            EEG = pop_select( EEG, 'channel',go_labels);                                            % only keep EEG channels
            [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);                                     % store data set

            EEG = pop_editset(EEG, 'run', [], 'icaweights', 'ALLEEG(2).icaweights', 'icasphere', 'ALLEEG(2).icasphere'); % apply weights from ALLEEG(1) on this data set
            EEG.setname = [EEG.setname, '_trad-ICAweights'];
            [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
        
            % remove bad components --------------------------------------------------------------
            
            EEG.badics = ALLEEG(2).badics;                                                          % get bad ICs
            
            if ~isempty(EEG.badics)                                                                 % if bad ICs, remove them from data
                EEG = pop_subcomp( EEG,EEG.badics, 0, 0);
                disp(['Removing components: ', mat2str(EEG.badics)])
            end
    
            try
                if ~isempty(EEG.badchans)                                                           % if there are bad channels...   
                    EEG = pop_interp(EEG, EEG.urchanlocs , 'spherical');                            % and interpolate them using urchanlocs        
                end
            end
 
            EEG.setname = ['dualLayer2_', num2str(sub), '_', SUB(sub).ID, '_trad-ICAcorr'];
            [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);

            cd(SUBICCPATH);
            EEG = pop_saveset(EEG, 'filename', EEG.setname, 'filepath', SUBICCPATH);                % save data set
            
        end                                                                                         % end if-else deciding about preproc option
    end                                                                                             % end loop across preproc options

end

% split data 
% load ICA cleaned no ICC and ICC and split the data from there

for sub = 1:length(SUB)

    if strcmp(SUB(sub).ID, 'sub_03')
        disp('skipping this mess...')
    else

        SUBICCPATH = [ICCPATH, SUB(sub).ID, '\'];
        cd(SUBICCPATH)                                                                                  % set filepath
        files = dir(fullfile(SUBICCPATH, '*.set'));                                                     % get access to data sets
    
        for file = 1:length(files)
    
            [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;                                                    % start EEGLAB
    
            file_name = files(file).name;                                                               % get current file name
            EEG = pop_loadset('filename',file_name,'filepath',SUBICCPATH);
            EEG = pop_eegfiltnew(EEG, 'hicutoff', check.LPF);                                           % low-pass filter
            [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);                                         % store data set
    
    
            % start sorting  data --------------------------------------------------------------------
            
            all_starts = find(strcmp({EEG.event.type}, '1 instruction'));                               % all start triggers
            all_ends = find(strcmp({EEG.event.type}, '5 end_block'));                                   % all end triggers
        
            SUBSPLITPATH = [SPLITPATH, SUB(sub).ID, '\'];
            if ~isfolder(SUBSPLITPATH)                                                                  % if the path doesn't exist yet, create it
                mkdir(SUBSPLITPATH)
            end
            cd(SUBSPLITPATH)
    
            if contains(file_name, 'trad')
                cond = 'trad';
            elseif contains(file_name, 'ICC')
                cond = 'ICC';
            end
        
            % sort single task oddball & dual task conditions ----------------------------------------
        
            EEG = pop_select( ALLEEG(1), 'point',[ALLEEG(1).event(all_starts(2)).latency-10 ALLEEG(1).event(all_ends(2)).latency+10] ); % cond 1
            [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname', ...
                ['dualLayer2_', num2str(sub), '_', SUB(sub).ID, '_', cond, '-ICAcorr_run-1_cond-', conds{sub, 1}'], 'gui','off'); 
            EEG = pop_saveset(EEG, 'filename', EEG.setname, 'filepath', SUBSPLITPATH); 
        
            EEG = pop_select( ALLEEG(1), 'point',[ALLEEG(1).event(all_starts(3)).latency-10 ALLEEG(1).event(all_ends(3)).latency+10] ); % cond 2
            [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname', ...
                ['dualLayer2_', num2str(sub), '_', SUB(sub).ID, '_', cond, '-ICAcorr_run-2_cond-', conds{sub, 2}'], 'gui','off');  
            EEG = pop_saveset(EEG, 'filename', EEG.setname, 'filepath', SUBSPLITPATH)
        
            EEG = pop_select( ALLEEG(1), 'point',[ALLEEG(1).event(all_starts(4)).latency-10 ALLEEG(1).event(all_ends(4)).latency+10] ); % cond 4
            [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname', ...
                ['dualLayer2_', num2str(sub), '_', SUB(sub).ID, '_', cond, '-ICAcorr_run-4_cond-', conds{sub, 4}'], 'gui','off'); 
            EEG = pop_saveset(EEG, 'filename', EEG.setname, 'filepath', SUBSPLITPATH); 
    
            EEG = pop_select( ALLEEG(1), 'point',[ALLEEG(1).event(all_starts(5)).latency-10 ALLEEG(1).event(all_ends(5)).latency+10] ); % cond 5
            [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname', ...
                ['dualLayer2_', num2str(sub), '_', SUB(sub).ID, '_', cond, '-ICAcorr_run-5_cond-', conds{sub, 5}'], 'gui','off'); 
            EEG = pop_saveset(EEG, 'filename', EEG.setname, 'filepath', SUBSPLITPATH);
    
        end                                                                                             % end loop across ICC / noICC files    
    end                                                                                             % end sorting out sub 3
end                                                                                                 % end loop across subs


%% end









