%% duallayer2_gerd_06_erp.m
%
% Description:
%   This script computes ERP metrics from epoched phantom head EEG data. 
%   Data are sorted into five motion-intensity conditions (rest, slow, mid, 
%   fast, walk) and compared between ICC-preprocessed and traditional 
%   preprocessing pipelines. ERPs are extracted at Pz, averaged, and 
%   summarized with peak amplitude, latency, topographies, and reference SNR.
%
% Workflow:
%   - Define input/output paths and create folders for results and plots
%   - Load epoched datasets per measurement and condition
%   - Sort data into motion-intensity conditions for ICC and trad
%   - Combine runs for each condition
%   - Extract Pz ERPs and compute condition-wise averages
%   - Compute ERP metrics:
%       * Peak amplitude and latency in P3 window
%       * Topographies at peak latency
%       * Reference SNR (Schimmel, 1967)
%   - Store results in structured ERP_PH object
%
% Inputs:
%   - Epoched EEG datasets (.set) from EPOPATH
%   - 'erp.mat' with ERP parameters:
%         * erp.sum_conds : condition names
%         * erp.P3_st_gerd / P3_sp_gerd : P3 time window
%   - 'MEAS.mat' with measurement metadata
%
% Outputs:
%   - ERP metrics (ERP_PH struct) saved in ERPPATH
%   - Condition-wise ERPs and metrics available for plotting
%
% Dependencies:
%   - EEGLAB (for loading datasets)
%   - pm_ref_snr (custom function for SNR computation)
%
%
% Author: Melanie, 2025

%% Preparations

close all; clear all; clc;                                                                          % start with fresh workspace

% set paths

