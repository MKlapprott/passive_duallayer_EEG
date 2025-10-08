%% duallayer2_human_08_erp_plot.m
%
%
%
% Author: Melanie, Summer 2025



%% Preparations

clear all; close all; clc;

MAINPATH = 'R:\Ferris-Lab\mklapprott\eegl\';                                                        % adjust this path to your local environment!!!
PATHOUT = [MAINPATH, 'derivatives\participants\'];
EPOPATH = [PATHOUT, 'duallayer2_human_06_epo\'];                                                    % path for epoched data 

cd(MAINPATH)
load('SUBS.mat');
load('erp.mat');
load('ERP_info.mat');

EVENTS = {'sta', 'tar'};

P3_start = 300;
P3_stop = 600;

%% Grand Average

% with ICC ---------------------------------------------------------------------------------------

all_ICC_sta_stand = cat(3, ERP(1).ICC_sta_stand_erp, ERP(2).ICC_sta_stand_erp);
all_ICC_tar_stand = cat(3, ERP(1).ICC_tar_stand_erp, ERP(2).ICC_tar_stand_erp);
all_ICC_sta_walk = cat(3, ERP(1).ICC_sta_walk_erp, ERP(2).ICC_sta_walk_erp);
all_ICC_tar_walk = cat(3, ERP(1).ICC_tar_walk_erp, ERP(2).ICC_tar_walk_erp);

for idx = [3,4,6,7,8,10,11]
    all_ICC_sta_stand = cat(3, all_ICC_sta_stand, ERP(idx).ICC_sta_stand_erp);
    all_ICC_tar_stand = cat(3, all_ICC_tar_stand, ERP(idx).ICC_tar_stand_erp);
    all_ICC_sta_walk = cat(3, all_ICC_sta_walk, ERP(idx).ICC_sta_walk_erp);
    all_ICC_tar_walk = cat(3, all_ICC_tar_walk, ERP(idx).ICC_tar_walk_erp);
end

ICC_sta_stand = mean(all_ICC_sta_stand, 3);
ICC_tar_stand = mean(all_ICC_tar_stand, 3);
ICC_sta_walk = mean(all_ICC_sta_walk, 3);
ICC_tar_walk = mean(all_ICC_tar_walk, 3);

P3_st = find(ERP(1).times == P3_start);
P3_sp = find(ERP(1).times == P3_stop);

[~, ICC_tar_stand_time] = max(ICC_tar_stand(P3_st:P3_sp));
ICC_tar_stand_lat = ERP(1).times(P3_st + ICC_tar_stand_time);

[~, ICC_tar_walk_time] = max(ICC_tar_walk(P3_st:P3_sp));
ICC_tar_walk_lat = ERP(1).times(P3_st + ICC_tar_walk_time);

error_ICC_sta_stand = std(all_ICC_sta_stand, [], 3) / sqrt(size(all_ICC_sta_stand, 3));
error_ICC_tar_stand = std(all_ICC_sta_stand, [], 3) / sqrt(size(all_ICC_tar_stand, 3));
error_ICC_sta_walk = std(all_ICC_sta_stand, [], 3) / sqrt(size(all_ICC_sta_walk, 3));
error_ICC_tar_walk = std(all_ICC_sta_stand, [], 3) / sqrt(size(all_ICC_tar_walk, 3));

% calculate error bars / shadow around GA
lo_ICC_sta_stand = ICC_sta_stand - error_ICC_sta_stand;
hi_ICC_sta_stand = ICC_sta_stand + error_ICC_sta_stand;

lo_ICC_tar_stand = ICC_tar_stand - error_ICC_tar_stand;
hi_ICC_tar_stand = ICC_tar_stand + error_ICC_tar_stand;

lo_ICC_sta_walk = ICC_sta_walk - error_ICC_sta_walk;
hi_ICC_sta_walk = ICC_sta_walk + error_ICC_sta_walk;

lo_ICC_tar_walk = ICC_tar_walk - error_ICC_tar_walk;
hi_ICC_tar_walk = ICC_tar_walk + error_ICC_tar_walk;


% without ICC ------------------------------------------------------------------------------------

all_trad_sta_stand = cat(3, ERP(1).trad_sta_stand_erp, ERP(2).trad_sta_stand_erp);
all_trad_tar_stand = cat(3, ERP(1).trad_tar_stand_erp, ERP(2).trad_tar_stand_erp);
all_trad_sta_walk = cat(3, ERP(1).trad_sta_walk_erp, ERP(2).trad_sta_walk_erp);
all_trad_tar_walk = cat(3, ERP(1).trad_tar_walk_erp, ERP(2).trad_tar_walk_erp);

for idx = [3,4,6,7,8,10,11]
    all_trad_sta_stand = cat(3, all_trad_sta_stand, ERP(idx).trad_sta_stand_erp);
    all_trad_tar_stand = cat(3, all_trad_tar_stand, ERP(idx).trad_tar_stand_erp);
    all_trad_sta_walk = cat(3, all_trad_sta_walk, ERP(idx).trad_sta_walk_erp);
    all_trad_tar_walk = cat(3, all_trad_tar_walk, ERP(idx).trad_tar_walk_erp);
end

trad_sta_stand = mean(all_trad_sta_stand, 3);
trad_tar_stand = mean(all_trad_tar_stand, 3);
trad_sta_walk = mean(all_trad_sta_walk, 3);
trad_tar_walk = mean(all_trad_tar_walk, 3);

[~, trad_tar_stand_time] = max(trad_tar_stand(P3_st:P3_sp));
trad_tar_stand_lat = ERP(1).times(P3_st + trad_tar_stand_time);

[~, trad_tar_walk_time] = max(trad_tar_walk(P3_st:P3_sp));
trad_tar_walk_lat = ERP(1).times(P3_st + trad_tar_walk_time);

error_trad_sta_stand = std(all_trad_sta_stand, [], 3) / sqrt(size(all_trad_sta_stand, 3));
error_trad_tar_stand = std(all_trad_sta_stand, [], 3) / sqrt(size(all_trad_tar_stand, 3));
error_trad_sta_walk = std(all_trad_sta_stand, [], 3) / sqrt(size(all_trad_sta_walk, 3));
error_trad_tar_walk = std(all_trad_sta_stand, [], 3) / sqrt(size(all_trad_tar_walk, 3));

% calculate error bars / shadow around GA
lo_trad_sta_stand = trad_sta_stand - error_trad_sta_stand;
hi_trad_sta_stand = trad_sta_stand + error_trad_sta_stand;

lo_trad_tar_stand = trad_tar_stand - error_trad_tar_stand;
hi_trad_tar_stand = trad_tar_stand + error_trad_tar_stand;

lo_trad_sta_walk = trad_sta_walk - error_trad_sta_walk;
hi_trad_sta_walk = trad_sta_walk + error_trad_sta_walk;

lo_trad_tar_walk = trad_tar_walk - error_trad_tar_walk;
hi_trad_tar_walk = trad_tar_walk + error_trad_tar_walk;


% topographies -----------------------------------------------------------------------------------

topo_ICC_sta_stand = cat(2, ERP(1).ICC_sta_stand_topo, ERP(2).ICC_sta_stand_topo);
topo_ICC_tar_stand = cat(2, ERP(1).ICC_tar_stand_topo, ERP(2).ICC_tar_stand_topo);
topo_ICC_sta_walk = cat(2, ERP(1).ICC_sta_walk_topo, ERP(2).ICC_sta_walk_topo);
topo_ICC_tar_walk = cat(2, ERP(1).ICC_tar_walk_topo, ERP(2).ICC_tar_walk_topo);

for idx = [3,4,6,7,8,10,11]
    topo_ICC_sta_stand = cat(2, topo_ICC_sta_stand, ERP(idx).ICC_sta_stand_topo);
    topo_ICC_tar_stand = cat(2, topo_ICC_tar_stand, ERP(idx).ICC_tar_stand_topo);
    topo_ICC_sta_walk = cat(2, topo_ICC_sta_walk, ERP(idx).ICC_sta_walk_topo);
    topo_ICC_tar_walk = cat(2, topo_ICC_tar_walk, ERP(idx).ICC_tar_walk_topo);
end

topo_ICC_sta_stand_mean = mean(topo_ICC_sta_stand, 2);
topo_ICC_tar_stand_mean = mean(topo_ICC_tar_stand, 2);
topo_ICC_sta_walk_mean = mean(topo_ICC_sta_walk, 2);
topo_ICC_tar_walk_mean = mean(topo_ICC_tar_walk, 2);

topo_trad_sta_stand = cat(2, ERP(1).trad_sta_stand_topo, ERP(2).trad_sta_stand_topo);
topo_trad_tar_stand = cat(2, ERP(1).trad_tar_stand_topo, ERP(2).trad_tar_stand_topo);
topo_trad_sta_walk = cat(2, ERP(1).trad_sta_walk_topo, ERP(2).trad_sta_walk_topo);
topo_trad_tar_walk = cat(2, ERP(1).trad_tar_walk_topo, ERP(2).trad_tar_walk_topo);

for idx = [3,4,6,7,8,10,11]
    topo_trad_sta_stand = cat(2, topo_trad_sta_stand, ERP(idx).trad_sta_stand_topo);
    topo_trad_tar_stand = cat(2, topo_trad_tar_stand, ERP(idx).trad_tar_stand_topo);
    topo_trad_sta_walk = cat(2, topo_trad_sta_walk, ERP(idx).trad_sta_walk_topo);
    topo_trad_tar_walk = cat(2, topo_trad_tar_walk, ERP(idx).trad_tar_walk_topo);
end

topo_trad_sta_stand_mean = mean(topo_trad_sta_stand, 2);
topo_trad_tar_stand_mean = mean(topo_trad_tar_stand, 2);
topo_trad_sta_walk_mean = mean(topo_trad_sta_walk, 2);
topo_trad_tar_walk_mean = mean(topo_trad_tar_walk, 2);


%% plot - Grand Average

x = ERP(1).times';

%f = figure('Units', 'normalized', 'Position', [0.2 0.2 0.3 0.7]);  % Large square figure

f = figure;

% ICC stand --------------------------------------------------------------------------------------

subplot_handle = subplot(2,2,1)

subplot_pos = get(subplot_handle, 'Position');                                                      % [left, bottom, width, height]
inset_width = 0.35 * subplot_pos(3);                                                                 % as fraction of subplot width
inset_height = 0.35 * subplot_pos(4);                                                               % as fraction of subplot height

                                                                                        
hp1 = patch([x; x(end:-1:1);x(1)], [lo_ICC_sta_stand'; hi_ICC_sta_stand(end:-1:1)';lo_ICC_sta_stand(1)], 'b');  % create appearance of SEM in plot
hold on;
set(hp1, 'facecolor', "b", 'edgecolor', 'none');                                                    % adjust,emts
hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on

plot(ERP(1).times, mean(all_ICC_sta_stand, 3), 'b')                                                      % actual plot
hold on

hp1 = patch([x; x(end:-1:1);x(1)], [lo_ICC_tar_stand'; hi_ICC_tar_stand(end:-1:1)';lo_ICC_tar_stand(1)], 'r');  % create appearance of SEM in plot
hold on;
set(hp1, 'facecolor', [0.8500, 0.3250, 0.0980], 'edgecolor', 'none');                                                    % adjust,emts
hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on

plot(ERP(1).times, mean(all_ICC_tar_stand, 3), 'color',[0.8500, 0.3250, 0.0980], 'LineWidth', 1.1)          % actual plot
ylim([-4, 8])

xl = xline(0, '--');                                                                                % vertical line at x = 0
yl = yline(0);                                                                                      % horizontal line at y = 0
yl.Annotation.LegendInformation.IconDisplayStyle = 'off';
xl.Annotation.LegendInformation.IconDisplayStyle = 'off';

title('Standing - with ICC', "FontSize", 11)                                                                        % titles, labels...
legend('Standard', 'Target')


rectangle('Position',[300 -4 300 12], 'FaceColor',[0.3, .4, .6 , 0.2], 'LineStyle', 'none');        % search space

% topoplot 
upper_left = [
        subplot_pos(1) - 0.075, ...
        subplot_pos(2) + subplot_pos(4) - inset_height - 0.04, ...
        inset_width, inset_height];
ax1 = axes('Position', upper_left);
topoplot(topo_ICC_tar_stand_mean-topo_ICC_sta_stand_mean, ERP(1).chanlocs, 'electrodes', 'off')
axis tight
set(ax1, 'XColor', 'none', 'YColor', 'none')

% No ICC stand -----------------------------------------------------------------------------------

subplot_handle = subplot(2,2,2)

subplot_pos = get(subplot_handle, 'Position');                                                      % [left, bottom, width, height]
inset_width = 0.35 * subplot_pos(3);                                                                 % as fraction of subplot width
inset_height = 0.35 * subplot_pos(4);                                                               % as fraction of subplot height


hp1 = patch([x; x(end:-1:1);x(1)], [lo_trad_sta_stand'; hi_trad_sta_stand(end:-1:1)';lo_trad_sta_stand(1)], 'b');  % create appearance of SEM in plot
hold on;
set(hp1, 'facecolor', "b", 'edgecolor', 'none');                                                    % adjust,emts
hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on

plot(ERP(1).times, mean(all_trad_sta_stand, 3), 'b')                                               % actual plot
hold on

hp1 = patch([x; x(end:-1:1);x(1)], [lo_trad_tar_stand'; hi_trad_tar_stand(end:-1:1)';lo_trad_tar_stand(1)], 'r');  % create appearance of SEM in plot
hold on;
set(hp1, 'facecolor', [0.8500, 0.3250, 0.0980], 'edgecolor', 'none');                                                    % adjust,emts
hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on

plot(ERP(1).times, mean(all_trad_tar_stand, 3), 'color', [0.8500, 0.3250, 0.0980], 'LineWidth', 1.1)                                               % actual plot
ylim([-4, 8])

xl = xline(0, '--');  % vertical line at x = 0
yl = yline(0);  % horizontal line at y = 0
xl.Annotation.LegendInformation.IconDisplayStyle = 'off';
yl.Annotation.LegendInformation.IconDisplayStyle = 'off';

title('Standing - Trad', "FontSize", 11)

rectangle('Position',[300 -4 300 12], 'FaceColor',[0.3, .4, .6 , 0.2], 'LineStyle', 'none');        % search space

% topoplot 
upper_left = [
        subplot_pos(1) - 0.075, ...
        subplot_pos(2) + subplot_pos(4) - inset_height - 0.04, ...
        inset_width, inset_height];
ax1 = axes('Position', upper_left);
topoplot(topo_trad_tar_stand_mean-topo_trad_sta_stand_mean, ERP(1).chanlocs, 'electrodes', 'off')
axis tight
set(ax1, 'XColor', 'none', 'YColor', 'none')


% ICC walk ---------------------------------------------------------------------------------------

subplot_handle = subplot(2,2,3)

subplot_pos = get(subplot_handle, 'Position');                                                      % [left, bottom, width, height]
inset_width = 0.35 * subplot_pos(3);                                                                 % as fraction of subplot width
inset_height = 0.35 * subplot_pos(4);                                                               % as fraction of subplot height


hp1 = patch([x; x(end:-1:1);x(1)], [lo_ICC_sta_walk'; hi_ICC_sta_walk(end:-1:1)';lo_ICC_sta_walk(1)], 'b');  % create appearance of SEM in plot
hold on;
set(hp1, 'facecolor', "b", 'edgecolor', 'none');                                                    % adjust,emts
hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on

plot(ERP(1).times, mean(all_ICC_sta_walk, 3), 'b')                                                  % actual plot
hold on

hp1 = patch([x; x(end:-1:1);x(1)], [lo_ICC_tar_walk'; hi_ICC_tar_walk(end:-1:1)';lo_ICC_tar_walk(1)], 'r');  % create appearance of SEM in plot
hold on;
set(hp1, 'facecolor', [0.8500, 0.3250, 0.0980], 'edgecolor', 'none');                                                    % adjust,emts
hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on

plot(ERP(1).times, mean(all_ICC_tar_walk, 3), 'color', [0.8500, 0.3250, 0.0980], 'LineWidth', 1.1)                                                  % actual plot
ylim([-4, 8])

xl = xline(0, '--');  % vertical line at x = 0
yl = yline(0);  % horizontal line at y = 0
xl.Annotation.LegendInformation.IconDisplayStyle = 'off';
yl.Annotation.LegendInformation.IconDisplayStyle = 'off';


title('Walking - with ICC', "FontSize", 11)

rectangle('Position',[300 -4 300 12], 'FaceColor',[0.3, .4, .6 , 0.2], 'LineStyle', 'none');        % search space

% topoplot 
upper_left = [
        subplot_pos(1) - 0.075, ...
        subplot_pos(2) + subplot_pos(4) - inset_height - 0.035, ...
        inset_width, inset_height];
ax1 = axes('Position', upper_left);
topoplot(topo_ICC_tar_walk_mean-topo_ICC_sta_walk_mean, ERP(1).chanlocs, 'electrodes', 'off')
axis tight
set(ax1, 'XColor', 'none', 'YColor', 'none')


% No ICC walk ------------------------------------------------------------------------------------

subplot_handle = subplot(2,2,4)

subplot_pos = get(subplot_handle, 'Position');                                                      % [left, bottom, width, height]
inset_width = 0.35 * subplot_pos(3);                                                                 % as fraction of subplot width
inset_height = 0.35 * subplot_pos(4);                                                               % as fraction of subplot height


hp1 = patch([x; x(end:-1:1);x(1)], [lo_trad_sta_walk'; hi_trad_sta_walk(end:-1:1)';lo_trad_sta_walk(1)], 'b');  % create appearance of SEM in plot
hold on;
set(hp1, 'facecolor', "b", 'edgecolor', 'none');                                                    % adjust,emts
hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on

plot(ERP(1).times, mean(all_trad_sta_walk, 3), 'b')                                                % actual plot
hold on

hp1 = patch([x; x(end:-1:1);x(1)], [lo_trad_tar_walk'; hi_trad_tar_walk(end:-1:1)';lo_trad_tar_walk(1)], 'r');  % create appearance of SEM in plot
hold on;
set(hp1, 'facecolor', [0.8500, 0.3250, 0.0980], 'edgecolor', 'none');                                                    % adjust,emts
hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on

plot(ERP(1).times, mean(all_trad_tar_walk, 3), 'color', [0.8500, 0.3250, 0.0980], 'LineWidth', 1.1)                                                % actual plot
ylim([-4, 8])

xl = xline(0, '--');  % vertical line at x = 0
yl = yline(0);  % horizontal line at y = 0
xl.Annotation.LegendInformation.IconDisplayStyle = 'off';
yl.Annotation.LegendInformation.IconDisplayStyle = 'off';

title('Walking - Trad', "FontSize", 11)

rectangle('Position',[300 -4 300 12], 'FaceColor',[0.3, .4, .6 , 0.2], 'LineStyle', 'none');        % search space

% topoplot 
upper_left = [
        subplot_pos(1) - 0.075, ...
        subplot_pos(2) + subplot_pos(4) - inset_height - 0.03, ...
        inset_width, inset_height];
ax1 = axes('Position', upper_left);
topoplot(topo_trad_tar_walk_mean-topo_trad_sta_walk_mean, ERP(1).chanlocs, 'electrodes', 'off')
axis tight
set(ax1, 'XColor', 'none', 'YColor', 'none')


sgtitle('Participants P3 measured at Pz');


han=axes(gcf,'visible','off'); 
han.Title.Visible='on';
han.XLabel.Visible='on';
han.YLabel.Visible='on';
ylabel(han,'Amplitude [µV]', "FontSize", 12);
xlabel(han,'Time [ms]', "FontSize", 12);

% cd(EPOPATH);
% exportgraphics(f, 'GrandAverage-Pz_ERPs.png', 'Resolution', 300);
% close;





%% plot - Grand Average

x = ERP(1).times';

f = figure('Units', 'normalized', 'Position', [0.2 0.2 0.3 0.7]);  % Large square figure

% ICC stand --------------------------------------------------------------------------------------

subplot_handle = subplot(4,1,1)

subplot_pos = get(subplot_handle, 'Position');                                                      % [left, bottom, width, height]
inset_width = 0.4 * subplot_pos(3);                                                                 % as fraction of subplot width
inset_height = 0.4 * subplot_pos(4);                                                               % as fraction of subplot height

                                                                                        
hp1 = patch([x; x(end:-1:1);x(1)], [lo_ICC_sta_stand'; hi_ICC_sta_stand(end:-1:1)';lo_ICC_sta_stand(1)], 'b');  % create appearance of SEM in plot
hold on;
set(hp1, 'facecolor', "b", 'edgecolor', 'none');                                                    % adjust,emts
hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on

plot(ERP(1).times, mean(all_ICC_sta_stand, 3), 'b')                                                      % actual plot
hold on

hp1 = patch([x; x(end:-1:1);x(1)], [lo_ICC_tar_stand'; hi_ICC_tar_stand(end:-1:1)';lo_ICC_tar_stand(1)], 'r');  % create appearance of SEM in plot
hold on;
set(hp1, 'facecolor', [0.8500, 0.3250, 0.0980], 'edgecolor', 'none');                                                    % adjust,emts
hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on

plot(ERP(1).times, mean(all_ICC_tar_stand, 3), 'color',[0.8500, 0.3250, 0.0980], 'LineWidth', 1.1)          % actual plot
ylim([-4, 8])

xl = xline(0, '--');                                                                                % vertical line at x = 0
yl = yline(0);                                                                                      % horizontal line at y = 0
yl.Annotation.LegendInformation.IconDisplayStyle = 'off';
xl.Annotation.LegendInformation.IconDisplayStyle = 'off';

title('Standing - with ICC', "FontSize", 11)                                                                        % titles, labels...
legend('Standard', 'Target')


rectangle('Position',[300 -4 300 12], 'FaceColor',[0.3, .4, .6 , 0.2], 'LineStyle', 'none');        % search space

% topoplot 
upper_left = [
        subplot_pos(1) - 0.075, ...
        subplot_pos(2) + subplot_pos(4) - inset_height - 0.04, ...
        inset_width, inset_height];
ax1 = axes('Position', upper_left);
topoplot(topo_ICC_tar_stand_mean-topo_ICC_sta_stand_mean, ERP(1).chanlocs, 'electrodes', 'off')
axis tight
set(ax1, 'XColor', 'none', 'YColor', 'none')

% No ICC stand -----------------------------------------------------------------------------------

subplot_handle = subplot(4,1,2)

subplot_pos = get(subplot_handle, 'Position');                                                      % [left, bottom, width, height]
inset_width = 0.4 * subplot_pos(3);                                                                 % as fraction of subplot width
inset_height = 0.4 * subplot_pos(4);                                                               % as fraction of subplot height


hp1 = patch([x; x(end:-1:1);x(1)], [lo_trad_sta_stand'; hi_trad_sta_stand(end:-1:1)';lo_trad_sta_stand(1)], 'b');  % create appearance of SEM in plot
hold on;
set(hp1, 'facecolor', "b", 'edgecolor', 'none');                                                    % adjust,emts
hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on

plot(ERP(1).times, mean(all_trad_tar_stand, 3)- mean(all_trad_sta_stand, 3), 'b')                                               % actual plot
hold on

hp1 = patch([x; x(end:-1:1);x(1)], [lo_trad_tar_stand'; hi_trad_tar_stand(end:-1:1)';lo_trad_tar_stand(1)], 'r');  % create appearance of SEM in plot
hold on;
set(hp1, 'facecolor', [0.8500, 0.3250, 0.0980], 'edgecolor', 'none');                                                    % adjust,emts
hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on

plot(ERP(1).times, mean(all_ICC_tar_stand, 3)- mean(all_ICC_sta_stand, 3), 'color', [0.8500, 0.3250, 0.0980], 'LineWidth', 1.1)                                               % actual plot
ylim([-4, 8])

xl = xline(0, '--');  % vertical line at x = 0
yl = yline(0);  % horizontal line at y = 0
xl.Annotation.LegendInformation.IconDisplayStyle = 'off';
yl.Annotation.LegendInformation.IconDisplayStyle = 'off';

title('Standing - Trad', "FontSize", 11)

rectangle('Position',[300 -4 300 12], 'FaceColor',[0.3, .4, .6 , 0.2], 'LineStyle', 'none');        % search space

% topoplot 
upper_left = [
        subplot_pos(1) - 0.075, ...
        subplot_pos(2) + subplot_pos(4) - inset_height - 0.04, ...
        inset_width, inset_height];
ax1 = axes('Position', upper_left);
topoplot(topo_trad_tar_stand_mean-topo_trad_sta_stand_mean, ERP(1).chanlocs, 'electrodes', 'off')
axis tight
set(ax1, 'XColor', 'none', 'YColor', 'none')


sgtitle('Participants P3 measured at Pz');


han=axes(gcf,'visible','off'); 
han.Title.Visible='on';
han.XLabel.Visible='on';
han.YLabel.Visible='on';
ylabel(han,'Amplitude [µV]', "FontSize", 12);
xlabel(han,'Time [ms]', "FontSize", 12);

% cd(EPOPATH);
% exportgraphics(f, 'GrandAverage-Pz_ERPs_POSTER.png', 'Resolution', 300);
% close;


%% plot - topographies
% upper line target, lower line standard, left with ICC, right no ICC


figure;
subplot(2,4,1)
topoplot(topo_ICC_sta_stand_mean, ERP(1).chanlocs)
clim([-6 6])
title('Standing standard - ICC')

subplot(2,4,5)
topoplot(topo_ICC_tar_stand_mean, ERP(1).chanlocs)
clim([-6 6])
title('Standing target - ICC')

subplot(2,4,2)
topoplot(topo_ICC_sta_walk_mean, ERP(1).chanlocs)
clim([-6 6])
title('Walking standard - ICC')

subplot(2,4,6)
topoplot(topo_ICC_tar_walk_mean, ERP(1).chanlocs)
clim([-6 6])
title('Walking target - ICC')

subplot(2,4,3)
topoplot(topo_trad_sta_stand_mean, ERP(1).chanlocs)
clim([-6 6])
title('Standing standard - no ICC')

subplot(2,4,7)
topoplot(topo_trad_tar_stand_mean, ERP(1).chanlocs)
clim([-6 6])
title('Standing target - no ICC')

subplot(2,4,4)
topoplot(topo_trad_sta_walk_mean, ERP(1).chanlocs)
clim([-6 6])
title('Walking standard - no ICC')

subplot(2,4,8)
topoplot(topo_trad_tar_walk_mean, ERP(1).chanlocs)
clim([-6 6])
colorbar;
title('Walking target - no ICC')

% tar - sta

figure;
subplot(1,4,1)
topoplot(topo_ICC_tar_stand_mean-topo_ICC_sta_stand_mean, ERP(1).chanlocs)
clim([-6 6])
title('ICC stand')

subplot(1,4,2)
topoplot(topo_ICC_tar_walk_mean-topo_ICC_sta_walk_mean, ERP(1).chanlocs)
clim([-6 6])
title('ICC walk')

subplot(1,4,3)
topoplot(topo_trad_tar_stand_mean-topo_trad_sta_stand_mean, ERP(1).chanlocs)
clim([-6 6])
title('Trad stand')

subplot(1,4,4)
topoplot(topo_trad_tar_walk_mean-topo_trad_sta_walk_mean, ERP(1).chanlocs)
clim([-6 6])
title('Trad walk')



%%

figure('Units', 'normalized', 'Position', [0.2 0.2 0.6 0.6]);  % Large square figure
sp_count = [1,1,2,2,3,3,4,4];
topo_time = [80 120];

for sp = 1:2:length(ALLEEG)

    subplot_handle = subplot(2,2,sp_count(sp));

    ICC = mean(ALLEEG(sp).data(N1_chan(sp),:,:),3);
    No_ICC = mean(ALLEEG(sp+1).data(N1_chan(sp+1),:,:),3);
    
    error_ICC = std(ALLEEG(sp).data(N1_chan(sp),:,:), [], 3) / sqrt(size(ALLEEG(sp).data(N1_chan(sp),:,:), 3));
    error_No_ICC = std(ALLEEG(sp+1).data(N1_chan(sp+1),:,:), [], 3) / sqrt(size(ALLEEG(sp+1).data(N1_chan(sp+1),:,:), 3));

    % calculate error bars / shadow around GA
    lo_ICC = ICC - error_ICC;
    hi_ICC = ICC + error_ICC;
    lo_No_ICC = No_ICC - error_No_ICC;
    hi_No_ICC = No_ICC + error_No_ICC;
    
    x = EEG.times';

    % ICC
    hp1 = patch([x; x(end:-1:1);x(1)], [lo_ICC'; hi_ICC(end:-1:1)';lo_ICC(1)], 'b');                    % create appearance of SEM in plot
    hold on;
    set(hp1, 'facecolor', "b", 'edgecolor', 'none');                                                    % adjust,emts
    hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
    hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
    hold on
    plot(EEG.times, ICC, 'b', 'LineWidth', 1.1)
    hold on

    % NO ICC
    hp2 = patch([x; x(end:-1:1);x(1)], [lo_No_ICC'; hi_No_ICC(end:-1:1)';lo_No_ICC(1)], 'b');                    % create appearance of SEM in plot
    hold on;
    set(hp2, 'facecolor', "r", 'edgecolor', 'none');                                                    % adjust,emts
    hp2.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
    hp2.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
    hold on
    plot(EEG.times, No_ICC, 'r', 'LineWidth', 1.1)
    
    
    if sp == 1
        ylabel('Amplitude [µV]')
    elseif sp == 5
        ylabel('Amplitude [µV]')
        xlabel('time [ms]')
    elseif sp == 7
        xlabel('time [ms]')
    end
    
    if sp == 7
        legend('with iCC', 'no iCC')
    end
    
    ylim([-5,5])
    xl = xline(0, '--');  % vertical line at x = 0
    yl = yline(0);  % horizontal line at y = 0
    xl.Annotation.LegendInformation.IconDisplayStyle = 'off';
    yl.Annotation.LegendInformation.IconDisplayStyle = 'off';

    title(erp.noise_conds{sp})

    rectangle('Position',[80 -5 40 10], 'FaceColor',[0.3, .4, .6 , 0.2], 'LineStyle', 'none');        % search space


    % === Inset Parameters ===
    subplot_pos = get(subplot_handle, 'Position'); % [left, bottom, width, height]
    inset_width = 0.17 * subplot_pos(3);            % as fraction of subplot width
    inset_height = 0.25 * subplot_pos(4);           % as fraction of subplot height

    % === Upper Left Topoplot (ALLEEG(sp)) ===
    upper_left = [
        subplot_pos(1) + 0.002, ...
        subplot_pos(2) + subplot_pos(4) - inset_height - 0.04, ...
        inset_width, inset_height];
    ax1 = axes('Position', upper_left);
    data1 = squeeze(mean(mean(ALLEEG(sp).data(:,N1_st_idx:N1_sp_idx,:), 3),2));
    topoplot(data1, ALLEEG(sp).chanlocs);
    axis tight
    set(ax1, 'XColor', 'none', 'YColor', 'none')
    annotation('rectangle', upper_left, 'EdgeColor', 'b', 'LineWidth', 1)


    % === Lower Left Topoplot (ALLEEG(sp+1)) ===
    lower_left = [
        subplot_pos(1) + 0.002, ...
        subplot_pos(2) + 0.01, ...
        inset_width, inset_height];
    ax2 = axes('Position', lower_left);
    data2 = squeeze(mean(mean(ALLEEG(sp+1).data(:,N1_st_idx:N1_sp_idx,:), 3),2));
    topoplot(data2, ALLEEG(sp+1).chanlocs);
    axis tight
    set(ax2, 'XColor', 'none', 'YColor', 'none')
    annotation('rectangle', lower_left, 'EdgeColor', 'r', 'LineWidth', 1)

end

sgtitle([erp.rec_conds{meas}, ' - N1 at Fz']);

cd(ERPPLOTS);
saveas(gca, [erp.rec_conds_save{meas}, '-Fz_ERPs.png']);                                              % save plot
close;

% P300 ---------------------------------------------------------------------------------------

figure('Units', 'normalized', 'Position', [0.2 0.2 0.6 0.6]);  % Large square figure
sp_count = [1,1,2,2,3,3,4,4];

for sp = 1:2:length(ALLEEG)

    subplot_handle = subplot(2,2,sp_count(sp));

    ICC = mean(ALLEEG(sp).data(P3_chan(sp),:,:),3);
    No_ICC = mean(ALLEEG(sp+1).data(P3_chan(sp+1),:,:),3);
    
    error_ICC = std(ALLEEG(sp).data(P3_chan(sp),:,:), [], 3) / sqrt(size(ALLEEG(sp).data(P3_chan(sp),:,:), 3));
    error_No_ICC = std(ALLEEG(sp+1).data(P3_chan(sp+1),:,:), [], 3) / sqrt(size(ALLEEG(sp+1).data(P3_chan(sp+1),:,:), 3));

    % calculate error bars / shadow around GA
    lo_ICC = ICC - error_ICC;
    hi_ICC = ICC + error_ICC;
    lo_No_ICC = No_ICC - error_No_ICC;
    hi_No_ICC = No_ICC + error_No_ICC;
    
    x = EEG.times';

    % ICC
    hp1 = patch([x; x(end:-1:1);x(1)], [lo_ICC'; hi_ICC(end:-1:1)';lo_ICC(1)], 'b');                    % create appearance of SEM in plot
    hold on;
    set(hp1, 'facecolor', "b", 'edgecolor', 'none');                                                    % adjust,emts
    hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
    hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
    hold on
    plot(EEG.times, ICC, 'b', 'LineWidth', 1.1)
    hold on

    % NO ICC
    hp2 = patch([x; x(end:-1:1);x(1)], [lo_No_ICC'; hi_No_ICC(end:-1:1)';lo_No_ICC(1)], 'b');                    % create appearance of SEM in plot
    hold on;
    set(hp2, 'facecolor', "r", 'edgecolor', 'none');                                                    % adjust,emts
    hp2.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
    hp2.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
    hold on
    plot(EEG.times, No_ICC, 'r', 'LineWidth', 1.1)
    
    
    if sp == 1
        ylabel('Amplitude [µV]')
    elseif sp == 5
        ylabel('Amplitude [µV]')
        xlabel('time [ms]')
    elseif sp == 7
        xlabel('time [ms]')
    end
    
    if sp == 7
        legend('with iCC', 'no iCC')
    end
    
    ylim([-5,5])
    xl = xline(0, '--');  % vertical line at x = 0
    yl = yline(0);  % horizontal line at y = 0
    xl.Annotation.LegendInformation.IconDisplayStyle = 'off';
    yl.Annotation.LegendInformation.IconDisplayStyle = 'off';

    title(erp.noise_conds{sp})

    rectangle('Position',[200 -5 150 10], 'FaceColor',[0.3, .4, .6 , 0.2], 'LineStyle', 'none');        % search space


    % === Inset Parameters ===
    subplot_pos = get(subplot_handle, 'Position'); % [left, bottom, width, height]
    inset_width = 0.17 * subplot_pos(3);            % as fraction of subplot width
    inset_height = 0.25 * subplot_pos(4);           % as fraction of subplot height

    % === Upper Left Topoplot (ALLEEG(sp)) ===
    upper_left = [
        subplot_pos(1) + 0.002, ...
        subplot_pos(2) + subplot_pos(4) - inset_height - 0.04, ...
        inset_width, inset_height];
    ax1 = axes('Position', upper_left);
    data1 = squeeze(mean(mean(ALLEEG(sp).data(:,P3_st_idx:P3_sp_idx,:), 3),2));
    topoplot(data1, ALLEEG(sp).chanlocs);
    axis tight
    set(ax1, 'XColor', 'none', 'YColor', 'none')
    annotation('rectangle', upper_left, 'EdgeColor', 'b', 'LineWidth', 1)


    % === Lower Left Topoplot (ALLEEG(sp+1)) ===
    lower_left = [
        subplot_pos(1) + 0.002, ...
        subplot_pos(2) + 0.01, ...
        inset_width, inset_height];
    ax2 = axes('Position', lower_left);
    data2 = squeeze(mean(mean(ALLEEG(sp+1).data(:,P3_st_idx:P3_sp_idx,:), 3),2));
    topoplot(data2, ALLEEG(sp+1).chanlocs);
    axis tight
    set(ax2, 'XColor', 'none', 'YColor', 'none')
    annotation('rectangle', lower_left, 'EdgeColor', 'r', 'LineWidth', 1)

end

sgtitle([erp.rec_conds{meas}, ' - P3 at Pz']);

cd(ERPPLOTS);
saveas(gca, [erp.rec_conds_save{meas}, '-Pz_ERPs.png']);                                              % save plot
close;


%%

figure;
subplot(121)
plot(ERP(1).ICC_sta_stand_mean)
hold on
plot(ERP(2).ICC_sta_stand_mean)
hold on
plot(ERP(3).ICC_sta_stand_mean)
hold on
plot(ERP(4).ICC_sta_stand_mean)
hold on
plot(ERP(5).ICC_sta_stand_mean)
hold on
plot(ERP(6).ICC_sta_stand_mean)
hold on
plot(ERP(7).ICC_sta_stand_mean)
hold on
plot(ERP(8).ICC_sta_stand_mean)
legend('p4', 'p6', 's1', 's2', 's3', 's4', 's5', 's6')

subplot(122)
plot(ERP(1).noICC_sta_stand_mean)
hold on
plot(ERP(2).noICC_sta_stand_mean)
hold on
plot(ERP(3).noICC_sta_stand_mean)
hold on
plot(ERP(4).noICC_sta_stand_mean)
hold on
plot(ERP(5).noICC_sta_stand_mean)
hold on
plot(ERP(6).noICC_sta_stand_mean)
hold on
plot(ERP(7).noICC_sta_stand_mean)
hold on
plot(ERP(8).noICC_sta_stand_mean)
legend('p4', 'p6', 's1', 's2', 's3', 's4', 's5', 's6')
