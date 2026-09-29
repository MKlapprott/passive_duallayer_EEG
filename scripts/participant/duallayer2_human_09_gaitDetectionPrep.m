%% duallayer2_human_09_gaitDetectionPrep.m
%
%
%
%
% Author: Melanie, 2025


%% Preparations


close all; clear all; clc;                                                                          % start with fresh workspace

% set paths
MAINPATH = 'R:\Ferris-Lab\mklapprott\eegl\';                                                        % adjust this path to your local environment!!!
cd(MAINPATH)

PATHIN = [MAINPATH, 'rawdata\participants\'];                                                       % path to raw data
PATHOUT = [MAINPATH, 'derivatives\participants\']; 
ICCPATH = [PATHOUT, 'duallayer2_human_04_iCC_ICA-corr\'];                                           % path for ICC & ICA corrected data data 

GAITPATH = [PATHOUT, 'duallayer2_human_07_gait_data\'];
if ~isfolder(GAITPATH)                                                                             % if the path doesn't exist yet, create it
    mkdir(GAITPATH)
end


subs_info = readtable([MAINPATH, 'participant_info.xlsx']);
subs = table2cell(subs_info(:,1));                                                                  % extract subject names
conds = table2cell(subs_info(:,4:8));                                                               % extract conditions
load('check.mat');
load('SUBS.mat');


%% Start looking for gait events

for sub = 13%:length(SUB) 

    PATHINSUB = [PATHIN, subs{sub}, '\'];
    cd(PATHINSUB)

    files = dir(fullfile(PATHINSUB, '*.xdf'));                                                      % get access to data sets - xdf

    % special treatment for our special snowflakes -----------------------------------------------

    if strcmp(subs{sub}, 'sub_03') || strcmp(subs{sub}, 'sub_06') || strcmp(subs{sub}, 'sub_07') || strcmp(subs{sub}, 'sub_11') ...
            || strcmp(subs{sub}, 'sub_12') || strcmp(subs{sub}, 'sub_13')

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
                plot(ALLEEG(idx+1).times, ALLEEG(idx+1).data(34,:));

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