MAINPATH = 'R:\Ferris-Lab\mklapprott\eegl\';                                                        % adjust this path to your local environment!!!
PATHOUT = [MAINPATH, 'derivatives\gerd\'];                                                          % path for data derivatives created on the way
EPOPATH = [PATHOUT, 'duallayer2_gerd_04_epo\'];                                                     % path for epoch data 
ERPPATH = [PATHOUT, 'duallayer2_gerd_05_erp\'];                                                     % path for erp data 

if ~isfolder(ERPPATH)                                                                               % if the path doesn't exist yet, create it
    mkdir(ERPPATH)
end

ERPPLOTS = [ERPPATH, 'plots\'];
if ~isfolder(ERPPLOTS)                                                                              % if the path doesn't exist yet, create it
    mkdir(ERPPLOTS)
end

% load parameters

cd(MAINPATH)
load('MEAS.mat'); 
load('erp.mat');  

%% sort data based on motion intensity

for meas = 1:length(MEASUREMENTS)

    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;                                                     % start EEGLAB

    SUBEPOPATH = [EPOPATH, MEASUREMENTS(meas).ID, '\'];

    cd(SUBEPOPATH)                                                                                  % set filepath
    files = dir(fullfile(SUBEPOPATH, '*.set'));                                                     % get access to data sets

    

    ERP_PH(1).ID = erp.sum_conds{1};
    ERP_PH(2).ID = erp.sum_conds{2};
    ERP_PH(3).ID = erp.sum_conds{3};
    ERP_PH(4).ID = erp.sum_conds{4};
    ERP_PH(5).ID = erp.sum_conds{5};

    for file = 1:length(files)


        file_name = files(file).name;
        EEG = pop_loadset('filename',file_name,'filepath',SUBEPOPATH);                              % load data
        [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);

        if contains(file_name, 'ICC')
            ERP_PH_single(meas).ICC_data = EEG.data;                                                        % also store single w/o combining
        elseif contains(file_name, 'trad')
            ERP_PH_single(meas).trad_data = EEG.data;
        end

        MEASUREMENTS(meas).chanPz(file) = find(strcmp({EEG.chanlocs.labels}, 'Pz'));                % find channel Pz

        if contains(file_name, 'rest') && contains(file_name, 'ICC')                                % sort for conditions
            ERP_PH(1).ICC_data1 = EEG.data;


        elseif contains(file_name, 'slow') && contains(file_name, 'ICC')
            if meas < 5
                ERP_PH(2).ICC_data1 = EEG.data;
            else
                ERP_PH(2).ICC_data2 = EEG.data;
            end

        elseif contains(file_name, 'mid') && contains(file_name, 'ICC')
            if meas < 5
                ERP_PH(3).ICC_data1 = EEG.data;
            else
                ERP_PH(3).ICC_data2 = EEG.data;
            end

        elseif contains(file_name, 'fast') && contains(file_name, 'ICC')
            if meas < 5
                ERP_PH(4).ICC_data1 = EEG.data;
            else
                ERP_PH(4).ICC_data2 = EEG.data;
            end

        elseif contains(file_name, 'walking') && contains(file_name, 'ICC')
            if meas == 8
                ERP_PH(5).ICC_data1 = EEG.data;
            elseif meas == 9
                ERP_PH(5).ICC_data2 = EEG.data;
            end

        % NO ICC ---------------------------------------------------------------------------------    
        elseif contains(file_name, 'rest') && contains(file_name, 'trad')
            ERP_PH(1).trad_data1 = EEG.data;


        elseif contains(file_name, 'slow') && contains(file_name, 'trad')
            if meas < 5
                ERP_PH(2).trad_data1 = EEG.data;
            else
                ERP_PH(2).trad_data2 = EEG.data;
            end

        elseif contains(file_name, 'mid') && contains(file_name, 'trad')
            if meas < 5
                ERP_PH(3).trad_data1 = EEG.data;
            else
                ERP_PH(3).trad_data2 = EEG.data;
            end

        elseif contains(file_name, 'fast') && contains(file_name, 'trad')
            if meas < 5
                ERP_PH(4).trad_data1 = EEG.data;
            else
                ERP_PH(4).trad_data2 = EEG.data;
            end

        elseif contains(file_name, 'walking') && contains(file_name, 'trad')
            if meas == 8
                ERP_PH(5).trad_data1 = EEG.data;
            elseif meas == 9
                ERP_PH(5).trad_data2 = EEG.data;
            end                                                                                     % end if else to sort 1st and 2nd measurement
        end                                                                                         % end if else for contains filename        
    end                                                                                             % end loop across files in measurements
end                                                                                                 % end loop across measurements
    

P3_st = find(EEG.times == erp.P3_st_gerd);
P3_sp = find(EEG.times == erp.P3_sp_gerd);

%% Summarize for metrics - combined

n_select = 50;                                                                                      % select 50 random trials to make SNR comparable

for idx = 1:length(ERP_PH)

    % combine first and second runs --------------------------------------------------------------

    if idx == 1
        ERP_PH(1).ICC_data = ERP_PH(1).ICC_data1;
        ERP_PH(1).trad_data = ERP_PH(1).trad_data1;
    else
        icc_int = cat(3, ERP_PH(idx).ICC_data1, ERP_PH(idx).ICC_data2);
        trad_int = cat(3, ERP_PH(idx).trad_data1, ERP_PH(idx).trad_data2);
        
        ERP_PH(idx).ICC_data = icc_int(:,:,randperm(size(icc_int,3), n_select));
        ERP_PH(idx).trad_data = trad_int(:,:,randperm(size(trad_int,3), n_select));
    end

    ERP_PH(idx).times = EEG.times;
    ERP_PH(idx).chanlocs = EEG.chanlocs;
    
    % get ERP metrics ----------------------------------------------------------------------------

    ERP_PH(idx).ICC_erp = ERP_PH(idx).ICC_data(MEASUREMENTS(1).chanPz(1), :,:);
    ERP_PH(idx).trad_erp = ERP_PH(idx).trad_data(MEASUREMENTS(1).chanPz(1), :,:);

    ERP_PH(idx).ICC_mean = mean(ERP_PH(idx).ICC_erp, 3);
    ERP_PH(idx).trad_mean = mean(ERP_PH(idx).trad_erp, 3);
    
    [ERP_PH(idx).ICC_peak, ICC_time] = max(ERP_PH(idx).ICC_mean(P3_st: P3_sp));
    [ERP_PH(idx).trad_peak, trad_time] = max(ERP_PH(idx).trad_mean(P3_st: P3_sp));

    ERP_PH(idx).ICC_lat = EEG.times(P3_st + ICC_time);
    ERP_PH(idx).trad_lat = EEG.times(P3_st + trad_time);

    ERP_PH(idx).ICC_topo = mean(ERP_PH(idx).ICC_data(:,find(EEG.times == ERP_PH(idx).ICC_lat), :), 3);
    ERP_PH(idx).trad_topo = mean(ERP_PH(idx).trad_data(:,find(EEG.times == ERP_PH(idx).trad_lat), :), 3);

    % get signal to noise ratio ------------------------------------------------------------------

    ERP_PH(idx).ICC_snr = pm_ref_snr(ERP_PH(idx).ICC_erp, P3_st, P3_sp);                            % +- reference SNR (Schimmel, 1967)
    ERP_PH(idx).trad_snr = pm_ref_snr(ERP_PH(idx).trad_erp, P3_st, P3_sp);                          % +- reference SNR (Schimmel, 1967)

    for trial = 1:size(ERP_PH(idx).ICC_erp, 3)
        ERP_PH(idx).ICC_stsnr(trial) = ERP_PH(idx).ICC_peak / ...
            std(ERP_PH(idx).ICC_erp(:, 1:find(ERP_PH(idx).times == 0), trial));                     % single trial SNR
    end

    for trial = 1:size(ERP_PH(idx).trad_erp, 3)
        ERP_PH(idx).trad_stsnr(trial) = ERP_PH(idx).trad_peak / ...
            std(ERP_PH(idx).trad_erp(:, 1:find(ERP_PH(idx).times == 0), trial));                    % single trial SNR
    end

    for chan = 1:size(ERP_PH(idx).ICC_data, 1)
        ERP_PH(idx).ICC_snr_all(chan) = pm_ref_snr(ERP_PH(idx).ICC_data(chan,:,:), P3_st, P3_sp); % +- reference SNR (Schimmel, 1967)
        ERP_PH(idx).trad_snr_all(chan) = pm_ref_snr(ERP_PH(idx).trad_data(chan,:,:), P3_st, P3_sp); % +- reference SNR (Schimmel, 1967)

    end


end


%% Summarize for metrics - single

n_select = 50;                                                                                      % select 50 random trials to make SNR comparable

for idx = 1:length(ERP_PH_single)

    % combine first and second runs --------------------------------------------------------------

    if idx == 8 || idx == 9
        
        ERP_PH_single(idx).ICC_data = ERP_PH_single(idx).ICC_data(:,:,randperm(size(ERP_PH_single(idx).ICC_data,3), n_select));
        ERP_PH_single(idx).trad_data = ERP_PH_single(idx).trad_data(:,:,randperm(size(ERP_PH_single(idx).trad_data,3), n_select));
    else      

        ERP_PH_single(1).ICC_data = ERP_PH_single(1).ICC_data;
        ERP_PH_single(1).trad_data = ERP_PH_single(1).trad_data;
        
    end

    ERP_PH_single(idx).times = EEG.times;
    ERP_PH_single(idx).chanlocs = EEG.chanlocs;
    
    % get ERP metrics ----------------------------------------------------------------------------

    ERP_PH_single(idx).ICC_erp = ERP_PH_single(idx).ICC_data(MEASUREMENTS(1).chanPz(1), :,:);
    ERP_PH_single(idx).trad_erp = ERP_PH_single(idx).trad_data(MEASUREMENTS(1).chanPz(1), :,:);

    ERP_PH_single(idx).ICC_mean = mean(ERP_PH_single(idx).ICC_erp, 3);
    ERP_PH_single(idx).trad_mean = mean(ERP_PH_single(idx).trad_erp, 3);
    
    [ERP_PH_single(idx).ICC_peak, ICC_time] = max(ERP_PH_single(idx).ICC_mean(P3_st: P3_sp));
    [ERP_PH_single(idx).trad_peak, trad_time] = max(ERP_PH_single(idx).trad_mean(P3_st: P3_sp));

    ERP_PH_single(idx).ICC_lat = EEG.times(P3_st + ICC_time);
    ERP_PH_single(idx).trad_lat = EEG.times(P3_st + trad_time);

    ERP_PH_single(idx).ICC_topo = mean(ERP_PH_single(idx).ICC_data(:,find(EEG.times == ERP_PH_single(idx).ICC_lat), :), 3);
    ERP_PH_single(idx).trad_topo = mean(ERP_PH_single(idx).trad_data(:,find(EEG.times == ERP_PH_single(idx).trad_lat), :), 3);

    % get signal to noise ratio ------------------------------------------------------------------

    ERP_PH_single(idx).ICC_snr = pm_ref_snr(ERP_PH_single(idx).ICC_erp, P3_st, P3_sp);              % +- reference SNR (Schimmel, 1967)
    ERP_PH_single(idx).trad_snr = pm_ref_snr(ERP_PH_single(idx).trad_erp, P3_st, P3_sp);            % +- reference SNR (Schimmel, 1967)

    for trial = 1:size(ERP_PH_single(idx).ICC_erp, 3)
        ERP_PH_single(idx).ICC_stsnr(trial) = ERP_PH_single(idx).ICC_peak / ...
            std(ERP_PH_single(idx).ICC_erp(:, 1:find(ERP_PH_single(idx).times == 0), trial));        % single trial SNR
    end

    for trial = 1:size(ERP_PH_single(idx).trad_erp, 3)
        ERP_PH_single(idx).trad_stsnr(trial) = ERP_PH_single(idx).trad_peak / ...
            std(ERP_PH_single(idx).trad_erp(:, 1:find(ERP_PH_single(idx).times == 0), trial));      % single trial SNR
    end


end


%% save info in table for stats

save([MAINPATH,'MEAS'],'MEASUREMENTS');                                                                      % save information
save([MAINPATH,'ERP_PH_info'],'ERP_PH');                                                                      % save information

T = table(erp.sum_conds', cell2mat({ERP_PH.ICC_peak})', cell2mat({ERP_PH.trad_peak})', cell2mat({ERP_PH.ICC_lat})', ...
    cell2mat({ERP_PH.trad_lat})', cell2mat({ERP_PH.ICC_snr})', cell2mat({ERP_PH.trad_snr})', ...
    'VariableNames', {'ID', 'ICC_peak', 'trad_peak', 'ICC_lat', 'trad_lat', 'ICC_snr', 'trad_snr'});

writetable(T, [MAINPATH, 'ERP_PH_stats.txt']);



SNRs = {cell2mat({ERP_PH(1).ICC_stsnr})', cell2mat({ERP_PH(1).trad_stsnr})', ... 
    cell2mat({ERP_PH(2).ICC_stsnr})', cell2mat({ERP_PH(2).trad_stsnr})', ...
    cell2mat({ERP_PH(3).ICC_stsnr})', cell2mat({ERP_PH(3).trad_stsnr})', ...
    cell2mat({ERP_PH(4).ICC_stsnr})', cell2mat({ERP_PH(4).trad_stsnr})', ...
    cell2mat({ERP_PH(5).ICC_stsnr})', cell2mat({ERP_PH(5).trad_stsnr})'};

meas_labels = {'rest', 'rest', 'slow', 'slow', 'mid', 'mid', 'fast', 'fast', 'walk', 'walk'};
prep_labels = {'ICC',  'trad', 'ICC',  'trad', 'ICC', 'trad','ICC',  'trad', 'ICC',  'trad'};

% Preallocate cell arrays for labels
allSNR = [];
allMeas = {};
allPipe = {};

for i = 1:numel(SNRs)
    thisSNR = SNRs{i};
    n = numel(thisSNR);

    allSNR  = [allSNR; thisSNR];                          % concatenate values
    allMeas = [allMeas; repmat(meas_labels(i), n, 1)];     % repeat measurement label
    allPipe = [allPipe; repmat(prep_labels(i), n, 1)];     % repeat pipeline label
end

% Make into a table
T_SNR = table(allMeas, allPipe, allSNR, ...
          'VariableNames', {'Measurement','Pipeline','SNR'});

writetable(T_SNR, [MAINPATH, 'ERP_PH_SNRs.txt']);


% for single values ------------------------------------------------------------------------------

SNRs = {cell2mat({ERP_PH_single(1).ICC_stsnr})', cell2mat({ERP_PH_single(1).trad_stsnr})', ... 
    cell2mat({ERP_PH_single(2).ICC_stsnr})', cell2mat({ERP_PH_single(2).trad_stsnr})', ...
    cell2mat({ERP_PH_single(3).ICC_stsnr})', cell2mat({ERP_PH_single(3).trad_stsnr})', ...
    cell2mat({ERP_PH_single(4).ICC_stsnr})', cell2mat({ERP_PH_single(4).trad_stsnr})', ...
    cell2mat({ERP_PH_single(5).ICC_stsnr})', cell2mat({ERP_PH_single(5).trad_stsnr})', ...
    cell2mat({ERP_PH_single(6).ICC_stsnr})', cell2mat({ERP_PH_single(6).trad_stsnr})', ...
    cell2mat({ERP_PH_single(7).ICC_stsnr})', cell2mat({ERP_PH_single(7).trad_stsnr})', ...
    cell2mat({ERP_PH_single(8).ICC_stsnr})', cell2mat({ERP_PH_single(8).trad_stsnr})', ...
    cell2mat({ERP_PH_single(9).ICC_stsnr})', cell2mat({ERP_PH_single(9).trad_stsnr})'};

ID = {'01', '01', '02', '02', '03', '03', '04', '04', '05', '05', '06', '06', '07', '07', '08', '08', ...
    '09', '09'};
meas_labels = {'rest', 'rest', 'slow', 'slow', 'mid', 'mid', 'fast', 'fast', 'slow', 'slow', ...
    'mid', 'mid', 'fast', 'fast', 'walk', 'walk', 'walk', 'walk'};
prep_labels = {'ICC',  'trad', 'ICC',  'trad', 'ICC', 'trad','ICC',  'trad', 'ICC',  'trad', ...
    'ICC',  'trad', 'ICC',  'trad', 'ICC',  'trad', 'ICC',  'trad'};

% Preallocate cell arrays for labels
allSNR = [];
allID = {};
allMeas = {};
allPipe = {};

for i = 1:numel(SNRs)
    thisSNR = SNRs{i};
    n = numel(thisSNR);

    allSNR  = [allSNR; thisSNR];                          % concatenate values
    allID = [allID; repmat(ID(i), n, 1)];
    allMeas = [allMeas; repmat(meas_labels(i), n, 1)];     % repeat measurement label
    allPipe = [allPipe; repmat(prep_labels(i), n, 1)];     % repeat pipeline label
end

% Make into a table
T_SNR_single = table(allID, allMeas, allPipe, allSNR, ...
          'VariableNames', {'ID', 'Measurement','Pipeline','SNR'});

writetable(T_SNR_single, [MAINPATH, 'ERP_PH_SNRs_single.txt']);





%% save plots 

my_positions = [0.755, 0.54, 0.33, 0.115];
% [0.78, 0.62, 0.454, 0.281, 0.115];

f = figure('Units', 'normalized', 'Position', [0.2 0.2 0.3 0.7]);  % Large square figure
sp_count = [1,5,2,4,3];
topo_time = [250 450];

for idx = 1:length(ERP_PH)-1

    subplot_handle = subplot(4,1,idx);

    error_ICC = std(ERP_PH(idx).ICC_erp, [], 3) / sqrt(size(ERP_PH(idx).ICC_erp, 3));
    error_No_ICC = std(ERP_PH(idx).trad_erp, [], 3) / sqrt(size(ERP_PH(idx).trad_erp, 3));

    % calculate error bars / shadow around GA
    lo_ICC = ERP_PH(idx).ICC_mean - error_ICC;
    hi_ICC = ERP_PH(idx).ICC_mean + error_ICC;
    lo_No_ICC = ERP_PH(idx).trad_mean - error_No_ICC;
    hi_No_ICC = ERP_PH(idx).trad_mean + error_No_ICC;
    
    x = EEG.times';

    % NO ICC
    hp2 = patch([x; x(end:-1:1);x(1)], [lo_No_ICC'; hi_No_ICC(end:-1:1)';lo_No_ICC(1)], 'r');                    % create appearance of SEM in plot
    hold on;
    set(hp2, 'facecolor', "#0F52BA", 'edgecolor', 'none');                                                    % adjust,emts
    hp2.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
    hp2.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
    hold on
    plot(ERP_PH(idx).times, ERP_PH(idx).trad_mean, 'color','#0F52BA', 'LineWidth', 1.1)
    hold on
    
    % ICC
    hp1 = patch([x; x(end:-1:1);x(1)], [lo_ICC'; hi_ICC(end:-1:1)';lo_ICC(1)], 'b');                    % create appearance of SEM in plot
    hold on;
    set(hp1, 'facecolor', "#EC5800", 'edgecolor', 'none');                                                    % adjust,emts
    hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
    hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
    hold on
    plot(ERP_PH(idx).times, ERP_PH(idx).ICC_mean, 'color', '#EC5800', 'LineWidth', 1.1)

    
    if idx == 1
        legend('trad', 'iCC')
    end
    
    ylim([-5,7])
    xl = xline(0, '--');  % vertical line at x = 0
    yl = yline(0);  % horizontal line at y = 0
    xl.Annotation.LegendInformation.IconDisplayStyle = 'off';
    yl.Annotation.LegendInformation.IconDisplayStyle = 'off';

    title(['Motion Condition: ', ERP_PH(idx).ID], "FontSize", 11)

    rectangle('Position',[200 -5 150 12], 'FaceColor',[0.3, .4, .6 , 0.2], 'LineStyle', 'none');        % search space


    % === Inset Parameters ===
    subplot_pos = get(subplot_handle, 'Position'); % [left, bottom, width, height]
    inset_width = 0.15 * subplot_pos(3);            % as fraction of subplot width
    inset_height = 0.3 * subplot_pos(4);           % as fraction of subplot height

    disp(num2str(subplot_pos));

    % === Upper Left Topoplot (ALLEEG(sp)) ===
    upper_left = [
        subplot_pos(1) + 0.002, ...
        my_positions(idx) + subplot_pos(4) - inset_height - 0.04, ...
        inset_width, inset_height];
    ax1 = axes('Position', upper_left);
    topoplot(ERP_PH(idx).ICC_topo, ERP_PH(idx).chanlocs, 'electrodes', 'off');
    axis tight
    set(ax1, 'XColor', 'none', 'YColor', 'none')
    annotation('rectangle', upper_left, 'EdgeColor', '#EC5800', 'LineWidth', 1)


    % === Lower Left Topoplot (ALLEEG(sp+1)) ===
    lower_left = [
        subplot_pos(1) + 0.0002, ...
        my_positions(idx) + 0.001, ...
        inset_width, inset_height];
    ax2 = axes('Position', lower_left);
    topoplot(ERP_PH(idx).trad_topo, ERP_PH(idx).chanlocs, 'electrodes', 'off');
    axis tight
    set(ax2, 'XColor', 'none', 'YColor', 'none')
    annotation('rectangle', lower_left, 'EdgeColor', '#0F52BA', 'LineWidth', 1)

end

sgtitle('Simulated P3 measured at Pz');

han=axes(gcf,'visible','off'); 
han.Title.Visible='on';
han.XLabel.Visible='on';
han.YLabel.Visible='on';
ylabel(han,'Amplitude [µV]', "FontSize", 12);
xlabel(han,'Time [ms]', "FontSize", 12);

cd(ERPPLOTS);
exportgraphics(f, 'GrandAverage-Pz_ERPs.png', 'Resolution', 300);
% close;


%% descriptive: SNR for different electrode positions

figure;
for idx = 1:length(ERP_PH)
    subplot(1,5,idx)
    topoplot(ERP_PH(idx).ICC_snr_all, ERP_PH(idx).chanlocs)
    %clim([0, 20])
    title(ERP_PH(idx).ID)
end
sgtitle('iCanClean pipeline')

figure;
for idx = 1:length(ERP_PH)
    subplot(1,5,idx)
    topoplot(ERP_PH(idx).trad_snr_all, ERP_PH(idx).chanlocs)
    %clim([0, 20])
    title(ERP_PH(idx).ID)
end
sgtitle('traditional pipeline')


