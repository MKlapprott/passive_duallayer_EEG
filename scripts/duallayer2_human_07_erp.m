%% duallayer2_human_07_erp.m
%
% Description:
%   This script extracts ERP (Event-Related Potential) measures from previously 
%   epoched EEG datasets. It organizes data by condition (stay/walk), stimulus 
%   type (standard/target), and preprocessing method (ICC/trad). Metrics include 
%   peak amplitude, latency, topography, and signal-to-noise ratio.
%
% Workflow:
%   - Load epoched EEG datasets (from duallayer2_human_06_epo)
%   - Identify channel Pz for ERP analyses
%   - Concatenate first and second runs for each condition
%   - Compute mean ERP waveforms per condition and participant
%   - Extract peak amplitudes and latencies in P3 window (erp.P3_st to erp.P3_sp)
%   - Compute topography at target peak latencies
%   - Calculate signal-to-noise ratio for each ERP
%   - Save ERP data structure and summary statistics table
%
% Inputs:
%   - Epoched EEG datasets (dualLayer2_human_06_epo)
%   - ERP parameters (erp.mat)
%   - SUBS.mat containing participant info
%
% Outputs:
%   - ERP structure with amplitude, latency, topography, and SNR metrics per participant
%   - Updated SUBS.mat
%   - Summary table 'ERP_stats.xlsx' with ERP metrics
%
% Dependencies:
%   - EEGLAB
%   - pm_ref_snr (custom SNR function)
%
%
% Author: Melanie, 2025

%% Preparations

clear all; close all; clc;

