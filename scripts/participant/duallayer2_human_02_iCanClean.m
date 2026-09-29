%% duallayer2_human_02_iCanClean.m
%
% Description:
%   This script applies the iCanClean (iCC) algorithm to participant EEG 
%   data from the dual-layer project. Both preprocessing variants are 
%   created: (1) with iCC denoising, and (2) without iCC (traditional 
%   preprocessing). The outputs are saved separately for each participant.
%
% Workflow:
%   - Define input/output paths and create subject-level folders
%   - Load subject information (SUB struct) and parameters (check.mat, params.mat)
%   - Loop over participants:
%       * Load preprocessed dataset from duallayer2_human_01_first-Check
%       * For each preprocessing option:
%            - iCC variant: apply iCanClean using EEG and Noise channels
%            - trad variant: keep dataset without iCC
%       * Save resulting datasets in subject-specific ICCPATH
%       * Store iCC diagnostic output in SUB struct
%   - Save updated SUB struct for later use
%
% Inputs:
%   - Preprocessed datasets from duallayer2_human_01_first-Check
%   - participant_info.xlsx with subject IDs
%   - check.mat with noise parameters
%   - params.mat with iCC settings
%   - SUBS.mat containing subject information
%
% Outputs:
%   - For each participant:
%       * *_preproc-iCC_eeg.set (after iCanClean)
%       * *_preproc-trad_eeg.set (without iCanClean)
%   - Updated SUB struct including iCC diagnostic info
%
% Dependencies:
%   - EEGLAB
%   - iCanClean (function for denoising dual-layer EEG)
%
% Author: Melanie, 2025

%% Preparations

close all; clear all; clc;                                                                          % start with fresh workspace

% set paths

