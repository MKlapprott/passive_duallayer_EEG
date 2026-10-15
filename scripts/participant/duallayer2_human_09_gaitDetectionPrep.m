%% duallayer2_human_09_gaitDetectionPrep.m
%
% PURPOSE
%   Prepare continuous EEG recordings for subsequent gait analysis by
%   integrating right-foot IMU data, identifying task boundaries, and
%   extracting the relevant experimental runs into separate EEGLAB datasets.
%
% DATA
%   - Raw recordings stored in XDF format.
%   - Continuous EEG data that have undergone ICA correction.
%   - Motion data recorded using Movella DOT inertial measurement units.
%   - Right- and left-foot IMU streams are identified in the XDF recording;
%     the right-foot stream is used for the gait analysis in this script.
%   - Experimental task markers are used to identify the different runs.
%
% PROCESSING OVERVIEW
%   1. Load participant information, condition labels, and auxiliary files.
%   2. Identify the relevant XDF recording and load its data streams.
%   3. Identify the EEG, right-foot IMU, and left-foot IMU streams.
%   4. Load the corresponding ICA-corrected continuous EEG dataset.
%   5. Interpolate the six right-foot IMU channels onto the EEG time base
%      so that the IMU and EEG data share a common sampling grid.
%   6. Append the right-foot accelerometer and gyroscope signals as channels
%      33–38 in the EEGLAB dataset.
%   7. Identify task start and end markers to determine the boundaries of
%      the experimental runs.
%   8. Extract the individual runs, including dual-task runs and the
%      walking-only run, using the event latencies.
%   9. Use the experimental condition information to identify the runs
%      relevant to gait analysis.
%  10. Concatenate the appropriate dual-task walking runs into a combined
%      walking dataset.
%  11. Save the extracted and combined datasets for subsequent gait-event
%      detection and walking-speed estimation.
%
% IMU INTEGRATION
%   - The right-foot IMU stream provides three accelerometer and three
%     gyroscope channels.
%   - IMU timestamps are converted to milliseconds relative to the first
%     IMU timestamp.
%   - Linear interpolation is used to map the IMU data onto EEG.times.
%   - Extrapolation is enabled for EEG time points outside the IMU time
%     range; these extrapolated samples should be checked for validity.
%   - The IMU channels are appended to the EEG data matrix and labelled
%     according to sensor axis.
%
% CHANNEL ORGANIZATION
%   Channels 33–35: right-foot accelerometer axes 1–3.
%   Channels 36–38: right-foot gyroscope axes 1–3.
%
% RUN EXTRACTION
%   - Task markers are identified from the EEGLAB event structure.
%   - Individual runs are extracted using their corresponding start and
%     end marker latencies, with small sample offsets around boundaries.
%   - Participant-specific exceptions are included for recordings with
%     known data or marker issues.
%   - Run order and experimental condition labels are used to determine
%     which runs should be combined for gait analysis.
%   - The relevant dual-task walking runs are concatenated into a single
%     dataset; the walking-only run is saved separately.
%
% OUTPUTS
%   - EEGLAB datasets containing the appended right-foot IMU channels.
%   - Separate datasets for the extracted experimental runs.
%   - Combined datasets for the selected dual-task walking runs.
%   - Output files saved in participant-specific directories under the
%     gait-data derivatives folder.
%
% QUALITY CONTROL AND LIMITATIONS
%   - Correct alignment depends on valid EEG and IMU timestamps and on
%     consistent identification of the relevant XDF streams.
%   - Interpolation and extrapolation can affect the IMU values at the
%     edges of the recording; verify alignment and edge samples.
%   - Run extraction depends on the presence, ordering, and validity of
%     task markers.
%   - Participant-specific exclusions and marker corrections should be
%     documented and reviewed.
%   - Verify that channel labels, channel indices, and sensor axes are
%     consistent with the actual data layout.
%   - Confirm that the selected runs correspond to the intended experimental
%     conditions before using the output for gait analysis.
%
% Author: Melanie, 2025


%% Preparations


close all; clear all; clc;                                                                          % start with fresh workspace

% set paths
MAINPATH = 'Q:\Neuro\data\projects\all_gait\dual-layerCap\dual-layer-2024_25\eegl\';                                                       % adjust this path to your local environment!!!
cd(MAINPATH)

