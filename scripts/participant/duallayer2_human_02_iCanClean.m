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

MAINPATH = 'R:\Ferris-Lab\mklapprott\eegl\';                                                        % adjust this path to your local environment!!!
PATHIN = [MAINPATH, 'rawdata\participants\'];                                                       % path to raw data (changed from task-Flanker!!!)
PATHOUT = [MAINPATH, 'derivatives\participants\'];                                                  % path for data derivatives created on the way

CHECKPATH = [PATHOUT, 'duallayer2_human_01_first-Check\'];
ICCPATH = [PATHOUT, 'duallayer2_human_02_iCC\'];                                                    % path for ICC data 

if ~isfolder(ICCPATH)                                                                                % if the path doesn't exist yet, create it
    mkdir(ICCPATH)
end

file_paths = dir(fullfile(CHECKPATH));                                                               % get access to all folder names
file_paths(1:2) = [];                                                                                % first two entries in the struct are empty
file_paths(3) = [];                                                                                 % get rid of plots folder


cd(MAINPATH)
measurement_info = readtable([MAINPATH, 'participant_info.xlsx']);                                  % load initial info table
load('check.mat');                                                                                  % load parameters containing info about noise
load('params.mat');                                                                                 % load params (written in duallayer2_gerd_00_configfiles.m)
load('SUBS.mat');                                                                                   % load info struct, which is extended with each script


%% start

for sub = 14%:length(SUB)

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
            
            fprintf('==== %s STARTING: ICANCLEAN ====\n',EEG.setname);
            EEG_chans = find(strcmpi('EEG',{EEG.chanlocs.type}));                                   % get EEG channel indices
            Noise_chans = find(strcmpi('Noise',{EEG.chanlocs.type}));                               % get Noise channel indices          
            
            outputStr = evalc('EEG = iCanClean(EEG, EEG_chans, Noise_chans, 0, params);');          % perform iCanClean

            cd(SUBICCPATH);
            EEG = pop_saveset(EEG, 'filename', [EEG.setname, '_preproc-iCC_eeg'], 'filepath', SUBICCPATH);    % save data set

            disp(['Saving data for ', EEG.setname, '_preproc-iCC_eeg'])
            
            SUB(sub).ICC_info = outputStr;                                                          % save iCC info
            
        elseif ~do_iCC(idx)
            
            fprintf('==== %s NO ICANCLEAN ====\n',EEG.setname);

            cd(SUBICCPATH);
            EEG = pop_saveset(EEG, 'filename', [EEG.setname, '_preproc-trad_eeg'], 'filepath', SUBICCPATH);    % save data set

            disp(['Saving data for ', EEG.setname, '_preproc-trad_eeg'])
            
        end                                                                                         % end if-else deciding about preproc option
    end                                                                                             % end loop across preproc options

end                                                                                                 % end loop acrss measurements

save([MAINPATH,'SUBS'],'SUB');                                                                      % save information

%% end
%% Preparations

close all; clear all; clc;                                                                          % start with fresh workspace

% set paths

MAINPATH = 'R:\Ferris-Lab\mklapprott\eegl\';                                                        % adjust this path to your local environment!!!
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


%% Preparations

close all; clear all; clc;                                                                          % start with fresh workspace

% set paths

MAINPATH = 'R:\Ferris-Lab\mklapprott\eegl\';                                                        % adjust this path to your local environment
PATHOUT = [MAINPATH, 'derivatives\participants\'];                                                  % path for data derivatives created on the way
ICAPATH = [PATHOUT, 'duallayer2_human_03_iCA\'];                                                    % path for ICA data 

cd(MAINPATH)
load('SUBS.mat');                                                                                   % load info struct, which is extended with each script


%%

for sub = 12:length(SUB)

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
        c_eye = find(EEG.etc.ic_classification.ICLabel.classifications(:,3) > .75);
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
types = {'Pipeline', 'brain', 'eye', 'muscle', 'other'};
% 
% pipelines = {'trad','trad','trad','trad','trad','trad',...
%     'ICC','ICC','ICC','ICC','ICC','ICC'}';

pipelines = {'trad','trad','trad','trad','trad','trad','trad','trad','trad','trad','trad','trad','trad',...
    'ICC','ICC','ICC','ICC','ICC','ICC','ICC','ICC','ICC','ICC','ICC','ICC','ICC'}';

T = table(pipelines, COMPS(:,1),COMPS(:,2),COMPS(:,3),COMPS(:,5), VariableNames=types);

save([MAINPATH,'SUBS'],'SUB');                                                                      % save information
writetable(T, [MAINPATH, 'COMP_stats.txt']);                                                             % save information


%% Preparations

clear all; close all; clc;

MAINPATH = 'R:\Ferris-Lab\mklapprott\eegl\';                                                        % adjust this path to your local environment!!!
PATHIN = [MAINPATH, 'rawdata\participants\'];
PATHOUT = [MAINPATH, 'derivatives\participants\'];
ICAPATH = [PATHOUT, 'duallayer2_human_03_iCA\'];                                                    % path for ICA data 

ICCPATH = [PATHOUT, 'duallayer2_human_04_iCC_ICA-corr\'];                                           % path for ICC & ICA corrected data data 

if ~isfolder(ICCPATH)                                                                               % if the path doesn't exist yet, create it
    mkdir(ICCPATH)
end

SPLITPATH = [PATHOUT, 'duallayer2_human_05_splitdata\'];                                            % path for ICA data 

if ~isfolder(SPLITPATH)                                                                             % if the path doesn't exist yet, create it
    mkdir(SPLITPATH)
end

cd(MAINPATH)
subs_info = readtable([MAINPATH, 'participant_info.xlsx']);
conds = table2cell(subs_info(:,4:8));                                                               % extract conditions
load('check.mat');
load('params.mat');
load('SUBS.mat');


%% Start loading & re-running iCanClean + applying ICA weights


for sub = 1:length(SUB)

    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;                                                     % start EEGLAB

    SUBICAPATH = [ICAPATH, SUB(sub).ID, '\badICs\'];                                                % go to ICA path
    cd(SUBICAPATH)
    ica_files = dir( fullfile( SUBICAPATH,'\*.set'));                                               % listing data sets
    
    for idx = 1:2
        EEG = pop_loadset([SUBICAPATH, ica_files(idx).name]);                                       % load files with ICA weights & bad components
        [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);                                         % store data set
    end


    SUBPATH = [PATHIN, SUB(sub).ID, '\'];                                                           % go to raw data path for re-processing data
    cd(SUBPATH)
    cur_file = dir( fullfile( SUBPATH,'\*.xdf'));                                                   % listing data sets
    
    SUBICCPATH = [ICCPATH, SUB(sub).ID, '\'];                                                       % create path subject iCC+ICA
    
    if ~isfolder(SUBICCPATH)
        mkdir(SUBICCPATH)
    end

    do_iCC = [true, false];                                                                         % one line with and one line without iCanClean

    for idx = 1:length(do_iCC)                                                                      % loop across the two processing lines
        
        if do_iCC(idx)

            % data preparation -------------------------------------------------------------------

            if strcmp(SUB(sub).ID, 'sub_03')
        
                for file = 1:length(cur_file)
                    file_name = cur_file(file).name;
                
                    EEG = pop_loadxdf([SUBPATH, file_name], 'streamtype', 'EEG', 'exclude_markerstreams', {});    % load data
                    EEG = pop_chanedit(EEG, 'lookup',[MAINPATH, 'DualLayer64.elp']);
                    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG);                                        % store data set
                end
                
                EEG = pop_mergeset( ALLEEG, [5  4  3], 0); 
            else
            
                EEG = pop_loadxdf([SUBPATH, cur_file.name]);                                            % load
                EEG = pop_chanedit(EEG, 'lookup',[MAINPATH, 'DualLayer64.elp']);                        % add channel locations
                EEG.setname = ['dualLayer2_', num2str(sub), '_', SUB(sub).ID];                      % give data set a name
            end
        
            [EEG.chanlocs(find(contains({EEG.chanlocs.labels}, 'R'))).type] = deal('Noise');        % assign the Noise label to the Noise electrodes
            [EEG.chanlocs(find(~contains({EEG.chanlocs.labels}, 'R'))).type] = deal('EEG');         % assign the EEG label to the EEG electrodes
            [EEG.chanlocs(find(contains({EEG.chanlocs.labels}, 'Acc'))).type] = deal('MISC');       % assign the MISC label to the IMU channels
            [EEG.chanlocs(find(contains({EEG.chanlocs.labels}, 'Gyro'))).type] = deal('MISC');      % assign the MISC label to the IMU channels
            [EEG.chanlocs(find(contains({EEG.chanlocs.labels}, 'Quat'))).type] = deal('MISC');      % assign the MISC label to the IMU channels

            all_starts = find(strcmp({EEG.event.type}, '1 instruction'));
            all_ends = find(strcmp({EEG.event.type}, '5 end_block'));
        
            if length(all_starts) > 4 && length(all_ends) > 4                                       % if there are more events than intended
                EEG.event(all_starts(3):all_ends(3)) = [];                                          % kick them out        
            end
        
            EEG = pop_eegfiltnew(EEG, 'locutoff', check.HPF);                                       % high-pass filter

            EEG.urchanlocs = EEG.chanlocs(1:32);                                                    % save scalp chanlocs for later
        
            [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);                                     % store data set
        
            rej_chans = [SUB(sub).rej_EEGchans, SUB(sub).rej_Noisechans];
            EEG.badchans = SUB(sub).rej_EEGchans;

            if strcmp(SUB(sub).ID, 'pilot_04') || strcmp(SUB(sub).ID, 'sub_05')                     % here, C4 is a flat channel
                rej_chans = [rej_chans, find(strcmp({EEG.chanlocs.labels}, 'C4'))];
            end

            EEG = pop_select(EEG, 'nochannel', sort(rej_chans));

             % ICC -------------------------------------------------------------------------------
            
            fprintf('==== %s STARTING: ICANCLEAN ====\n',EEG.setname);
            EEG_chans = find(strcmpi('EEG',{EEG.chanlocs.type}));                                   % get EEG channel indices
            Noise_chans = find(strcmpi('Noise',{EEG.chanlocs.type}));                               % get Noise channel indices          
            
            EEG = iCanClean(EEG, EEG_chans, Noise_chans, 0, params);                                % perform iCanClean

            % apply ICA weights ------------------------------------------------------------------

            go_chans = EEG.chanlocs(strcmp({EEG.chanlocs.type},'EEG'));                             % mark EEG channels
            go_labels = {go_chans.labels};       
            EEG = pop_select( EEG, 'channel',go_labels);                                            % only keep EEG channels
            [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);                                     % store data set

            EEG = pop_editset(EEG, 'run', [], 'icaweights', 'ALLEEG(1).icaweights', 'icasphere', 'ALLEEG(1).icasphere'); % apply weights from ALLEEG(1) on this data set
            EEG.setname = [EEG.setname, '_ICC-ICAweights'];
            [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
        
            % remove bad components --------------------------------------------------------------

            EEG.badics = ALLEEG(1).badics;                                                          % get bad ICs
            
            if ~isempty(EEG.badics)                                                                 % if bad ICs, remove them from data
                EEG = pop_subcomp( EEG,EEG.badics, 0, 0);
                disp(['Removing components: ', mat2str(EEG.badics)])
            end
    
            try
                if ~isempty(EEG.badchans)                                                           % if there are bad channels...   
                    EEG = pop_interp(EEG, EEG.urchanlocs , 'spherical');                            % and interpolate them using urchanlocs        
                end
            end
 
            % save data set ----------------------------------------------------------------------

            cd(SUBICCPATH);
            EEG = pop_saveset(EEG, 'filename', ['dualLayer2_', num2str(sub), '_', SUB(sub).ID, '_ICC-ICAcorr'], 'filepath', SUBICCPATH); % save data set

        else                                                                                        % repeat the procedure without iCanClean
            
            fprintf('==== %s NO ICANCLEAN ====\n',EEG.setname);
            
            % data preparation -------------------------------------------------------------------
            
            if strcmp(SUB(sub).ID, 'sub_03')
        
                for file = 1:length(cur_file)
                    file_name = cur_file(file).name;
                
                    EEG = pop_loadxdf([SUBPATH, file_name], 'streamtype', 'EEG', 'exclude_markerstreams', {});    % load data
                    EEG = pop_chanedit(EEG, 'lookup',[MAINPATH, 'DualLayer64.elp']);
                    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG);                                        % store data set
                end
                
                EEG = pop_mergeset( ALLEEG, [11  10  9], 0); 
            else
            
                EEG = pop_loadxdf([SUBPATH, cur_file.name]);                                        % load
                EEG = pop_chanedit(EEG, 'lookup',[MAINPATH, 'DualLayer64.elp']);                    % add channel locations
                EEG.setname = ['dualLayer2_', num2str(sub), '_', SUB(sub).ID];                      % give data set a name
            end
        
        
            [EEG.chanlocs(find(contains({EEG.chanlocs.labels}, 'R'))).type] = deal('Noise');        % assign the Noise label to the Noise electrodes
            [EEG.chanlocs(find(~contains({EEG.chanlocs.labels}, 'R'))).type] = deal('EEG');         % assign the EEG label to the EEG electrodes
            [EEG.chanlocs(find(contains({EEG.chanlocs.labels}, 'Acc'))).type] = deal('MISC');       % assign the MISC label to the IMU channels
            [EEG.chanlocs(find(contains({EEG.chanlocs.labels}, 'Gyro'))).type] = deal('MISC');      % assign the MISC label to the IMU channels
            [EEG.chanlocs(find(contains({EEG.chanlocs.labels}, 'Quat'))).type] = deal('MISC');      % assign the MISC label to the IMU channels

            all_starts = find(strcmp({EEG.event.type}, '1 instruction'));
            all_ends = find(strcmp({EEG.event.type}, '5 end_block'));

            if length(all_starts) > 4 && length(all_ends) > 4                                       % if there are more events than intended
                EEG.event(all_starts(3):all_ends(3)) = [];                                          % kick them out        
            end
        
            EEG = pop_eegfiltnew(EEG, 'locutoff', check.HPF);                                       % high-pass filter

            EEG.urchanlocs = EEG.chanlocs(1:32);                                                    % save scalp chanlocs for later
        
            [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);                                     % store data set
        
            rej_chans = [SUB(sub).rej_EEGchans, SUB(sub).rej_Noisechans];
            EEG.badchans = SUB(sub).rej_EEGchans;
            EEG = pop_select(EEG, 'nochannel', sort(rej_chans));

            % NO ICC -----------------------------------------------------------------------------
            % apply ICA weights ------------------------------------------------------------------

            go_chans = EEG.chanlocs(strcmp({EEG.chanlocs.type},'EEG'));                             % mark EEG channels
            go_labels = {go_chans.labels};       
            EEG = pop_select( EEG, 'channel',go_labels);                                            % only keep EEG channels
            [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);                                     % store data set

            EEG = pop_editset(EEG, 'run', [], 'icaweights', 'ALLEEG(2).icaweights', 'icasphere', 'ALLEEG(2).icasphere'); % apply weights from ALLEEG(1) on this data set
            EEG.setname = [EEG.setname, '_trad-ICAweights'];
            [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
        
            % remove bad components --------------------------------------------------------------
            
            EEG.badics = ALLEEG(2).badics;                                                          % get bad ICs
            
            if ~isempty(EEG.badics)                                                                 % if bad ICs, remove them from data
                EEG = pop_subcomp( EEG,EEG.badics, 0, 0);
                disp(['Removing components: ', mat2str(EEG.badics)])
            end
    
            try
                if ~isempty(EEG.badchans)                                                           % if there are bad channels...   
                    EEG = pop_interp(EEG, EEG.urchanlocs , 'spherical');                            % and interpolate them using urchanlocs        
                end
            end
 
            EEG.setname = ['dualLayer2_', num2str(sub), '_', SUB(sub).ID, '_trad-ICAcorr'];
            [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);

            cd(SUBICCPATH);
            EEG = pop_saveset(EEG, 'filename', EEG.setname, 'filepath', SUBICCPATH);                % save data set
            
        end                                                                                         % end if-else deciding about preproc option
    end                                                                                             % end loop across preproc options

end

%% split data 
% load ICA cleaned no ICC and ICC and split the data from there

for sub = 12:length(SUB)

    SUBICCPATH = [ICCPATH, SUB(sub).ID, '\'];
    cd(SUBICCPATH)                                                                                  % set filepath
    files = dir(fullfile(SUBICCPATH, '*.set'));                                                     % get access to data sets

    for file = 1:length(files)

        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;                                                    % start EEGLAB

        file_name = files(file).name;                                                               % get current file name
        EEG = pop_loadset('filename',file_name,'filepath',SUBICCPATH);
        EEG = pop_eegfiltnew(EEG, 'hicutoff', check.LPF);                                           % low-pass filter
        [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);                                         % store data set


        % start sorting  data --------------------------------------------------------------------
        
        all_starts = find(strcmp({EEG.event.type}, '1 instruction'));                               % all start triggers
        all_ends = find(strcmp({EEG.event.type}, '5 end_block'));                                   % all end triggers

        if strcmp(SUB(sub).ID, 'sub_03')                                                            % the special snowflake :')
            all_ends = [all_ends(1), 303, all_ends(2), all_ends(3)];
        end
    
        SUBSPLITPATH = [SPLITPATH, SUB(sub).ID, '\'];
        if ~isfolder(SUBSPLITPATH)                                                                  % if the path doesn't exist yet, create it
            mkdir(SUBSPLITPATH)
        end
        cd(SUBSPLITPATH)

        if contains(file_name, 'trad')
            cond = 'trad';
        elseif contains(file_name, 'ICC')
            cond = 'ICC';
        end
    
        % sort single task oddball & dual task conditions ----------------------------------------

        EEG = pop_select( ALLEEG(1), 'point',[ALLEEG(1).event(all_starts(1)).latency-10 ALLEEG(1).event(all_ends(1)).latency+10] );
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname', ...
            ['dualLayer2_', num2str(sub), '_', SUB(sub).ID, '_', cond, '-ICAcorr_run-1_cond-', conds{sub, 1}'], 'gui','off'); 
        EEG = pop_saveset(EEG, 'filename', EEG.setname, 'filepath', SUBSPLITPATH); 
    
        EEG = pop_select( ALLEEG(1), 'point',[ALLEEG(1).event(all_starts(2)).latency-10 ALLEEG(1).event(all_ends(2)).latency+10] );
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname', ...
            ['dualLayer2_', num2str(sub), '_', SUB(sub).ID, '_', cond, '-ICAcorr_run-2_cond-', conds{sub, 2}'], 'gui','off'); 
        EEG = pop_saveset(EEG, 'filename', EEG.setname, 'filepath', SUBSPLITPATH); 
    
        EEG = pop_select( ALLEEG(1), 'point',[ALLEEG(1).event(all_starts(3)).latency-10 ALLEEG(1).event(all_ends(3)).latency+10] );
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname', ...
            ['dualLayer2_', num2str(sub), '_', SUB(sub).ID, '_', cond, '-ICAcorr_run-4_cond-', conds{sub, 4}'], 'gui','off');  
        EEG = pop_saveset(EEG, 'filename', EEG.setname, 'filepath', SUBSPLITPATH)
    
        EEG = pop_select( ALLEEG(1), 'point',[ALLEEG(1).event(all_starts(4)).latency-10 ALLEEG(1).event(all_ends(4)).latency+10] );
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname', ...
            ['dualLayer2_', num2str(sub), '_', SUB(sub).ID, '_', cond, '-ICAcorr_run-5_cond-', conds{sub, 5}'], 'gui','off'); 
        EEG = pop_saveset(EEG, 'filename', EEG.setname, 'filepath', SUBSPLITPATH); 

    end                                                                                             % end loop across ICC / noICC files    
end                                                                                                 % end loop across subs


%% end
%% Preparations

clear all; close all; clc;

MAINPATH = 'R:\Ferris-Lab\mklapprott\eegl\';                                                        % adjust this path to your local environment!!!
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

for sub = 12:length(SUB)

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
            
            EEG.setname = ['dualLayer2_', num2str(sub), '_', SUB(sub).ID, '_', cond, '_run-', ...
                num2str(erp.runs(file)),'_', mocond, '-epo'];                                       % new set name
            [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);                                       % save as new set (ALLEEG)
    
            SUBEPOPATH = [EPOPATH, SUB(sub).ID, '\'];
    
            if ~isfolder(SUBEPOPATH)                                                                % if the path doesn't exist yet, create it
                mkdir(SUBEPOPATH)
            end
    
            cd(SUBEPOPATH)
            
             for e = 1:length(erp.EVENTS)                                                           % go through event names
        
                EEG = pop_selectevent(ALLEEG(2), 'latency','-2<=2','type',...                       % select events
                    {erp.EVENTS{e}},'deleteevents','off','deleteepochs','on','invertepochs','off');
    
                [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);                                   % save as new set (ALLEEG)
                EEG.setname = ['dualLayer2_', num2str(sub), '_', SUB(sub).ID, '_', cond, '_run-', ...
                num2str(erp.runs(file)),'_', mocond, '-epo-', erp.events_save{e}];                  % store as separate set
                EEG = pop_saveset(EEG, 'filename', [EEG.setname], 'filepath', SUBEPOPATH);          % save data set
            
             end
    
             SUB(sub).stas(file) = size(ALLEEG(3).data, 3);
             SUB(sub).tars(file) = size(ALLEEG(4).data, 3);
            

        end
    end
end


save([MAINPATH,'SUBS'],'SUB');                                                                      % save information


%% end







