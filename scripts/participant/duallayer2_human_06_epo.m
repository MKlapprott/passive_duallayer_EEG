%% duallayer2_human_06_epo.m
%
% Description:
%   This script epochs participant EEG data into task- and event-specific segments 
%   for ERP analysis. It applies re-referencing, baseline correction, and 
%   artefact rejection before saving epoched datasets for downstream analyses.
%
% Workflow:
%   - Load split EEG datasets from previous ICA/ICC corrections
%   - Re-reference EEG data to mastoid channels (TP9, TP10)
%   - Cut epochs around predefined triggers (erp.EVENTS)
%   - Apply baseline correction
%   - Perform artefact rejection using joint probability and kurtosis
%   - Save epoched datasets per run, condition, and event type
%   - Update SUB structure with behavioral target counts and number of trials
%
% Inputs:
%   - Split EEG datasets (dualLayer2_human_05_splitdata)
%   - ERP parameters from erp.mat (epoch window, rejection thresholds)
%   - SUBS.mat containing participant info
%
% Outputs:
%   - Epoched EEG datasets per participant, run, condition, and event
%   - Updated SUBS.mat with behavioral and trial count information
%
% Dependencies:
%   - EEGLAB
%   - erp.mat, SUBS.mat%
%
%
% Author: Melanie, 2025

%% Preparations

clear all; close all; clc;

MAINPATH = 'Q:\Neuro\data\projects\all_gait\dual-layerCap\dual-layer-2024_25\eegl\';
PATHIN = [MAINPATH, 'rawdata\participants\'];
PATHOUT = [MAINPATH, 'derivatives\participants\'];

SPLITPATH = [PATHOUT, 'duallayer2_human_05_splitdata\'];                                            % path for split data 
EPOPATH = [PATHOUT, 'duallayer2_human_06_epo\'];                                                    % path for epoched data 

if ~isfolder(EPOPATH)                                                                               % if the path doesn't exist yet, create it
    mkdir(EPOPATH)
end

cd(MAINPATH)
load('SUBS.mat');
load('erp.mat');

%% Start loading & epoching

for sub = 1:length(SUB)

    if strcmp(SUB(sub).ID, 'sub_03')
        disp('skipping')
    else
        SUBSPLITPATH = [SPLITPATH, SUB(sub).ID, '\'];
        cd(SUBSPLITPATH)                                                                                % set filepath
        files = dir(fullfile(SUBSPLITPATH, '*.set'));                                                   % get access to data sets 
    
        for file = 1:length(files)
    
            [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;                                                    % start EEGLAB
    
            file_name = files(file).name;                                                               % get current file name
            EEG = pop_loadset('filename',file_name,'filepath',SUBSPLITPATH);
            [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);                                         % store data set
    
            if contains(file_name, 'trad')                                                              % sort for iCC condition
                cond = 'trad';
            elseif contains(file_name, 'ICC')
                cond = 'ICC';
            end
    
            if contains(file_name, 'cond-A')                                                            % give more concise names to the data sets
                mocond = 'stay';
            else
                mocond = 'walk';
            end
    
            EEG = pop_eegfiltnew(EEG, 'hicutoff', 30);                                       % low-pass filter
    
            % cut epochs around triggers -------------------------------------------------------------
    
            if strcmp(file_name, 'dualLayer2_5_sub_03_ICC-ICAcorr_run-2_cond-A.set')
                SUB(sub).stas(file) = 0;
                SUB(sub).tars(file) = 0;
    
                SUB(sub).behav_tars(file) = 0;
    
            elseif strcmp(file_name, 'dualLayer2_5_sub_03_trad-ICAcorr_run-2_cond-A.set')
                SUB(sub).stas(file) = 0;
                SUB(sub).tars(file) = 0;
    
                SUB(sub).behav_tars(file) = 0;
    
            else
    
                SUB(sub).behav_tars(file) = sum(strcmp({EEG.event.type}, 'tar'));                       % save for behavioral stats
    
                refchans = strmatch('TP', {EEG.chanlocs.labels});                                       % find mastoid electrodes
                EEG = pop_reref(EEG, refchans);                                                         % re-reference data to TP9 and TP10
                
                EEG = pop_epoch( EEG, erp.EVENTS, [erp.FROM erp.TO], 'epochinfo', 'yes');                   % cut SME-epochs from -.2 to 1.1 s
                EEG = pop_rmbase( EEG, [erp.FROM*1000 0] ,[]);                                          % baseline correction                                                 % baseline correction
            
                EEG = pop_jointprob(EEG,1,[1:EEG.nbchan] ,erp.REJ,erp.REJ,0,1,0,[],0);                  % artefact correction using joint probabilities
                EEG = pop_rejkurt(EEG,1,[1:EEG.nbchan] ,erp.REJ,erp.REJ,0,1,0,[],0);                    % artefact correction using channel kurtosis

                rej_kurt(sub, file) = sum(EEG.reject.rejkurt);
                
        %         EEG.setname = ['dualLayer2_', num2str(sub), '_', SUB(sub).ID, '_', cond, '_run-', ...
        %             num2str(erp.runs(file)),'_', mocond, '-epo'];                                       % new set name
        %         [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);                                       % save as new set (ALLEEG)
        % 
        %         SUBEPOPATH = [EPOPATH, SUB(sub).ID, '\'];
        % 
        %         if ~isfolder(SUBEPOPATH)                                                                % if the path doesn't exist yet, create it
        %             mkdir(SUBEPOPATH)
        %         end
        % 
        %         cd(SUBEPOPATH)
        % 
        %          for e = 1:length(erp.EVENTS)                                                           % go through event names
        % 
        %             EEG = pop_selectevent(ALLEEG(2), 'latency','-2<=2','type',...                       % select events
        %                 {erp.EVENTS{e}},'deleteevents','off','deleteepochs','on','invertepochs','off');
        % 
        %             [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);                                   % save as new set (ALLEEG)
        %             EEG.setname = ['dualLayer2_', num2str(sub), '_', SUB(sub).ID, '_', cond, '_run-', ...
        %             num2str(erp.runs(file)),'_', mocond, '-epo-', erp.events_save{e}];                  % store as separate set
        %             EEG = pop_saveset(EEG, 'filename', [EEG.setname], 'filepath', SUBEPOPATH);          % save data set
        % 
        %          end
        % 
        %          SUB(sub).stas(file) = size(ALLEEG(3).data, 3);
        %          SUB(sub).tars(file) = size(ALLEEG(4).data, 3);
        % 
        % 
             end
         end
    end
end


%save([MAINPATH,'SUBS'],'SUB');                                                                      % save information


%% end


subs = {'pilot_06', 'sub_01', 'sub_02', 'sub_03', 'sub_04', 'sub_05', 'sub_06', 'sub_07', 'sub_08', ...
    'sub_09', 'sub_10', 'sub_11', 'sub_12', 'sub_13', 'sub_14', 'sub_15'}';

conds = ["ID" "ICC_run1" "ICC_run2" "ICC_run3" "ICC_run4" "noICC_run1" "noICC_run2" "noICC_run3" "noICC_run4"];


T = array2table(rej_kurt);
T = addvars(T, subs, 'Before', 1);

T.Properties.VariableNames = conds;

writetable(T, [PATHOUT, 'rej_epochs.csv']);