MAINPATH = 'R:\Ferris-Lab\mklapprott\eegl\';                                                        % adjust this path to your local environment!!!
PATHIN = [MAINPATH, 'rawdata\participants\'];
PATHOUT = [MAINPATH, 'derivatives\participants\'];

SPLITPATH = [PATHOUT, 'duallayer2_human_05_splitdata\'];                                            % path for split data 
EPOPATH = [PATHOUT, 'duallayer2_human_06_epo\'];                                                    % path for epoched data 


cd(MAINPATH)
load('SUBS.mat');
load('erp.mat');
load('ERP_info.mat');

%% start collecting information for ERP metrics calculation

for sub = 14%:length(SUB)

    if strcmp(SUB(sub).ID, 'sub_03')
        disp('Skipping')
    else

        SUBEPOPATH = [EPOPATH, SUB(sub).ID, '\'];
        cd(SUBEPOPATH)                                                                                  % set filepath
        files = dir(fullfile(SUBEPOPATH, '*.set'));                                                     % get access to data sets
    
        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;                                                        % start EEGLAB
    
        for file = 1:length(files)
    
            file_name = files(file).name;                                                               % get current file name
            EEG = pop_loadset('filename',file_name,'filepath',SUBEPOPATH);
            %EEG = pop_eegfiltnew(EEG, 'hicutoff', 10);                                       % high-pass filter
            [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);                                         % store data set
    
            SUB(sub).chanPz(file) = find(strcmp({EEG.chanlocs.labels}, 'Pz'));                          % get index for channel Pz
    
            if contains(file_name, 'stay') && contains(file_name, 'standard') && contains(file_name, 'ICC')
                if file < 5
                    ERP(sub).ICC_sta_stand1 = EEG.data;
                else
                    ERP(sub).ICC_sta_stand2 = EEG.data;
                    
                end
    
            elseif contains(file_name, 'stay') && contains(file_name, 'target') && contains(file_name, 'ICC')
                if file < 5
                    ERP(sub).ICC_tar_stand1 = EEG.data;
                else
                    ERP(sub).ICC_tar_stand2 = EEG.data;
                end
    
            elseif contains(file_name, 'walk') && contains(file_name, 'standard') && contains(file_name, 'ICC')
                if file < 5
                    ERP(sub).ICC_sta_walk1 = EEG.data;
                else
                    ERP(sub).ICC_sta_walk2 = EEG.data;
                end
    
            elseif contains(file_name, 'walk') && contains(file_name, 'target') && contains(file_name, 'ICC')
                if file < 5
                    ERP(sub).ICC_tar_walk1 = EEG.data;
                else
                    ERP(sub).ICC_tar_walk2 = EEG.data;
                end
    
            % NO ICC ---------------------------------------------------------------------------------    
            elseif contains(file_name, 'stay') && contains(file_name, 'standard') && contains(file_name, 'trad')
                if file < 13
                    ERP(sub).trad_sta_stand1 = EEG.data;
                else
                    ERP(sub).trad_sta_stand2 = EEG.data;
                end
    
            elseif contains(file_name, 'stay') && contains(file_name, 'target') && contains(file_name, 'trad')
                if file < 13
                    ERP(sub).trad_tar_stand1 = EEG.data;
                else
                    ERP(sub).trad_tar_stand2 = EEG.data;
                end
    
            elseif contains(file_name, 'walk') && contains(file_name, 'standard') && contains(file_name, 'trad')
                if file < 13
                    ERP(sub).trad_sta_walk1 = EEG.data;
                else
                    ERP(sub).trad_sta_walk2 = EEG.data;
                end
    
            elseif contains(file_name, 'walk') && contains(file_name, 'target') && contains(file_name, 'trad')
                if file < 13
                    ERP(sub).trad_tar_walk1 = EEG.data;
                else
                    ERP(sub).trad_tar_walk2 = EEG.data;
                end
    
            end
            
        end
    
        ERP(sub).times = EEG.times;
        ERP(sub).chanlocs = EEG.chanlocs;
    
        % combine first and second runs --------------------------------------------------------------
    
        ERP(sub).ICC_sta_stand = cat(3, ERP(sub).ICC_sta_stand1, ERP(sub).ICC_sta_stand2);
        ERP(sub).ICC_tar_stand = cat(3, ERP(sub).ICC_tar_stand1, ERP(sub).ICC_tar_stand2);
        ERP(sub).ICC_sta_walk = cat(3, ERP(sub).ICC_sta_walk1, ERP(sub).ICC_sta_walk2);
        ERP(sub).ICC_tar_walk = cat(3, ERP(sub).ICC_tar_walk1, ERP(sub).ICC_tar_walk2);
    
        ERP(sub).trad_sta_stand = cat(3, ERP(sub).trad_sta_stand1, ERP(sub).trad_sta_stand2);
        ERP(sub).trad_tar_stand = cat(3, ERP(sub).trad_tar_stand1, ERP(sub).trad_tar_stand2);
        ERP(sub).trad_sta_walk = cat(3, ERP(sub).trad_sta_walk1, ERP(sub).trad_sta_walk2);
        ERP(sub).trad_tar_walk = cat(3, ERP(sub).trad_tar_walk1, ERP(sub).trad_tar_walk2);
    
    
        ERP(sub).ICC_sta_stand_erp = ERP(sub).ICC_sta_stand(SUB(sub).chanPz(file), :,:);
        ERP(sub).ICC_tar_stand_erp = ERP(sub).ICC_tar_stand(SUB(sub).chanPz(file), :,:);
        ERP(sub).ICC_sta_walk_erp = ERP(sub).ICC_sta_walk(SUB(sub).chanPz(file), :,:);
        ERP(sub).ICC_tar_walk_erp = ERP(sub).ICC_tar_walk(SUB(sub).chanPz(file), :,:);
    
        ERP(sub).trad_sta_stand_erp = ERP(sub).trad_sta_stand(SUB(sub).chanPz(file), :,:);
        ERP(sub).trad_tar_stand_erp = ERP(sub).trad_tar_stand(SUB(sub).chanPz(file), :,:);
        ERP(sub).trad_sta_walk_erp = ERP(sub).trad_sta_walk(SUB(sub).chanPz(file), :,:);
        ERP(sub).trad_tar_walk_erp = ERP(sub).trad_tar_walk(SUB(sub).chanPz(file), :,:);
    
        % get ERP metrics (amp & lat)  ---------------------------------------------------------------
    
        ERP(sub).ICC_sta_stand_mean = mean(ERP(sub).ICC_sta_stand_erp, 3);
        ERP(sub).ICC_tar_stand_mean = mean(ERP(sub).ICC_tar_stand_erp, 3);
        ERP(sub).ICC_sta_walk_mean = mean(ERP(sub).ICC_sta_walk_erp, 3);
        ERP(sub).ICC_tar_walk_mean = mean(ERP(sub).ICC_tar_walk_erp, 3);
    
        ERP(sub).trad_sta_stand_mean = mean(ERP(sub).trad_sta_stand_erp, 3);
        ERP(sub).trad_tar_stand_mean = mean(ERP(sub).trad_tar_stand_erp, 3);
        ERP(sub).trad_sta_walk_mean = mean(ERP(sub).trad_sta_walk_erp, 3);
        ERP(sub).trad_tar_walk_mean = mean(ERP(sub).trad_tar_walk_erp, 3);
    
    
        P3_st = find(EEG.times == erp.P3_st);
        P3_sp = find(EEG.times == erp.P3_sp);
    
        ERP(sub).ICC_sta_stand_peak                           = max(ERP(sub).ICC_sta_stand_mean(P3_st:P3_sp));
        [ERP(sub).ICC_tar_stand_peak, ICC_tar_stand_time]     = max(ERP(sub).ICC_tar_stand_mean(P3_st: P3_sp));
        ERP(sub).ICC_sta_walk_peak                            = max(ERP(sub).ICC_sta_walk_mean(P3_st: P3_sp));
        [ERP(sub).ICC_tar_walk_peak, ICC_tar_walk_time]       = max(ERP(sub).ICC_tar_walk_mean(P3_st: P3_sp));
    
        ERP(sub).trad_sta_stand_peak                         = max(ERP(sub).trad_sta_stand_mean(P3_st: P3_sp));
        [ERP(sub).trad_tar_stand_peak, trad_tar_stand_time] = max(ERP(sub).trad_tar_stand_mean(P3_st: P3_sp));
        ERP(sub).trad_sta_walk_peak                          = max(ERP(sub).trad_sta_walk_mean(P3_st: P3_sp));
        [ERP(sub).trad_tar_walk_peak, trad_tar_walk_time]   = max(ERP(sub).trad_tar_walk_mean(P3_st: P3_sp));
    
        ERP(sub).ICC_tar_stand_lat = EEG.times(P3_st + ICC_tar_stand_time);
        ERP(sub).ICC_tar_walk_lat = EEG.times(P3_st + ICC_tar_walk_time);
    
        ERP(sub).trad_tar_stand_lat = EEG.times(P3_st + trad_tar_stand_time);
        ERP(sub).trad_tar_walk_lat = EEG.times(P3_st + trad_tar_walk_time);
    
        ERP(sub).ICC_sta_stand_amp = mean(ERP(sub).ICC_sta_stand_mean(P3_st:P3_sp));
        ERP(sub).ICC_tar_stand_amp = mean(ERP(sub).ICC_tar_stand_mean(P3_st: P3_sp));
        ERP(sub).ICC_sta_walk_amp = mean(ERP(sub).ICC_sta_walk_mean(P3_st: P3_sp));
        ERP(sub).ICC_tar_walk_amp = mean(ERP(sub).ICC_tar_walk_mean(P3_st: P3_sp));
    
        ERP(sub).trad_sta_stand_amp = mean(ERP(sub).trad_sta_stand_mean(P3_st: P3_sp));
        ERP(sub).trad_tar_stand_amp = mean(ERP(sub).trad_tar_stand_mean(P3_st: P3_sp));
        ERP(sub).trad_sta_walk_amp = mean(ERP(sub).trad_sta_walk_mean(P3_st: P3_sp));
        ERP(sub).trad_tar_walk_amp = mean(ERP(sub).trad_tar_walk_mean(P3_st: P3_sp));
    
        % get topography metrics ---------------------------------------------------------------------
    
        ERP(sub).ICC_sta_stand_topo = mean(ERP(sub).ICC_sta_stand(:,find(EEG.times == ERP(sub).ICC_tar_stand_lat), :), 3);
        ERP(sub).ICC_tar_stand_topo = mean(ERP(sub).ICC_tar_stand(:,find(EEG.times == ERP(sub).ICC_tar_stand_lat), :), 3);
        ERP(sub).ICC_sta_walk_topo = mean(ERP(sub).ICC_sta_walk(:,find(EEG.times == ERP(sub).ICC_tar_walk_lat), :), 3);
        ERP(sub).ICC_tar_walk_topo = mean(ERP(sub).ICC_tar_walk(:,find(EEG.times == ERP(sub).ICC_tar_walk_lat), :), 3);
    
        ERP(sub).trad_sta_stand_topo = mean(ERP(sub).trad_sta_stand(:,find(EEG.times == ERP(sub).trad_tar_stand_lat), :), 3);
        ERP(sub).trad_tar_stand_topo = mean(ERP(sub).trad_tar_stand(:,find(EEG.times == ERP(sub).trad_tar_stand_lat), :), 3);
        ERP(sub).trad_sta_walk_topo = mean(ERP(sub).trad_sta_walk(:,find(EEG.times == ERP(sub).trad_tar_walk_lat), :), 3);
        ERP(sub).trad_tar_walk_topo = mean(ERP(sub).trad_tar_walk(:,find(EEG.times == ERP(sub).trad_tar_walk_lat), :), 3);
    
        
        % get signal to noise ratio ------------------------------------------------------------------
    
        ERP(sub).ICC_sta_stand_SNR = pm_ref_snr(ERP(sub).ICC_sta_stand_erp, P3_st, P3_sp);
        ERP(sub).ICC_tar_stand_SNR = pm_ref_snr(ERP(sub).ICC_tar_stand_erp, P3_st, P3_sp);
        ERP(sub).ICC_sta_walk_SNR = pm_ref_snr(ERP(sub).ICC_sta_walk_erp, P3_st, P3_sp);
        ERP(sub).ICC_tar_walk_SNR = pm_ref_snr(ERP(sub).ICC_tar_walk_erp, P3_st, P3_sp);
    
        ERP(sub).trad_sta_stand_SNR = pm_ref_snr(ERP(sub).trad_sta_stand_erp, P3_st, P3_sp);
        ERP(sub).trad_tar_stand_SNR = pm_ref_snr(ERP(sub).trad_tar_stand_erp, P3_st, P3_sp);
        ERP(sub).trad_sta_walk_SNR = pm_ref_snr(ERP(sub).trad_sta_walk_erp, P3_st, P3_sp);
        ERP(sub).trad_tar_walk_SNR = pm_ref_snr(ERP(sub).trad_tar_walk_erp, P3_st, P3_sp);
    
        for chan = 1:length(ERP(sub).chanlocs)
            ERP(sub).ICC_tar_stand_SNR_all(chan) = pm_ref_snr(ERP(sub).ICC_tar_stand(chan,:,:), P3_st, P3_sp);
            ERP(sub).ICC_tar_walk_SNR_all(chan) = pm_ref_snr(ERP(sub).ICC_tar_walk(chan,:,:), P3_st, P3_sp);
            ERP(sub).trad_tar_stand_SNR_all(chan) = pm_ref_snr(ERP(sub).trad_tar_stand(chan,:,:), P3_st, P3_sp);
            ERP(sub).trad_tar_walk_SNR_all(chan) = pm_ref_snr(ERP(sub).trad_tar_walk(chan,:,:), P3_st, P3_sp);
    
        end
    end

end


%% pack standing and walking conditions together ----------------------------------------------

fun = @(s) all(structfun(@isempty, s));
idx = arrayfun(fun, ERP);
ERP(idx) = [];

save([MAINPATH,'SUBS'],'SUB');                                                                      % save information
save([MAINPATH,'ERP_info'],'ERP', '-v7.3');                                                                      % save information

T = table({SUB.ID}', cell2mat({ERP.ICC_sta_stand_peak})', cell2mat({ERP.ICC_tar_stand_peak})', cell2mat({ERP.ICC_sta_walk_peak})', ...
    cell2mat({ERP.ICC_tar_walk_peak})', cell2mat({ERP.trad_sta_stand_peak})', cell2mat({ERP.trad_tar_stand_peak})', ...
    cell2mat({ERP.trad_sta_walk_peak})', cell2mat({ERP.trad_tar_walk_peak})', ...
     cell2mat({ERP.ICC_sta_stand_amp})', cell2mat({ERP.ICC_tar_stand_amp})', cell2mat({ERP.ICC_sta_walk_amp})', ...
    cell2mat({ERP.ICC_tar_walk_amp})', cell2mat({ERP.trad_sta_stand_amp})', cell2mat({ERP.trad_tar_stand_amp})', ...
    cell2mat({ERP.trad_sta_walk_amp})', cell2mat({ERP.trad_tar_walk_amp})', ...
    cell2mat({ERP.ICC_tar_stand_lat})',  cell2mat({ERP.ICC_tar_walk_lat})', ...
    cell2mat({ERP.trad_tar_stand_lat})', cell2mat({ERP.trad_tar_walk_lat})', ...
    cell2mat({ERP.ICC_tar_stand_SNR})',  cell2mat({ERP.ICC_tar_walk_SNR})',  ...
    cell2mat({ERP.trad_tar_stand_SNR})', cell2mat({ERP.trad_tar_walk_SNR})', ...
    'VariableNames', {'ID', 'ICC_sta_stand_peak', 'ICC_tar_stand_peak', 'ICC_sta_walk_peak', 'ICC_tar_walk_peak', ...
    'trad_sta_stand_peak', 'trad_tar_stand_peak', 'trad_sta_walk_peak', 'trad_tar_walk_peak', ...
    'ICC_sta_stand_amp', 'ICC_tar_stand_amp', 'ICC_sta_walk_amp', 'ICC_tar_walk_amp', ...
    'trad_sta_stand_amp', 'trad_tar_stand_amp', 'trad_sta_walk_amp', 'trad_tar_walk_amp', ...
    'ICC_tar_stand_lat', 'ICC_tar_walk_lat', 'trad_tar_stand_lat', 'trad_tar_walk_lat', ...
    'ICC_tar_stand_SNR', 'ICC_tar_walk_SNR', 'trad_tar_stand_SNR', 'trad_tar_walk_SNR'});


writetable(T, [MAINPATH, 'ERP_stats.txt']);


%% descriptive: SNR for different electrode positions

figure;
for idx = 1:length(ERP)
    subplot(4,4,idx)
    topoplot(ERP(idx).ICC_tar_walk_SNR_all, ERP(idx).chanlocs)
    clim([0, 3])
    title(SUB(idx).ID, 'Interpreter','none')
end
sgtitle('SNR iCanClean pipeline')

figure;
for idx = 1:length(ERP)
    subplot(4,4,idx)
    topoplot(ERP(idx).trad_tar_walk_SNR_all, ERP(idx).chanlocs)
    clim([0, 3])
    title(SUB(idx).ID, 'Interpreter','none')
end
sgtitle('traditional pipeline')



%% end


