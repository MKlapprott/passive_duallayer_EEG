%% duallayer2_gerd_03_tryERP.m
%
%
%
%
% Author: Melanie, 2025

%% Preparations

close all; clear all; clc;                                                                          % start with fresh workspace

% set paths

MAINPATH = 'R:\Ferris-Lab\mklapprott\eegl\';                                % adjust this path to your local environment!!!
%cd(MAINPATH)

EEGLABPATH = 'R:\Ferris-Lab\share\shared software\eeglab2021.0\';
cd(EEGLABPATH)

PATHIN = [MAINPATH, 'rawdata\gerd\'];                                                                    % path to raw data (changed from task-Flanker!!!)
PATHOUT = [MAINPATH, 'derivatives\gerd\'];                                                               % path for data derivatives created on the way

CHECKPATH = [PATHOUT, 'duallayer2_gerd_01_first-Check\'];
EPOPATH = [PATHOUT, 'duallayer2_gerd_02_epo-erp\'];                                                     % path for SME epoch data 

if ~isfolder(EPOPATH)                                                                                % if the path doesn't exist yet, create it
    mkdir(EPOPATH)
end

ERPPLOTS = [EPOPATH, 'plots\'];                                                     % path for SME epoch data 

if ~isfolder(ERPPLOTS)                                                                                % if the path doesn't exist yet, create it
    mkdir(ERPPLOTS)
end

file_paths = dir(fullfile(CHECKPATH));                                                                  % get access to all folder names
file_paths(1:2) = [];                                                                                % in my matlab, the first two entries in the struct are empty


% load parameters

measurement_info = readtable([MAINPATH, 'measurement_info.xlsx']);  
EVENTS = measurement_info{9:end, 'event'};
load('erp.mat');  

%% start

for meas = 9:17

    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;                                                         % start EEGLAB

    SUBICAPATH = [CHECKPATH, file_paths(meas).name, '\'];

    cd(SUBICAPATH)                                                                                    % set filepath
    files = dir(fullfile(SUBICAPATH, '*.set'));                                                       % get access to data sets

    file_name = files.name;
    
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    EEG = pop_loadset('filename',file_name,'filepath',SUBICAPATH);

    nchan = EEG.nbchan;
  
    SUBEPOSME = [EPOPATH, char(measurement_info{meas, 'cond'}), '\'];
    mkdir(SUBEPOSME)

    %refchans = strmatch('TP', {EEG.chanlocs.labels});                                           % find mastoid electrodes
    EEG = pop_epoch( EEG, EVENTS, [erp.FROM erp.TO], 'epochinfo', 'yes');                           % cut SME-epochs from -.2 to 1.1 s
    EEG = pop_rmbase( EEG, [erp.FROM*1000 0] ,[]);                                                  % baseline correction                                                 % baseline correction

    EEG = pop_jointprob(EEG,1,[1:nchan] ,erp.REJ,erp.REJ,0,1,0,[],0);                                   % artefact correction using joint probabilities
    EEG = pop_rejkurt(EEG,1,[1:nchan] ,erp.REJ,erp.REJ,0,1,0,[],0);                                     % artefact correction using channel kurtosis
    EEG = pop_reref(EEG, []);                                                             % re-reference data to TP9 and TP10
    EEG.setname = [char(measurement_info{meas, 'cond'}), '_epochs'];                                % new set name
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);                                           % save as new set (ALLEEG)


    % Move on to ERP calculation -----------------------------------------------------------------

     N1_chan = find(strcmp('Fz', {EEG.chanlocs.labels}));
     P3_chan = find(strcmp('Pz', {EEG.chanlocs.labels}));
% 
%     N1_start_pos = find(EEG.times == N1_st);                                                    % P3 start timepoint on EEG.times
%     N1_stop_pos = find(EEG.times==N1_sp);                                                       % P3 stop timepoint on EEG.times
% 
%     P3_start_pos = find(EEG.times == P3_st);                                                    % P3 start timepoint on EEG.times
%     P3_stop_pos = find(EEG.times==P3_sp);                                                       % P3 stop timepoint on EEG.times
% 
%     chanERP_N1 = squeeze(mean(mean(EEG.data(N1_chan,N1_start_pos:N1_stop_pos,:),3),1));    
%     N1_amp = mean(chanERP_N1);
%     [~, N1_lat] = min(chanERP_N1);
% 
%     SUB(sub).ERP_pre_hit = chanERP_N1;
%     GA_pre_hit(:,:,sub) = chanERP_N1;


    % save plots ---------------------------------------------------------------------------------

    subplot(1,2,1)
    plot(EEG.times, mean(EEG.data(N1_chan,:,:),3))
    xlabel('time [ms]')
    ylabel('Amplitude [µV]')
    ylim([-5,5])
    title('Fz')
    
    subplot(122)
    plot(EEG.times, mean(EEG.data(P3_chan,:,:),3))
    xlabel('time [ms]')
    ylabel('Amplitude [µV]')
    ylim([-5,5])
    title('Pz')

    sgtitle(char(measurement_info{meas, 'cond'}), 'Interpreter', 'none')
    
    cd(ERPPLOTS);
    saveas(gca, [char(measurement_info{meas, 'cond'}), '-ERP.png']);                                                % save plot
    cd(SUBEPOSME);
    EEG = pop_saveset(EEG, 'filename', [EEG.setname], 'filepath', SUBEPOSME);      % save data set

    


end

