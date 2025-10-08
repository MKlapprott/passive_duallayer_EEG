%% duallayer2_gerd_04_ICA.m
%
% Description:
%   This script performs Independent Component Analysis (ICA) on phantom head EEG 
%   datasets that were either preprocessed with iCanClean (ICC) or traditional methods. 
%   The ICA decomposition is run on EEG channels only, and dipole fitting is 
%   tested for evaluation purposes. Results are saved separately for each condition.
%
% Workflow:
%   - Define input/output paths and load parameters
%   - Loop across measurement sessions and preprocessing conditions (ICC vs. trad)
%   - Load preprocessed EEG datasets
%   - Keep only EEG channels for ICA
%   - Run ICA (extended Infomax) and store decomposition
%   - Perform dipole fitting (exploratory step)
%   - Save ICA-weighted datasets in structured output folders
%
% Inputs:
%   - Preprocessed EEG datasets (.set) from ICCPATH
%   - 'MEAS.mat' containing measurement metadata
%   - 'df_params.mat' with dipole fitting parameters
%   - Standard EEGLAB head model files (standard_vol.mat, standard_mri.mat, standard_1020.elc)
%
% Outputs:
%   - ICA-weighted EEG datasets (.set) stored in ICAPATH
%   - Updated MEAS.mat including number of channels used for ICA
%
% Dependencies:
%   - EEGLAB (for ICA, dipole fitting, and data handling)
%   - Dipfit EEGLAB plugin (for dipole fitting functions)
%
%
% Author: Melanie, 2025

%% Preparations

close all; clear all; clc;                                                                          % start with fresh workspace

% set paths --------------------------------------------------------------------------------------

MAINPATH = 'R:\Ferris-Lab\mklapprott\eegl\';                                                        % adjust this path to your local environment!!!
PATHOUT = [MAINPATH, 'derivatives\gerd\'];                                                           % path for data derivatives created on the way

CHECKPATH = [PATHOUT, 'duallayer2_gerd_01_first-Check2\'];
ICCPATH = [PATHOUT, 'duallayer2_gerd_02_iCC\'];                                                      % path for iCanClean data 
ICAPATH = [PATHOUT, 'duallayer2_gerd_03_iCA\'];                                                      % path for ICA data 

if ~isfolder(ICAPATH)                                                                                % if the path doesn't exist yet, create it
    mkdir(ICAPATH)
end

% parameters -------------------------------------------------------------------------------------

cd(MAINPATH)
load('MEAS.mat');
load('df_params.mat')


%% Start Processing


for meas = 7:length(MEASUREMENTS)

    SUBICCPATH = [ICCPATH, MEASUREMENTS(meas).ID, '\'];
    cd(SUBICCPATH)                                                                                  % set filepath
    files = dir(fullfile(SUBICCPATH, '*.set'));                                                     % get access to data sets

    for file = 1:length(files)

        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;                                                    % start EEGLAB

        file_name = files(file).name;                                                               % get current file name
        EEG = pop_loadset('filename',file_name,'filepath',SUBICCPATH);

        if contains(file_name, 'trad')                                                              % sort of iCC conditions
            cond = 'trad';
        else
            cond = 'ICC';
        end
    
        


        % continue with real preparation for ICA -------------------------------------------------
   
        go_chans = EEG.chanlocs(strcmp({EEG.chanlocs.type},'EEG'));                                 % get EEG channels
        go_labels = {go_chans.labels};                                                              % get their labels
        
        EEG = pop_select( EEG, 'channel',go_labels);                                                % only keep EEG chans for ICA
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'gui','off'); 

        MEASUREMENTS(meas).nchans_ICA = EEG.nbchan;                                                 % update number of channels
    
        EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'interrupt','on');                  % run ICA
        EEG.setname = [MEASUREMENTS(meas).ID, '_preproc-ICAWeights'];                               % give set name
        [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);                                           % save as new set
    
        % try out dipole fitting -----------------------------------------------------------------

        EEG = pop_dipfit_settings( EEG, 'hdmfile', [MAINPATH,'standard_vol.mat'], ...               % dipole fitting settings (for trying out stuff)
            'mrifile',[MAINPATH, 'standard_mri.mat'], 'chanfile',[MAINPATH, 'standard_1020.elc'],...
            'coordformat','MNI');
        
        [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
        EEG = pop_dipfit_gridsearch(EEG, [1:length(EEG.chanlocs)] , df.gridA, df.gridB, df.gridC, 0.4);               % dipole fitting (for trying out stuff)
      
        SUBICAPATH = [ICAPATH,MEASUREMENTS(meas).ID,'\'];
        if ~isfolder(SUBICAPATH)                                                                    % if the path doesn't exist yet, create it
            mkdir(SUBICAPATH)
        end
    
        EEG.setname = [MEASUREMENTS(meas).ID, '_preproc-', cond, '_ICAWeights'];
        EEG = pop_saveset(EEG, 'filename', EEG.setname, 'filepath', SUBICAPATH);                    % save data set
    end                                                                                             % end loop across preproc conditions
end                                                                                                 % end loop across measurements


save([MAINPATH,'MEAS'],'MEASUREMENTS');  


%% end

