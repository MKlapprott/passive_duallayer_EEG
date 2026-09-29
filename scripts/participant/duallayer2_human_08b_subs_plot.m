%% duallayer2_human_08b_subs_plot.m
%
%
%
% Author: Melanie, Summer 2025



%% Preparations

clear all; close all; clc;

MAINPATH = 'R:\Ferris-Lab\mklapprott\eegl\';                                                        % adjust this path to your local environment!!!
PATHOUT = [MAINPATH, 'derivatives\participants\'];
EPOPATH = [PATHOUT, 'duallayer2_human_06_epo\plots\'];                                                    % path for epoched data 

cd(MAINPATH)
load('SUBS.mat');
load('erp.mat');
load('ERP_info.mat');

EVENTS = {'sta', 'tar'};

P3_start = 300;
P3_stop = 600;

SUB(4) = [];

%%

for sub = 13
    % data with ICC ------------------------------------------------------------------------------

    ICC_sta_stand = mean(ERP(sub).ICC_sta_stand_erp, 3);
    ICC_tar_stand = mean(ERP(sub).ICC_tar_stand_erp, 3);
    ICC_sta_walk = mean(ERP(sub).ICC_sta_walk_erp, 3);
    ICC_tar_walk = mean(ERP(sub).ICC_tar_walk_erp, 3);
    
    P3_st = find(ERP(1).times == P3_start);
    P3_sp = find(ERP(1).times == P3_stop);

    error_ICC_sta_stand = std(ERP(sub).ICC_sta_stand_erp, [], 3) / sqrt(size(ERP(sub).ICC_sta_stand_erp, 3));
    error_ICC_tar_stand = std(ERP(sub).ICC_tar_stand_erp, [], 3) / sqrt(size(ERP(sub).ICC_tar_stand_erp, 3));
    error_ICC_sta_walk = std(ERP(sub).ICC_sta_walk_erp, [], 3) / sqrt(size(ERP(sub).ICC_sta_walk_erp, 3));
    error_ICC_tar_walk = std(ERP(sub).ICC_tar_walk_erp, [], 3) / sqrt(size(ERP(sub).ICC_tar_walk_erp, 3));
    
    % calculate error bars / shadow around GA
    lo_ICC_sta_stand = ICC_sta_stand - error_ICC_sta_stand;
    hi_ICC_sta_stand = ICC_sta_stand + error_ICC_sta_stand;
    
    lo_ICC_tar_stand = ICC_tar_stand - error_ICC_tar_stand;
    hi_ICC_tar_stand = ICC_tar_stand + error_ICC_tar_stand;
    
    lo_ICC_sta_walk = ICC_sta_walk - error_ICC_sta_walk;
    hi_ICC_sta_walk = ICC_sta_walk + error_ICC_sta_walk;
    
    lo_ICC_tar_walk = ICC_tar_walk - error_ICC_tar_walk;
    hi_ICC_tar_walk = ICC_tar_walk + error_ICC_tar_walk;

    % data without ICC ---------------------------------------------------------------------------

    trad_sta_stand = mean(ERP(sub).trad_sta_stand_erp, 3);
    trad_tar_stand = mean(ERP(sub).trad_tar_stand_erp, 3);
    trad_sta_walk = mean(ERP(sub).trad_sta_walk_erp, 3);
    trad_tar_walk = mean(ERP(sub).trad_tar_walk_erp, 3);
    
    error_trad_sta_stand = std(ERP(sub).trad_sta_stand_erp, [], 3) / sqrt(size(ERP(sub).trad_sta_stand_erp, 3));
    error_trad_tar_stand = std(ERP(sub).trad_tar_stand_erp, [], 3) / sqrt(size(ERP(sub).trad_tar_stand_erp, 3));
    error_trad_sta_walk = std(ERP(sub).trad_sta_walk_erp, [], 3) / sqrt(size(ERP(sub).trad_sta_walk_erp, 3));
    error_trad_tar_walk = std(ERP(sub).trad_tar_walk_erp, [], 3) / sqrt(size(ERP(sub).trad_tar_walk_erp, 3));
    
    % calculate error bars / shadow around GA
    lo_trad_sta_stand = trad_sta_stand - error_trad_sta_stand;
    hi_trad_sta_stand = trad_sta_stand + error_trad_sta_stand;
    
    lo_trad_tar_stand = trad_tar_stand - error_trad_tar_stand;
    hi_trad_tar_stand = trad_tar_stand + error_trad_tar_stand;
    
    lo_trad_sta_walk = trad_sta_walk - error_trad_sta_walk;
    hi_trad_sta_walk = trad_sta_walk + error_trad_sta_walk;
    
    lo_trad_tar_walk = trad_tar_walk - error_trad_tar_walk;
    hi_trad_tar_walk = trad_tar_walk + error_trad_tar_walk;

    % ACTUAL PLOT --------------------------------------------------------------------------------

    x = ERP(1).times';

    figure('Units', 'normalized', 'Position', [0.2 0.2 0.6 0.6]);  % Large square figure
    
    % ICC stand --------------------------------------------------------------------------------------
    
    subplot_handle = subplot(2,2,1)
    
    subplot_pos = get(subplot_handle, 'Position');                                                      % [left, bottom, width, height]
    inset_width = 0.3 * subplot_pos(3);                                                                 % as fraction of subplot width
    inset_height = 0.3 * subplot_pos(4);                                                               % as fraction of subplot height
                                                                                          
    hp1 = patch([x; x(end:-1:1);x(1)], [lo_ICC_sta_stand'; hi_ICC_sta_stand(end:-1:1)';lo_ICC_sta_stand(1)], 'b');  % create appearance of SEM in plot
    hold on;
    set(hp1, 'facecolor', "b", 'edgecolor', 'none');                                                    % adjust,emts
    hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
    hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
    hold on
    
    plot(ERP(1).times, mean(ERP(sub).ICC_sta_stand_erp, 3), 'b')                                                      % actual plot
    hold on
    
    hp1 = patch([x; x(end:-1:1);x(1)], [lo_ICC_tar_stand'; hi_ICC_tar_stand(end:-1:1)';lo_ICC_tar_stand(1)], 'r');  % create appearance of SEM in plot
    hold on;
    set(hp1, 'facecolor', [0.8500, 0.3250, 0.0980], 'edgecolor', 'none');                                                    % adjust,emts
    hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
    hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
    hold on
    
    plot(ERP(1).times, mean(ERP(sub).ICC_tar_stand_erp, 3), 'color',[0.8500, 0.3250, 0.0980], 'LineWidth', 1.1)          % actual plot
    %ylim([-5, 25])
    
    xl = xline(0, '--');                                                                                % vertical line at x = 0
    yl = yline(0);                                                                                      % horizontal line at y = 0
    yl.Annotation.LegendInformation.IconDisplayStyle = 'off';
    xl.Annotation.LegendInformation.IconDisplayStyle = 'off';
    
    title('Standing - with ICC')                                                                        % titles, labels...
    ylabel('Amplitude [/u V]')
    legend('standard', 'target')
    
    %rectangle('Position',[300 -5 300 10], 'FaceColor',[0.3, .4, .6 , 0.2], 'LineStyle', 'none');        % search space
    
    % topoplot 
    upper_left = [
            subplot_pos(1) + 0.06, ...
            subplot_pos(2) + subplot_pos(4) - inset_height - 0.04, ...
            inset_width, inset_height];
    ax1 = axes('Position', upper_left);
    topoplot(ERP(sub).ICC_tar_stand_topo-ERP(sub).ICC_sta_stand_topo, ERP(1).chanlocs)
    axis tight
    set(ax1, 'XColor', 'none', 'YColor', 'none')
    
    % No ICC stand -----------------------------------------------------------------------------------
    
    subplot_handle = subplot(2,2,2)
    
    subplot_pos = get(subplot_handle, 'Position');                                                      % [left, bottom, width, height]
    inset_width = 0.3 * subplot_pos(3);                                                                 % as fraction of subplot width
    inset_height = 0.3 * subplot_pos(4);                                                               % as fraction of subplot height
    
    
    hp1 = patch([x; x(end:-1:1);x(1)], [lo_trad_sta_stand'; hi_trad_sta_stand(end:-1:1)';lo_trad_sta_stand(1)], 'b');  % create appearance of SEM in plot
    hold on;
    set(hp1, 'facecolor', "b", 'edgecolor', 'none');                                                    % adjust,emts
    hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
    hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
    hold on
    
    plot(ERP(1).times, mean(ERP(sub).trad_sta_stand_erp, 3), 'b')                                               % actual plot
    hold on
    
    hp1 = patch([x; x(end:-1:1);x(1)], [lo_trad_tar_stand'; hi_trad_tar_stand(end:-1:1)';lo_trad_tar_stand(1)], 'r');  % create appearance of SEM in plot
    hold on;
    set(hp1, 'facecolor', [0.8500, 0.3250, 0.0980], 'edgecolor', 'none');                                                    % adjust,emts
    hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
    hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
    hold on
    
    plot(ERP(1).times, mean(ERP(sub).trad_tar_stand_erp, 3), 'color', [0.8500, 0.3250, 0.0980], 'LineWidth', 1.1)                                               % actual plot
    %ylim([-5, 25])
    
    xl = xline(0, '--');  % vertical line at x = 0
    yl = yline(0);  % horizontal line at y = 0
    xl.Annotation.LegendInformation.IconDisplayStyle = 'off';
    yl.Annotation.LegendInformation.IconDisplayStyle = 'off';
    
    title('Standing - No ICC')
    
    %rectangle('Position',[300 -5 300 10], 'FaceColor',[0.3, .4, .6 , 0.2], 'LineStyle', 'none');        % search space
    
    % topoplot 
    upper_left = [
            subplot_pos(1) + 0.06, ...
            subplot_pos(2) + subplot_pos(4) - inset_height - 0.04, ...
            inset_width, inset_height];
    ax1 = axes('Position', upper_left);
    topoplot(ERP(sub).trad_tar_stand_topo-ERP(sub).trad_sta_stand_topo, ERP(1).chanlocs)
    axis tight
    set(ax1, 'XColor', 'none', 'YColor', 'none')
    
    
    % ICC walk ---------------------------------------------------------------------------------------
    
    subplot_handle = subplot(2,2,3)
    
    subplot_pos = get(subplot_handle, 'Position');                                                      % [left, bottom, width, height]
    inset_width = 0.3 * subplot_pos(3);                                                                 % as fraction of subplot width
    inset_height = 0.3 * subplot_pos(4);                                                               % as fraction of subplot height
    
    
    hp1 = patch([x; x(end:-1:1);x(1)], [lo_ICC_sta_walk'; hi_ICC_sta_walk(end:-1:1)';lo_ICC_sta_walk(1)], 'b');  % create appearance of SEM in plot
    hold on;
    set(hp1, 'facecolor', "b", 'edgecolor', 'none');                                                    % adjust,emts
    hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
    hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
    hold on
    
    plot(ERP(1).times, mean(ERP(sub).ICC_sta_walk_erp, 3), 'b')                                                  % actual plot
    hold on
    
    hp1 = patch([x; x(end:-1:1);x(1)], [lo_ICC_tar_walk'; hi_ICC_tar_walk(end:-1:1)';lo_ICC_tar_walk(1)], 'r');  % create appearance of SEM in plot
    hold on;
    set(hp1, 'facecolor', [0.8500, 0.3250, 0.0980], 'edgecolor', 'none');                                                    % adjust,emts
    hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
    hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
    hold on
    
    plot(ERP(1).times, mean(ERP(sub).ICC_tar_walk_erp, 3), 'color', [0.8500, 0.3250, 0.0980], 'LineWidth', 1.1)                                                  % actual plot
    %ylim([-5, 25])
    
    xl = xline(0, '--');  % vertical line at x = 0
    yl = yline(0);  % horizontal line at y = 0
    xl.Annotation.LegendInformation.IconDisplayStyle = 'off';
    yl.Annotation.LegendInformation.IconDisplayStyle = 'off';
    
    
    title('Walking - with ICC')
    ylabel('Amplitude [/u V]')
    xlabel('Time [ms]')
    
    %rectangle('Position',[300 -5 300 10], 'FaceColor',[0.3, .4, .6 , 0.2], 'LineStyle', 'none');        % search space
    
    % topoplot 
    upper_left = [
            subplot_pos(1) + 0.06, ...
            subplot_pos(2) + subplot_pos(4) - inset_height - 0.04, ...
            inset_width, inset_height];
    ax1 = axes('Position', upper_left);
    topoplot(ERP(sub).ICC_tar_walk_topo-ERP(sub).ICC_sta_walk_topo, ERP(1).chanlocs)
    axis tight
    set(ax1, 'XColor', 'none', 'YColor', 'none')
    
    
    % No ICC walk ------------------------------------------------------------------------------------
    
    subplot_handle = subplot(2,2,4)
    
    subplot_pos = get(subplot_handle, 'Position');                                                      % [left, bottom, width, height]
    inset_width = 0.3 * subplot_pos(3);                                                                 % as fraction of subplot width
    inset_height = 0.3 * subplot_pos(4);                                                               % as fraction of subplot height
    
    
    hp1 = patch([x; x(end:-1:1);x(1)], [lo_trad_sta_walk'; hi_trad_sta_walk(end:-1:1)';lo_trad_sta_walk(1)], 'b');  % create appearance of SEM in plot
    hold on;
    set(hp1, 'facecolor', "b", 'edgecolor', 'none');                                                    % adjust,emts
    hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
    hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
    hold on
    
    plot(ERP(1).times, mean(ERP(sub).trad_sta_walk_erp, 3), 'b')                                                % actual plot
    hold on
    
    hp1 = patch([x; x(end:-1:1);x(1)], [lo_trad_tar_walk'; hi_trad_tar_walk(end:-1:1)';lo_trad_tar_walk(1)], 'r');  % create appearance of SEM in plot
    hold on;
    set(hp1, 'facecolor', [0.8500, 0.3250, 0.0980], 'edgecolor', 'none');                                                    % adjust,emts
    hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
    hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
    hold on
    
    plot(ERP(1).times, mean(ERP(sub).trad_tar_walk_erp, 3), 'color', [0.8500, 0.3250, 0.0980], 'LineWidth', 1.1)                                                % actual plot
    %ylim([-5, 25])
    
    xl = xline(0, '--');  % vertical line at x = 0
    yl = yline(0);  % horizontal line at y = 0
    xl.Annotation.LegendInformation.IconDisplayStyle = 'off';
    yl.Annotation.LegendInformation.IconDisplayStyle = 'off';
    
    title('Walking - No ICC')
    xlabel('Time [ms]')
    
    %rectangle('Position',[300 -5 300 10], 'FaceColor',[0.3, .4, .6 , 0.2], 'LineStyle', 'none');        % search space
    
    % topoplot 
    upper_left = [
            subplot_pos(1) + 0.06, ...
            subplot_pos(2) + subplot_pos(4) - inset_height - 0.04, ...
            inset_width, inset_height];
    ax1 = axes('Position', upper_left);
    topoplot(ERP(sub).trad_tar_walk_topo-ERP(sub).trad_sta_walk_topo, ERP(1).chanlocs)
    axis tight
    set(ax1, 'XColor', 'none', 'YColor', 'none')
    
    
    sgtitle(['P300 measured at Pz, ', SUB(sub).ID], 'Interpreter', 'none');
    
    cd(EPOPATH)
    saveas(gca, [SUB(sub).ID, '-ERPs.png']);                                % save plot
    %close;

end


%%













