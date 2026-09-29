%% duallayer2_gerd_01_addNoise.m
%
% Description:
%   This script loads EEG recordings from a phantom head setup and generates 
%   multiple versions of each dataset with different types of added noise. 
%   These artificial noise conditions can later be used to evaluate preprocessing 
%   and artifact correction pipelines in EEGLAB.
%
%   Implemented noise conditions:
%     (1) No noise (clean reference)
%     (2) White + pink noise
%     (3) White + pink noise + simulated eye blinks
%     (4) White + pink noise + simulated eye blinks + simulated muscle activity
%
% Workflow:
%   - Define input/output paths and load measurement info
%   - Loop across measurement sessions
%   - For each session, create datasets with different noise conditions
%   - Save the resulting EEG datasets into structured output folders
%
% Inputs:
%   - EEG .set files located in PATHIN (phantom head recordings)
%   - 'measurement_info.xlsx' containing metadata
%   - 'check.mat' containing noise condition parameters (check.noise_conds, NOCHANS)
%   - Electrode location file 'DualLayer64.elp'
%
% Outputs:
%   - EEG datasets (.set) with noise added, stored in PATHOUT/duallayer2_gerd_00_Noise
%
% Dependencies:
%   - MATLAB Signal Processing Toolbox (for dsp.ColoredNoise, gausswin)
%   - EEGLAB (for EEG data loading, channel handling, and saving)
%
% Author: Melanie, 2025


%% Preparations

close all; clear all; clc;                                                                          % start with fresh workspace

% set paths

MAINPATH = 'R:\Ferris-Lab\mklapprott\eegl\';                                                        % adjust this path to your local environment!!!
cd(MAINPATH)

PATHIN = [MAINPATH, 'BIDS_PhantomHead\sub-1\'];                                                     % path to raw data
PATHOUT = [MAINPATH, 'derivatives\gerd\']; 
NOISEPATH = [MAINPATH, 'rawdata\gerd\'];

if ~isfolder(PATHOUT)                                                                               % if the path doesn't exist yet, create it
    mkdir(PATHOUT)
end

CHECKPATH = [PATHOUT, 'duallayer2_gerd_00_Noise\'];
if ~isfolder(CHECKPATH)                                                                             % if the path doesn't exist yet, create it
    mkdir(CHECKPATH)
end


file_paths = dir(fullfile(PATHIN));                                                                 % get access to all folder names
file_paths = file_paths(contains({file_paths.name}, 'ses'));
file_paths = file_paths(1:9, :);

% load parameters

measurement_info = readtable([MAINPATH, 'measurement_info.xlsx']);                                  % load initial info table
measurement_info = measurement_info(9:end, :);
load('check.mat');


%% start adding noise

for meas = 1:length(file_paths)

    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;                                                     % start EEGLAB

    % load phantom head data from Downey et al. (2023) to make some noise! -----------------------

    cd(NOISEPATH)

    files = dir(fullfile(NOISEPATH, '*.set'));                                                      % get access to data set
    file_name = files.name;

    EEG = pop_loadset([NOISEPATH, file_name]);                                                      % load data
    EEG = pop_resample( EEG, 250);
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );                                        % store in ALLEEG -> ALLEEG(1)

    go_labels = {'N-A1', 'N-A8', 'N-A15', 'N-A19', 'N-A21', 'N-A28', 'N-B2', 'N-B5', 'N-B10', ...
        'N-B12', 'N-B16', 'N-B23', 'N-B26', 'N-B27', 'N-B30', 'N-C2', 'N-C7', 'N-C10', 'N-C16', ...
        'N-C21', 'N-C29',  'N-C32', 'N-D2', 'N-D7', 'N-D8', 'N-D11', 'N-D16', 'N-D19', 'N-D23', ...
        'N-D26', 'N-D31', 'N-D32'};
    
    EEG = pop_select( EEG, 'channel',go_labels);                                                    % only keep EEG chans for ICA
    EEG = pop_eegfiltnew(EEG, 'locutoff', 1);                                                       % use HPF to remove drift
    EEG = pop_eegfiltnew(EEG, 'hicutoff', 30);                                                      % use HPF to smoothe data
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'gui','off'); 

    if meas == 2 || meas == 5                                                                       % adjust for motion intensity
        noise_data = EEG.data ./ 4;
    elseif meas == 4 || meas == 7
        noise_data = EEG.data ./ 2;
    else
        noise_data = EEG.data ./ 3;
    end

    % load data ----------------------------------------------------------------------------------

    PATHINSUB = [PATHIN, 'ses-', num2str(meas), '\eeg\'];
    cd(PATHINSUB)

    files = dir(fullfile(PATHINSUB, '*.set'));                                                      % get access to data sets
    file_name = files.name;

    EEG = pop_loadset([PATHINSUB, file_name]);                                                      % load data
    EEG = pop_chanedit(EEG, 'lookup',[MAINPATH, 'DualLayer64.elp']);
    EEG.setname = strjoin(['dualLayer2_', num2str(meas), '_', measurement_info{meas, 'cond'}],'');  % give data set a name

    EEG = pop_select( EEG, 'nochannel', check.NOCHANS);                                             % select relevant channels
    nchan = EEG.nbchan;                                                                             % update number of channels   

    EEG.setname = strjoin(['dualLayer2_', num2str(meas), '_', measurement_info{meas, 'cond'}],''); 

    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );                                        % store in ALLEEG

    % add noise ----------------------------------------------------------------------------------

    go_chans = EEG.chanlocs(strcmp({EEG.chanlocs.type},'EEG'));                                 % get EEG channels
    go_labels = {go_chans.labels};                                                              % get their labels

    pink = dsp.ColoredNoise('Color','pink','SamplesPerFrame',EEG.pnts,'NumChannels',length(go_labels));
    pink_noise = pink()';  % returns [nbchan × pnts] pink noise

    EEG.data(1:length(go_labels),:) = EEG.data(1:length(go_labels),:) + pink_noise * 2;

    if meas == 1
        EEG.data = EEG.data;                                                                        % don"t add any noise

    else
        if meas == 8 || meas ==9
            EEG = pop_select(EEG, 'point',[1 size(noise_data, 2)] );
        end

        noise_data = noise_data(:,1:size(EEG.data, 2));                                            % adjust data for dimensions     
        noise_data2 = noise_data(1:size(EEG.data, 1)-32,:);

        all_noise = cat(1, noise_data, noise_data2);   
        EEG.data = EEG.data + all_noise;                                                            % add noise to all electrodes!
    end
    

    % save data set ------------------------------------------------------------------------------

    SUBCHECKPATH = [CHECKPATH, strjoin([num2str(meas), '_', measurement_info{meas, 'cond'}],''), '\'];  % create path for condition
    
    if ~isfolder(SUBCHECKPATH)
        mkdir(SUBCHECKPATH);
    end

    cd(SUBCHECKPATH);
    EEG = pop_saveset(EEG, 'filename', EEG.setname, 'filepath', SUBCHECKPATH);                      % save data set
      
       
end                                                                                                 % end loop across measurements

%% end