PATHIN = [MAINPATH, 'rawdata\participants\'];                                                       % path to raw data
PATHOUT = [MAINPATH, 'derivatives\participants\']; 
ICCPATH = [PATHOUT, 'duallayer2_human_04_iCC_ICA-corr\'];                                           % path for ICC & ICA corrected data data 

GAITPATH = [PATHOUT, 'duallayer2_human_07_gait_data\'];
if ~isfolder(GAITPATH)                                                                             % if the path doesn't exist yet, create it
    mkdir(GAITPATH)
end


subs_info = readtable([MAINPATH, 'participant_info_ana.xlsx']);
subs = table2cell(subs_info(:,1));                                                                  % extract subject names
conds = table2cell(subs_info(:,4:8));                                                               % extract conditions
load('check.mat');
load('SUBS.mat');


%% Start looking for gait events

for sub = 1:length(SUB) 

    PATHINSUB = [PATHIN, SUB(sub).ID, '\'];
    cd(PATHINSUB)

    files = dir(fullfile(PATHINSUB, '*.xdf'));                                                      % get access to data sets - xdf

    % special treatment for our special snowflakes -----------------------------------------------

    if strcmp(subs{sub}, 'sub_03') || strcmp(subs{sub}, 'sub_06') || strcmp(subs{sub}, 'sub_07') || strcmp(subs{sub}, 'sub_11') ...
            || strcmp(subs{sub}, 'sub_12') || strcmp(subs{sub}, 'sub_13') || strcmp(subs{sub}, 'sub_15')

       disp('Something went wrong with the IMUs here, so we skip this :`)...')
        
    else

        file_name = files.name;
        data = load_xdf([PATHINSUB, file_name]);                                                    % load xdf data with motion data
    
        % get indeces for streams ----------------------------------------------------------------
    
        for stream = 1:length(data)
            cur_name = data{1, stream}.info.name;
        
            if strcmp(cur_name, 'Android_EEG - PROX_049')
                eeg_stream = stream;
            elseif strcmp(cur_name, 'Movella DOT DOT4')
                right_foot = stream;
            elseif strcmp(cur_name, 'Movella DOT DOT3')
                left_foot = stream;
        
            end
        
        end
    
        % load ICA corrected, continuous EEG data ------------------------------------------------
    
        SUBICCPATH = [ICCPATH, SUB(sub).ID, '\'];
        cd(SUBICCPATH)                                                                              % set filepath
        files = dir(fullfile(SUBICCPATH, '*.set'));                                                 % get access to data sets
    
        for file = 1:length(files)
    
            [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;                                             % start EEGLAB
        
            file_name = files(file).name;                                                           % get current file name
            EEG = pop_loadset('filename',file_name,'filepath',SUBICCPATH);
    
            right_foot_time_series = data{1, right_foot}.time_series(1:6,:);
            right_foot_time = (data{1, right_foot}.time_stamps - data{1, right_foot}.time_stamps(1)) * 1000;
            
            % interpolate to match EEG srate
            right_foot_time_series = interp1(right_foot_time, double(right_foot_time_series)', EEG.times, 'linear', 'extrap');
            right_foot_time_stamps = interp1(right_foot_time, double(right_foot_time)', EEG.times, 'linear', 'extrap');    
            right_foot_time_series = right_foot_time_series';

            % add as channel in EEG 
            EEG.data(33:38, :) = right_foot_time_series;
            EEG.nbchan = 38;
            
            for idx = 33:38                
                EEG.chanlocs(idx).type = 'IMU';               
                EEG.urchanlocs(idx).type = 'IMU';
            end
            
            EEG.chanlocs(33).labels = 'rightFootAcc1';
            EEG.urchanlocs(33).labels = 'rightFootAcc1';
            EEG.chanlocs(34).labels = 'rightFootAcc2';
            EEG.urchanlocs(34).labels = 'rightFootAcc2';
            EEG.chanlocs(35).labels = 'rightFootAcc3';
            EEG.urchanlocs(36).labels = 'rightFootAcc3';
            EEG.chanlocs(36).labels = 'rightFootGyro1';
            EEG.urchanlocs(36).labels = 'rightFootGyro1';
            EEG.chanlocs(37).labels = 'rightFootGyro2';
            EEG.urchanlocs(37).labels = 'rightFootGyro2';
            EEG.chanlocs(38).labels = 'rightFootGyro3';
            EEG.urchanlocs(38).labels = 'rightFootGyro3';
            
            [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);                                             % store data set
        
            % extract walking periods ------------------------------------------------------------
        
            all_starts = find(strcmp({EEG.event.type}, '1 instruction'));
            all_ends = find(strcmp({EEG.event.type}, '5 end_block'));

            if contains(file_name, 'trad')
                cond = 'trad';
            elseif contains(file_name, 'ICC')
                cond = 'ICC';
            end
        
    
            SUBGAITPATH = [GAITPATH, SUB(sub).ID '\'];
            if ~isfolder(SUBGAITPATH)                                                                             % if the path doesn't exist yet, create it
                mkdir(SUBGAITPATH)
            end

            if strcmp(SUB(sub).ID, 'sub_09')
                all_starts(4) = [];
            end

            figure;
            for idx = 1:4
                subplot(6,1,idx)
                plot(ALLEEG(1).times, ALLEEG(1).data(32+idx, :))
            end
            
            for idx = 1:length(all_starts)
                hold on
                xline(ALLEEG(1).times(ALLEEG(1).event(all_starts(idx)).latency), 'Color', 'b')
                hold on
                xline(ALLEEG(1).times(ALLEEG(1).event(all_ends(idx)).latency), 'Color', 'r')
            end



    
            % RUN 1
            EEG = pop_select( ALLEEG(1), 'point',[ALLEEG(1).event(all_starts(2)).latency-10 ALLEEG(1).event(all_ends(2)).latency+10] );
            [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname', ...
                ['dualLayer2_', num2str(sub), '_', SUB(sub).ID, '_', cond, '-ICAcorr_run-1_cond-', conds{sub, 1}'], 'gui','off'); 
        
            % RUN 2
            EEG = pop_select( ALLEEG(1), 'point',[ALLEEG(1).event(all_starts(3)).latency-10 ALLEEG(1).event(all_ends(3)).latency] );
            [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname', ...
                ['dualLayer2_', num2str(sub), '_', SUB(sub).ID, '_', cond, '-ICAcorr_run-2_cond-', conds{sub, 2}'], 'gui','off');           
        
            % RUN 3 (walk only)
            EEG = pop_select( ALLEEG(1), 'point',[ALLEEG(1).event(all_ends(3)).latency-10 ALLEEG(1).event(all_starts(4)).latency+10] );
            [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname', ...
                ['dualLayer2_', num2str(sub), '_', SUB(sub).ID, '_', cond, '-walk_only'], 'gui','off'); 
            EEG = pop_saveset(EEG, 'filename', EEG.setname, 'filepath', SUBGAITPATH);                   % save data set    
        
            % RUN 4
            EEG = pop_select( ALLEEG(1), 'point',[ALLEEG(1).event(all_starts(4)).latency-10 ALLEEG(1).event(all_ends(4)).latency+10] );
            [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname', ...
                ['dualLayer2_', num2str(sub), '_', SUB(sub).ID, '_', cond, '-ICAcorr_run-4_cond-', conds{sub, 4}'], 'gui','off'); 
    
        
            % RUN 5
            EEG = pop_select( ALLEEG(1), 'point',[ALLEEG(1).event(all_starts(5)).latency-10 ALLEEG(1).event(all_ends(5)).latency+10] );
            [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname', ...
                ['dualLayer2_', num2str(sub), '_', SUB(sub).ID, '_', cond, '-ICAcorr_run-5_cond-', conds{sub, 5}'], 'gui','off'); 
    
    
            figure;
            for idx = 1:6
                subplot(6,1,idx)
                plot(ALLEEG(idx).times, ALLEEG(idx).data(34,:));

            end
        
            runs = [1,2,3,4,5];
            gait_runs_idx = strcmp(subs_info{sub, 5:9}, 'B') | strcmp(subs_info{sub, 5:9}, 'C');
            gait_runs = runs(gait_runs_idx);
    
            if gait_runs(1) == 1

                EEG = pop_mergeset(ALLEEG, [2 6], 0);                                                  % concatenate walk_dual EEG data
                EEG.setname = ['dualLayer2_', num2str(sub), '_', SUB(sub).ID, '_', cond, '-walk_dual'];
                [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);                                     % store data set
                EEG = pop_saveset(EEG, 'filename', EEG.setname, 'filepath', SUBGAITPATH);                   % save data set
    
            elseif gait_runs(1) == 2
                EEG = pop_mergeset( ALLEEG, [3 5], 0);                                                  % concatenate walk_dual EEG data
                EEG.setname = ['dualLayer2_', num2str(sub), '_', SUB(sub).ID, '_', cond, '-walk_dual'];
                [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);                                     % store data set
                EEG = pop_saveset(EEG, 'filename', EEG.setname, 'filepath', SUBGAITPATH);                   % save data set
    
            end                                                                                         % end if / else for different exp versions
    
        end                                                                                             % end loop across files
    end                                                                                             % end sorting out sub3
end                                                                                                 % end loop across participants

%%

