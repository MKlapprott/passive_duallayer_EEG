%% duallayer2_human_04_ICA_select.m
%
% Description:
%   This script performs ICLabel classification on ICA datasets for all participants. 
%   It identifies bad components (eye, muscle, line noise, other), saves their indices, 
%   generates topographical plots, and updates the SUB structure with component info.
%
% Workflow:
%   - Load ICA datasets from duallayer2_human_03_iCA
%   - Loop over participants and preprocessing conditions (trad, iCC):
%       * Apply ICLabel to classify components
%       * Count components by type (brain, eye, muscle, line noise, other)
%       * Generate and save component topographies
%       * Save indices of bad ICs in EEG structure and SUB structure
%       * Store updated EEG datasets in subject-specific 'badICs' folder
%   - Save updated SUB structure and component statistics
%
% Inputs:
%   - ICA datasets from duallayer2_human_03_iCA
%   - SUBS.mat containing participant information
%
% Outputs:
%   - *_preproc-*-BadICs.set for each participant and condition
%   - PNG topography plots of ICs
%   - Updated SUBS.mat with bad IC indices
%   - COMP_stats.mat summarizing component counts
%
% Dependencies:
%   - EEGLAB with ICLabel plugin
%
% Author: Melanie, 2025

%% Preparations

close all; clear all; clc;                                                                          % start with fresh workspace

% set paths

MAINPATH = 'R:\Ferris-Lab\mklapprott\eegl\';                                                        % adjust this path to your local environment
PATHOUT = [MAINPATH, 'derivatives\participants\'];                                                  % path for data derivatives created on the way
ICAPATH = [PATHOUT, 'duallayer2_human_03_iCA\'];                                                    % path for ICA data 

cd(MAINPATH)
load('SUBS.mat');                                                                                   % load info struct, which is extended with each script


%%

for sub = 14:length(SUB)

    SUBICAPATH = [ICAPATH, SUB(sub).ID, '\'];
    cd(SUBICAPATH)                                                                                  % set filepath
    files = dir(fullfile(SUBICAPATH, '*.set'));                                                     % get access to data sets

    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;                                                        % start EEGLAB


    for file = 1:length(files)

        file_name = files(file).name;                                                               % get current file name
        EEG = pop_loadset('filename',file_name,'filepath',SUBICAPATH);
    
        [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);

        if contains(file_name, 'trad')
            iCC_cond = 'trad';
        elseif contains(file_name, 'iCC')
            iCC_cond = 'ICC';
        end

    
        if isfield(EEG, 'badics')                                                                   % if this field exists...
            EEG = rmfield(EEG, 'badics');                                                           % throw it out
        end

        EEG = pop_iclabel(EEG, 'default');

        % save info from iclabel here! -> number of components with probability larger than 75%
        % 1 = brain, 2 = eye, 3 = muscle, 4 = line noise, 5 = other

        c_brain = find(EEG.etc.ic_classification.ICLabel.classifications(:,1) > .75);
        c_eye = find(EEG.etc.ic_classification.ICLabel.classifications(:,3) > .4);
        c_muscle = find(EEG.etc.ic_classification.ICLabel.classifications(:,2) > .75);
        c_line = find(EEG.etc.ic_classification.ICLabel.classifications(:,5) > .75);
        c_others = find(EEG.etc.ic_classification.ICLabel.classifications(:,7) > .75);
        if file ==1
            COMPS_iCC(sub, 1) = length(c_brain);                                                    % brain
            COMPS_iCC(sub, 2) = length(c_eye);                                                      % eye
            COMPS_iCC(sub, 3) = length(c_muscle);                                                   % muscle
            COMPS_iCC(sub, 4) = length(c_line);                                                     % line noise
            COMPS_iCC(sub, 5) = length(c_others);                                                   % other
        
        elseif file == 2
            COMPS_trad(sub, 1) = length(c_brain);                                                   % brain
            COMPS_trad(sub, 2) = length(c_eye);                                                     % eye
            COMPS_trad(sub, 3) = length(c_muscle);                                                  % muscle
            COMPS_trad(sub, 4) = length(c_line);                                                    % line noise
            COMPS_trad(sub, 5) = length(c_others);                                                  % other

        end

        pop_viewprops(EEG, 0, [1:size(EEG.data, 1)], {'freqrange', [2 80]}, {}, 1, 'ICLabel')       % for component properties
        saveas(gca, [SUB(sub).ID, '_', iCC_cond, '-ICA-Topos.png']);                                % save plot
        close;

        EEG.badics = sort([c_eye; c_muscle; c_line; c_others])';                                    % save in EEG structure
        
        if contains(file_name, 'trad')
            SUB(sub).trad_badics = EEG.badics;                                                      % save in SUB structure, doesn't hurt
        elseif contains(file_name, 'iCC')
            SUB(sub).ICC_badics = EEG.badics;                                                       % save in SUB structure, doesn't hurt
        end


        SUBBADPATH = [SUBICAPATH, 'badICs\'];
        if ~isfolder(SUBBADPATH)
            mkdir(SUBBADPATH)
        end

        EEG.setname = [SUB(sub).ID, '_preproc-', iCC_cond, '-BadICs'];                              % new set name
        [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);                                           % save as new set
        EEG = pop_saveset(EEG, 'filename', EEG.setname, 'filepath', SUBBADPATH);                    % save data set
    end

end


COMPS = vertcat(COMPS_trad, COMPS_iCC);
types = {'ID','Pipeline', 'brain', 'eye', 'muscle', 'other'};
pipelines = {'trad','trad','trad','trad','trad','trad','trad','trad','trad','trad','trad','trad','trad','trad',...
    'ICC','ICC','ICC','ICC','ICC','ICC','ICC','ICC','ICC','ICC','ICC','ICC','ICC','ICC'}';

ids = [{SUB.ID}';{SUB.ID}'];

T = table(ids,pipelines, COMPS(:,1),COMPS(:,2),COMPS(:,3),COMPS(:,5), VariableNames=types);

save([MAINPATH,'SUBS'],'SUB');                                                                      % save information
writetable(T, [MAINPATH, 'COMP_stats.txt']);                                                             % save information


%% end

