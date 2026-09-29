%% duallayer2_gerd_05_epo.m
%
% Description:
%   This script creates epoched EEG datasets from ICA-preprocessed phantom head 
%   recordings. Data are re-referenced, segmented into stimulus-locked epochs, 
%   baseline-corrected, and cleaned of artifacts using probability- and kurtosis-based 
%   rejection. The resulting datasets are saved for ERP analysis.
%
% Workflow:
%   - Define input/output paths and load parameters
%   - Loop across measurement sessions and preprocessing conditions (ICC vs. trad)
%   - Load ICA-preprocessed datasets
%   - Re-reference to mastoid electrodes (TP9/TP10)
%   - Epoch data relative to condition-specific events
%   - Apply baseline correction
%   - Perform artifact rejection (joint probability & kurtosis)
%   - Save cleaned epoch datasets in structured folders
%
% Inputs:
%   - ICA-preprocessed EEG datasets (.set) from ICAPATH
%   - 'erp.mat' with epoching parameters:
%         * erp.gerd_events   : event markers per measurement
%         * erp.FROM / TO     : epoch time window
%         * erp.REJ           : thresholds for artifact rejection
%   - 'MEAS.mat' with measurement metadata
%
% Outputs:
%   - Epoched and cleaned EEG datasets (.set) stored in EPOPATH
%
% Dependencies:
%   - EEGLAB (for rereferencing, epoching, baseline correction, and artifact rejection)
%
%
% Author: Melanie, 2025

%% Preparations

close all; clear all; clc;                                                                          % start with fresh workspace

% set paths

MAINPATH = 'Q:\Neuro\data\projects\all_gait\dual-layerCap\dual-layer-2024_25\eegl\';
cd(MAINPATH)

PATHOUT = [MAINPATH, 'derivatives\gerd\'];                                                          % path for data derivatives created on the way

ICAPATH = [PATHOUT, 'duallayer2_gerd_03_iCA\'];                                                     % path for ICA data 
EPOPATH = [PATHOUT, 'duallayer2_gerd_04_epo\'];                                                     % path for epoch data 

if ~isfolder(EPOPATH)                                                                                % if the path doesn't exist yet, create it
    mkdir(EPOPATH)
end


% load parameters

load('erp.mat');  
load('MEAS.mat');  


%% start

for meas = 1:length(MEASUREMENTS)

    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;                                                     % start EEGLAB

    SUBICAPATH = [ICAPATH, MEASUREMENTS(meas).ID, '\'];

    cd(SUBICAPATH)                                                                                  % set filepath
    files = dir(fullfile(SUBICAPATH, '*.set'));                                                     % get access to data sets

    figure;

    for file = 1:length(files)

        file_name = files(file).name;
        EEG = pop_loadset('filename',file_name,'filepath',SUBICAPATH);
        [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);                                           % save as new set (ALLEEG)

        if contains(file_name, 'trad')                                                              % sort iCC condition
            cond = 'trad';
        else
            cond = 'ICC';
        end


        SUBEPOSME = [EPOPATH, MEASUREMENTS(meas).ID, '\'];
        if ~isfolder(SUBEPOSME)                                                                     % if the path doesn't exist yet, create it
            mkdir(SUBEPOSME)
        end

        EEG = pop_interp(EEG, EEG.urchanlocs , 'spherical');                                        % and interpolate them using urchanlocs        

    
        %refchans = strmatch('TP', {EEG.chanlocs.labels});                                           % find mastoid electrodes
        EEG = pop_reref(EEG, []);                                                             % re-reference data to TP9 and TP10
        EEG = pop_epoch( EEG, {erp.gerd_events{meas}}, [erp.FROM erp.TO], 'epochinfo', 'yes');      % cut SME-epochs from -.2 to 0.8 s
        EEG = pop_rmbase( EEG, [erp.FROM*1000 0] ,[]);                                              % baseline correction  

        nchan = EEG.nbchan;
    
        %EEG = pop_jointprob(EEG,1,[1:nchan] ,erp.REJ,erp.REJ,0,1,0,[],0);                           % artefact correction using joint probabilities
        %EEG = pop_rejkurt(EEG,1,[1:nchan] ,erp.REJ,erp.REJ,0,1,0,[],0);                             % artefact correction using channel kurtosis
        EEG.setname = [num2str(file), '_',MEASUREMENTS(meas).ID, '_', cond, '_epochs']; % new set name
        [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);                                           % save as new set (ALLEEG)

        EEG = pop_saveset(EEG, 'filename', EEG.setname, 'filepath', SUBEPOSME);    % save data set

        subplot(2,1,file)
        plot(EEG.times, mean(EEG.data, 3));
        title(EEG.setname, 'Interpreter','none')
        ylim([-5 5])
        sgtitle(MEASUREMENTS(meas).ID, 'Interpreter', 'none')
    
    end


end



%% end
