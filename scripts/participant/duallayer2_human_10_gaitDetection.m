%% duallayer2_human_10_gaitDetection.m
%
%
%
%
% Author: Melanie, 2025


%% Preparations


close all; clear all; clc;                                                                          % start with fresh workspace

% set paths
MAINPATH = 'Q:\Neuro\data\projects\all_gait\dual-layerCap\dual-layer-2024_25\eegl\';                % adjust this path to your local environment!!!
cd(MAINPATH)

PATHIN = [MAINPATH, 'rawdata\participants\'];                                                       % path to raw data
PATHOUT = [MAINPATH, 'derivatives\participants\']; 
GAITPATH = [PATHOUT, 'duallayer2_human_07_gait_data\'];

load('SUBS.mat');

% gait parameters
gait_event_order = {'RHS', 'RTO', 'RHS'};
gait_timeNextHs = [.5 1.5];
Step_thresh = 10;
minPeakDist = 0.5;

% filter settings
LPF1 = 6; LPF2 = 30; Order = 2; srate = 250;
[b_low1,a_low1]=butter(Order,LPF1/(srate/2),'low');
[b_low2,a_low2]=butter(Order,LPF2/(srate/2),'low');

%%


for sub = 14:length(SUB)

    % special treatment for our special snowflakes -----------------------------------------------

    if strcmp(SUB(sub).ID, 'sub_03') || strcmp(SUB(sub).ID, 'sub_06') || strcmp(SUB(sub).ID, 'sub_07') || ...
            strcmp(SUB(sub).ID, 'sub_09')  || strcmp(SUB(sub).ID, 'sub_11') || strcmp(SUB(sub).ID, 'sub_12') || ...
            strcmp(SUB(sub).ID, 'sub_13') || strcmp(SUB(sub).ID, 'sub_15')


        disp('Something went wrong with the IMUs here, so we skip this :`)...')
        
    else

        SUBGAITPATH = [GAITPATH, SUB(sub).ID, '\'];
        cd(SUBGAITPATH)                                                                             % set filepath
        files = dir(fullfile(SUBGAITPATH, '*.set'));                                                % get access to data sets
    
        for file = 1:length(files)

            [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;                                             % start EEGLAB
        
            file_name = files(file).name;                                                           % get current file name
            EEG = pop_loadset('filename',file_name,'filepath',SUBGAITPATH);
            EEG.setname = file_name(1:end-4);
            [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);                                     % store data set

            % focus on IMU channels --------------------------------------------------------------
    
            Acc = pop_select(EEG, 'nochannel', [1:32]);                                             % keep only IMU channels
    
            data = detrend(double(Acc.data'));                                                      % detrending
            data2 = filtfilt(b_low2,a_low2, data);                                                  % 30 Hz
            Acc.data = data2';
            data = filtfilt(b_low1,a_low1, data);                                                   % 6 Hz
            Acc2.data = data';
            
            
            if contains(EEG.setname, 'walk_dual')
                all_starts = find(strcmp({EEG.event.type}, '1 instruction'));
                all_ends = find(strcmp({EEG.event.type}, '5 end_block'));
                START = EEG.event(all_starts(1)).latency-10;
                TO = EEG.event(all_ends(end)).latency+10;
            elseif contains(EEG.setname, 'walk_only')
                all_starts = find(strcmp({EEG.event.type}, 'boundary'));
                all_ends = find(strcmp({EEG.event.type}, '1 instruction'));
                START = EEG.event(all_starts).latency-10;
                TO = EEG.event(all_ends(end)).latency+10;
            end

            % find peaks in vertical acceleration (2nd Acc channel) ------------------------------
    
            [~, idxMS] =findpeaks(Acc2.data(2,:), 'MinPeakHeight', Step_thresh,'minPeakDist', minPeakDist*Acc.srate); % identify peaks in 6Hz filtered data
            %findpeaks(Acc2.data(2,:), 'MinPeakHeight', Step_thresh,'minPeakDist', minPeakDist*Acc.srate)

                
            for ev = 2:length(idxMS)-1                                                              %loop through all peaks
                        
                FROM = idxMS(ev)-.2*Acc.srate;
                
                % HEAL STRIKE: find peak in the 30 Hz LPF filtered vertical acceleration signal in
                % the surronding 200 ms
                
                tmp = Acc.data(2, FROM : FROM+.2*Acc.srate);                                        % use 30Hz filtered data for event making 
                [maxVal, idxHS] = max(tmp);
                
                if ~isempty(idxHS)                                                                  % if present add as event
                    EEG.event(end+1).type = 'RHS';
                    EEG.event(end).latency = START+FROM+idxHS;
                    EEG.event(end).duration = 1;
                end
                
                % TOE OFF: get AP acceleration of half a second before ---------------------------

                shift =.5*Acc.srate;
                tmp = Acc.data(2, START+FROM+idxHS-shift : START+FROM+idxHS);                       % use 30Hz filtered data for event making 

                [~, idxTO] = findpeaks(tmp, 'NPeaks', 2, 'SortStr' ,'descend');                     %find two highest peaks
                
                if ~isempty(idxTO)
                    EEG.event(end+1).type = 'RTO';                                                  % if present add as event
                    EEG.event(end).latency = START+FROM-shift+mean(idxTO);                          % get mean position as TO estimate
                    EEG.event(end).duration = 1;
                end
                clearvars idxIC idxTO
            end
    
            
            EEG = eeg_checkset(EEG, 'eventconsistency');                                             % sort events by latency
    
            % check for validity -----------------------------------------------------------------
    
            evalc('EEG = pop_select(EEG, ''point'', [START TO]);');   
            EEG.etc.valid_eeg = true(1, EEG.pnts);
            [EEG.etc.strides.number,EEG.etc.strides.numValid] = validStrides(EEG, gait_event_order,gait_timeNextHs);
    
            pause(3)
    
            SUB(sub).strides.number(file) = EEG.etc.strides.number;
            SUB(sub).strides.percValid(file) = EEG.etc.strides.numValid;
            
            SUBGAITPATHOUT = [GAITPATH, SUB(sub).ID '\step_events\'];
            if ~isfolder(SUBGAITPATHOUT)    
                mkdir(SUBGAITPATHOUT)
            end
    
            EEG.setname = [EEG.setname,'_steps'];
            [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);                                     % store data set
            EEG = pop_saveset(EEG, 'filename', EEG.setname, 'filepath', SUBGAITPATHOUT);            % save data set
    
        end                                                                                         % end loop across iCC files
        SUB(sub).strides.file_order = {'iCC_dual', 'iCC_only', 'trad_dual', 'trad_only'};
    end                                                                                             % end sorting out subs  
end                                                                                                 % end loop across subjects


%% save struct!

save([MAINPATH,'SUBS'],'SUB');                                                                      % save information





