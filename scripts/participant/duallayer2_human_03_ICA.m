%% duallayer2_human_03_ICA.m
%
% Description:
%   This script performs Independent Component Analysis (ICA) on dual-layer 
%   EEG datasets prepared in the previous step (with and without iCanClean). 
%   Data are epoched, cleaned using statistical rejection (joint probability 
%   and kurtosis), and ICA weights are computed and stored. Results are saved 
%   separately for each preprocessing condition.
%
% Workflow:
%   - Define input/output paths and create subject-level folders
%   - Load subject information (SUB struct)
%   - Loop over participants:
%       * Load iCC and trad datasets from duallayer2_human_02_iCC
%       * Epoch into 1s segments
%       * Retain only EEG channels
%       * Reject bad epochs based on probability and kurtosis
%       * Run ICA (runica, extended)
%       * Save datasets with ICA weights in subject-specific ICAPATH
%       * Update SUB struct with channel information
%   - Save updated SUB struct for later use
%
% Inputs:
%   - Preprocessed datasets from duallayer2_human_02_iCC
%   - SUBS.mat containing subject information
%
% Outputs:
%   - For each participant and condition:
%       * *_preproc-trad-ICAWeights.set
%       * *_preproc-iCC-ICAWeights.set
%   - Updated SUB struct including channel info for ICA
%
% Dependencies:
%   - EEGLAB
%
%
% Author: Melanie, 2025

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


for sub = 3:length(SUB)

    SUBICCPATH = [ICCPATH, SUB(sub).ID, '\'];
    cd(SUBICCPATH)                                                                                  % set filepath
    files = dir(fullfile(SUBICCPATH, '*.set'));                                                     % get access to data sets

    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;                                                        % start EEGLAB


    for file = 1%:length(files)

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

        pop_topoplot(EEG, 0, [1:6] ,'ICs scalp layer',[3 2] ,0,'electrodes','on');

        cd(ICAPATH)
        fig = ancestor(gca, 'figure');
        exportgraphics(fig, [SUB(sub).ID, '-ICA-Topos_scalplayer.png']);                                % save plot
    
         
        % SUBICAPATH = [ICAPATH, SUB(sub).ID, '\'];
        % if ~isfolder(SUBICAPATH)                                                                    % if the path doesn't exist yet, create it
        %     mkdir(SUBICAPATH)
        % end
    
        %EEG = pop_saveset(EEG, 'filename', EEG.setname, 'filepath', SUBICAPATH);                    % save data set
    end

end


save([MAINPATH,'SUBS'],'SUB');                                                                      % save information

%% end