MAINPATH = 'Q:\Neuro\data\projects\all_gait\dual-layerCap\dual-layer-2024_25\eegl\';                 % adjust this path to your local environment!!!
PATHIN = [MAINPATH, 'rawdata\participants\'];                                                       % path to raw data (changed from task-Flanker!!!)
PATHOUT = [MAINPATH, 'derivatives\participants\'];                                                  % path for data derivatives created on the way

CHECKPATH = [PATHOUT, 'duallayer2_human_01_first-Check\'];
ICCPATH = [PATHOUT, 'duallayer2_human_02_iCC\'];                                                    % path for ICC data 

if ~isfolder(ICCPATH)                                                                                % if the path doesn't exist yet, create it
    mkdir(ICCPATH)
end

file_paths = dir(fullfile(CHECKPATH));                                                               % get access to all folder names
file_paths(1:2) = [];                                                                                % first two entries in the struct are empty
file_paths(2) = [];                                                                                 % get rid of plots folder


cd(MAINPATH)
measurement_info = readtable([MAINPATH, 'participant_info_ana.xlsx']);                                  % load initial info table
load('check.mat');                                                                                  % load parameters containing info about noise
load('params.mat');                                                                                 % load params (written in duallayer2_gerd_00_configfiles.m)
load('SUBS.mat');                                                                                   % load info struct, which is extended with each script


%% start

for sub = 1:length(SUB)

    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;                                                            % start EEGLAB

    SUBCHECKPATH = [CHECKPATH, SUB(sub).ID, '\'];
    cd(SUBCHECKPATH)                                                                                % set filepath
    files = dir(fullfile(SUBCHECKPATH, '*.set'));                                                   % get access to data sets

    file_name = files.name;                                                                         % get current file name
    EEG = pop_loadset('filename',file_name,'filepath',SUBCHECKPATH);
    EEG.data = double(EEG.data);
    
    % acutal iCanClean ---------------------------------------------------------------------------
    
    SUBICCPATH = [ICCPATH, SUB(sub).ID, '\'];                                                       % create path for measurement
    
    if ~isfolder(SUBICCPATH)
        mkdir(SUBICCPATH)
    end
    
    do_iCC = [false,true];                                                                          % vector with preproc options
    
    for idx = 1:length(do_iCC)
        
        if do_iCC(idx)
            
            EEG_chans = find(strcmpi('EEG',{EEG.chanlocs.type}));                                   % get EEG channel indices
            Noise_chans = find(strcmpi('Noise',{EEG.chanlocs.type}));                               % get Noise channel indices 

            EEG = rerefC2CN2NExt2Ext_func(EEG,1);                                                           % re-reference
            EEG = iCanClean(EEG, EEG_chans, Noise_chans, 0, params);                            % perform iCanClean

            SUB(sub).ICC_info = EEG.etc.iCanClean;        % save iCC info

            cd(SUBICCPATH);
            % EEG = pop_saveset(EEG, 'filename', [EEG.setname, '_preproc-iCC_eeg'], 'filepath', SUBICCPATH);    % save data set
            % 
            % disp(['Saving data for ', EEG.setname, '_preproc-iCC_eeg'])
            
        % elseif ~do_iCC(idx)
            
            % fprintf('==== %s NO ICANCLEAN ====\n',EEG.setname);
            % 
            % cd(SUBICCPATH);
            % EEG = pop_saveset(EEG, 'filename', [EEG.setname, '_preproc-trad_eeg'], 'filepath', SUBICCPATH);    % save data set
            % 
            % disp(['Saving data for ', EEG.setname, '_preproc-trad_eeg'])
            
        end                                                                                         % end if-else deciding about preproc option
    end                                                                                             % end loop across preproc options

end                                                                                                 % end loop acrss measurements

%save([MAINPATH,'SUBS'],'SUB');                                                                      % save information

%% end

for idx = 1:16

    rem_comps_PH(idx) = SUB(idx).ICC_info.numNoiseCompsRemovedOnAvg;

end

avg = mean(rem_comps_PH);
my_min = min(rem_comps_PH);
my_max = max(rem_comps_PH);


%% Preparations

close all; clear all; clc;                                                                          % start with fresh workspace

% set paths

MAINPATH = 'Q:\Neuro\data\projects\all_gait\dual-layerCap\dual-layer-2024_25\eegl\';                                                        % adjust this path to your local environment!!!
PATHOUT = [MAINPATH, 'derivatives\participants\'];                                                  % path for data derivatives created on the way

ICCPATH = [PATHOUT, 'duallayer2_human_02_iCC\'];                                                     % path for iCanClean data 
ICAPATH = [PATHOUT, 'duallayer2_human_03_iCA\'];                                                     % path for ICA data 


if ~isfolder(ICAPATH)                                                                                % if the path doesn't exist yet, create it
    mkdir(ICAPATH)
end


cd(MAINPATH)
load('SUBS.mat');                                                                                   % load info struct, which is extended with each script

REJ = 3;                                                                                            % rejection threshold for bad epochs

%% Start Processing


for sub = 1:length(SUB)

    SUBICCPATH = [ICCPATH, SUB(sub).ID, '\'];
    cd(SUBICCPATH)                                                                                  % set filepath
    files = dir(fullfile(SUBICCPATH, '*.set'));                                                     % get access to data sets

    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;                                                        % start EEGLAB


    for file = 1:length(files)

        file_name = files(file).name;                                                               % get current file name
        EEG = pop_loadset('filename',file_name,'filepath',SUBICCPATH);

        if contains(file_name, 'trad')                                                              % sort for preproc condition
            cond = 'trad';
        elseif contains(file_name, 'iCC')
            cond = 'iCC';
        end

   % continue with real preparation for ICA -------------------------------------------------
    
        EEG = eeg_regepochs(EEG);                                                                   % cut in 1s epochs
        [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);                                         % store data set

        SUB(sub).nchans_ICA = EEG.nbchan;                                                           % update number of channels

        go_chans = EEG.chanlocs(strcmp({EEG.chanlocs.type},'EEG'));
        go_labels = {go_chans.labels};
        
        EEG = pop_select( EEG, 'channel',go_labels);                                                % only keep EEG channels
        EEG.setname = [SUB(sub).ID, '_preproc-', cond];
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'gui','off'); 

        EEG = pop_jointprob(EEG,1,[1:EEG.nbchan] ,REJ,REJ,0,1,0,[],0);                              % artefact rejection using joint probabilities
        EEG = pop_rejkurt(EEG,1,[1:EEG.nbchan] ,REJ,REJ,0,1,0,[],0);                                % artefact rejection using channel kurtosis   
    
        EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'interrupt','on');                  % run ICA
        EEG.setname = [SUB(sub).ID, '_preproc-', cond, '-ICAWeights'];                              % give set name
        [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);                                           % save as new set
    
         
        SUBICAPATH = [ICAPATH, SUB(sub).ID, '\'];
        if ~isfolder(SUBICAPATH)                                                                    % if the path doesn't exist yet, create it
            mkdir(SUBICAPATH)
        end
    
        EEG = pop_saveset(EEG, 'filename', EEG.setname, 'filepath', SUBICAPATH);                    % save data set
    end

end


save([MAINPATH,'SUBS'],'SUB');                                                                      % save information

%% end



