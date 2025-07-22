%% duallayer2_gerd_02_iCanClean.m
%
%
%
%
% Author: Melanie, 2025

%% Preparations

close all; clear all; clc;                                                                          % start with fresh workspace

% set paths

MAINPATH = 'R:\Ferris-Lab\mklapprott\eegl\';                                                        % adjust this path to your local environment!!!
PATHIN = [MAINPATH, 'rawdata\gerd\'];                                                                % path to raw data (changed from task-Flanker!!!)
PATHOUT = [MAINPATH, 'derivatives\gerd\'];                                                           % path for data derivatives created on the way

CHECKPATH = [PATHOUT, 'duallayer2_gerd_01_first-Check\'];
ICCPATH = [PATHOUT, 'duallayer2_gerd_02_iCC\'];                                                      % path for ICC data 

if ~isfolder(ICCPATH)                                                                                % if the path doesn't exist yet, create it
    mkdir(ICCPATH)
end

file_paths = dir(fullfile(CHECKPATH));                                                               % get access to all folder names
file_paths(1:2) = [];                                                                                % first two entries in the struct are empty
file_paths(end) = [];                                                                                % get rid of plots folder


cd(MAINPATH)
measurement_info = readtable([MAINPATH, 'measurement_info.xlsx']);                                  % load initial info table
load('params.mat');                                                                                 % load params (written in duallayer2_gerd_00_configfiles.m)
load('MEAS.mat');                                                                                   % load info struct, which is extended with each script


[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;                                                            % start EEGLAB

%% start

for meas = 1:length(file_paths)

    SUBCHECKPATH = [CHECKPATH, file_paths(meas).name, '\'];
    cd(SUBCHECKPATH)                                                                                % set filepath
    files = dir(fullfile(SUBCHECKPATH, '*.set'));                                                   % get access to data sets

    file_name = files.name;                                                                         % get current file name
    EEG = pop_loadset('filename',file_name,'filepath',SUBCHECKPATH);
    
    % acutal iCanClean ---------------------------------------------------------------------------
    
    do_iCC = [false,true];                                                                          % add other options?
    
    for idx = 1:length(do_iCC)
        
        if do_iCC(idx)
            
            fprintf('==== %s STARTING: ICANCLEAN ====\n',EEG.setname);
            EEG_chans = find(strcmpi('EEG',{EEG.chanlocs.type}));                                   % get EEG channel indices
            Noise_chans = find(strcmpi('Noise',{EEG.chanlocs.type}));                               % get Noise channel indices          
            outputStr = evalc('EEG = iCanClean(EEG, EEG_chans, Noise_chans, 0, params);');          % perform iCanClean
            
            MEASICCPATH = [ICCPATH, char(measurement_info{meas, 'cond'}), '\'];                     % create path for measurement
    
            if ~isfolder(MEASICCPATH)
                mkdir(MEASICCPATH)
            end

            cd(MEASICCPATH);
            EEG = pop_saveset(EEG, 'filename', [EEG.setname, '_preproc-iCC_eeg'], 'filepath', MEASICCPATH);    % save data set
            
            MEASUREMENTS(meas).ICC_info = outputStr;                                                % save iCC info
            
        else
            
            fprintf('==== %s NO ICANCLEAN ====\n',EEG.setname);

            MEASNOICCPATH = [ICCPATH, char(measurement_info{meas, 'cond'}), '\'];                   % create path for measurement
    
            if ~isfolder(MEASNOICCPATH)
                mkdir(MEASNOICCPATH)
            end

            cd(MEASNOICCPATH);
            EEG = pop_saveset(EEG, 'filename', [EEG.setname, '_preproc-NOiCC_eeg'], 'filepath', MEASNOICCPATH);    % save data set

            
        end                                                                                         % end if-else deciding about preproc option
    end                                                                                             % end loop across preproc options
end                                                                                                 % end loop acrss measurements


disp('Dont forget about the struct!!!')                                                             % reminder :)

%% save information

save([MAINPATH,'MEAS'],'MEASUREMENTS');



