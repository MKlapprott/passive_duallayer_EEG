%% duallayer2_human_08_erp_plot.m
%
%
%
% Author: Melanie, Summer 2025



%% Preparations

clear all; close all; clc;

MAINPATH = 'Q:\data\projects\all_gait\dual-layerCap\dual-layer-2024_25\eegl\';
PATHOUT = [MAINPATH, 'derivatives\participants\'];
EPOPATH = [PATHOUT, 'duallayer2_human_06_epo\'];                                                    % path for epoched data 

cd(MAINPATH)
load('SUBS.mat');
load('erp.mat');
load('ERP_info.mat');

EVENTS = {'sta', 'tar'};

P3_start = 300;
P3_stop = 600;

 ERP(1) = [];

%% Grand Average

% with ICC ---------------------------------------------------------------------------------------

all_ICC_sta_stand = cat(3, ERP(1).ICC_sta_stand_erp, ERP(2).ICC_sta_stand_erp);
all_ICC_tar_stand = cat(3, ERP(1).ICC_tar_stand_erp, ERP(2).ICC_tar_stand_erp);
all_ICC_sta_walk = cat(3, ERP(1).ICC_sta_walk_erp, ERP(2).ICC_sta_walk_erp);
all_ICC_tar_walk = cat(3, ERP(1).ICC_tar_walk_erp, ERP(2).ICC_tar_walk_erp);

for idx = [3:14]
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

for idx = 3:14
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

for idx = 3:14
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

for idx = 3:14
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

t = title('Stand - ICC', "FontSize", 11)                                                                        % titles, labels...
t.TitleHorizontalAlignment = 'left'; 

%rectangle('Position',[300 -4 300 12], 'FaceColor',[0.5, .5, .5], 'LineStyle', 'none', ...
%    'FaceAlpha', 0.2);        % search space

patch([300 600 600 300], ...
      [-4 -4 8 8], ...
      [0.5 0.5 0.5], ...
      'EdgeColor', 'none', ...
      'FaceAlpha', 0.2);

% topoplot 
upper_left = [
        subplot_pos(1) - 0.01, ...
        subplot_pos(2) + subplot_pos(4) - inset_height - 0.04, ...
        inset_width, inset_height];
ax1 = axes('Position', upper_left);
topoplot(topo_ICC_tar_stand_mean-topo_ICC_sta_stand_mean, ERP(1).chanlocs, 'electrodes', 'off')
%clim([-5 5])
caxis([-5 5])
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

t = title('Stand - noICC', "FontSize", 11);                                                                        % titles, labels...
t.TitleHorizontalAlignment = 'left'; 


%rectangle('Position',[300 -4 300 12], 'FaceColor',[0.5, .5, .5], 'LineStyle', 'none', ...
%    'FaceAlpha', 0.2);        % search space

patch([300 600 600 300], ...
      [-4 -4 8 8], ...
      [0.5 0.5 0.5], ...
      'EdgeColor', 'none', ...
      'FaceAlpha', 0.2);
      
% topoplot 
upper_left = [
        subplot_pos(1) - 0.01, ...
        subplot_pos(2) + subplot_pos(4) - inset_height - 0.04, ...
        inset_width, inset_height];
ax1 = axes('Position', upper_left);
topoplot(topo_trad_tar_stand_mean-topo_trad_sta_stand_mean, ERP(1).chanlocs, 'electrodes', 'off')
%clim([-5 5])
caxis([-5 5])
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

t = title('Walk - ICC', "FontSize", 11);                                                                        % titles, labels...
t.TitleHorizontalAlignment = 'left'; 


%rectangle('Position',[300 -4 300 12], 'FaceColor',[0.5, .5, .5], 'LineStyle', 'none', ...
%    'FaceAlpha', 0.2);        % search space

patch([300 600 600 300], ...
      [-4 -4 8 8], ...
      [0.5 0.5 0.5], ...
      'EdgeColor', 'none', ...
      'FaceAlpha', 0.2);

% topoplot 
upper_left = [
        subplot_pos(1) - 0.01, ...
        subplot_pos(2) + subplot_pos(4) - inset_height - 0.035, ...
        inset_width, inset_height];
ax1 = axes('Position', upper_left);
topoplot(topo_ICC_tar_walk_mean-topo_ICC_sta_walk_mean, ERP(1).chanlocs, 'electrodes', 'off')
%clim([-5 5])
caxis([-5 5])
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

legend('Standard', 'Target')
t = title('Walk - noICC', "FontSize", 11);                                                                        % titles, labels...
t.TitleHorizontalAlignment = 'left'; 


%rectangle('Position',[300 -4 300 12], 'FaceColor',[0.5, .5, .5], 'LineStyle', 'none', ...
%    'FaceAlpha', 0.2);        % search space

p = patch([300 600 600 300], ...
      [-4 -4 8 8], ...
      [0.5 0.5 0.5], ...
      'EdgeColor', 'none', ...
      'FaceAlpha', 0.2);
  
p.Annotation.LegendInformation.IconDisplayStyle = 'off';

% topoplot 
upper_left = [
        subplot_pos(1) - 0.01, ...
        subplot_pos(2) + subplot_pos(4) - inset_height - 0.03, ...
        inset_width, inset_height];
ax1 = axes('Position', upper_left);
topoplot(topo_trad_tar_walk_mean-topo_trad_sta_walk_mean, ERP(1).chanlocs, 'electrodes', 'off')
%clim([-5 5])
caxis([-5 5])
axis tight
set(ax1, 'XColor', 'none', 'YColor', 'none')


sgtitle('Participants P300 measured at Pz', 'FontSize', 14, 'FontWeight', 'bold');

set(gcf, 'Color', 'w')
han=axes(gcf,'visible','off'); 
han.Title.Visible='on';
han.XLabel.Visible='on';
han.YLabel.Visible='on';
ylabel(han,'Amplitude [µV]', "FontSize", 12);
xlabel(han,'Time [ms]', "FontSize", 12);

cd(EPOPATH);
%saveas(f, 'GrandAverage-Pz_ERPs.svg')
%exportgraphics(f, 'GrandAverage-Pz_ERPs.pdf','ContentType', 'vector', 'Resolution', 300);
% close;

%print(gcf, 'GrandAverage-Pz_ERPs', '-dsvg')

%print(f,'GrandAverage-Pz_ERPs.svg','-dsvg');
%exportgraphics(f, 'GrandAverage-Pz_ERPs_noaddnoise.pdf', 'ContentType', 'vector', 'Resolution', 300);

%% plot - Grand Average with minimally processed data

load('ERP_raw_info.mat');
ERP_raw(1) = [];

all_raw_sta_stand = cat(3, ERP_raw(1).sta_stand_erp, ERP_raw(2).sta_stand_erp);
all_raw_tar_stand = cat(3, ERP_raw(1).tar_stand_erp, ERP_raw(2).tar_stand_erp);
all_raw_sta_walk  = cat(3, ERP_raw(1).sta_walk_erp,  ERP_raw(2).sta_walk_erp);
all_raw_tar_walk  = cat(3, ERP_raw(1).tar_walk_erp,  ERP_raw(2).tar_walk_erp);

for idx = 3:14
    all_raw_sta_stand = cat(3, all_raw_sta_stand, ERP_raw(idx).sta_stand_erp);
    all_raw_tar_stand = cat(3, all_raw_tar_stand, ERP_raw(idx).tar_stand_erp);
    all_raw_sta_walk  = cat(3, all_raw_sta_walk,  ERP_raw(idx).sta_walk_erp);
    all_raw_tar_walk  = cat(3, all_raw_tar_walk,  ERP_raw(idx).tar_walk_erp);
end

raw_sta_stand = mean(all_raw_sta_stand, 3);
raw_tar_stand = mean(all_raw_tar_stand, 3);
raw_sta_walk  = mean(all_raw_sta_walk, 3);
raw_tar_walk  = mean(all_raw_tar_walk, 3);

error_raw_sta_stand = std(all_raw_sta_stand, [], 3) / sqrt(size(all_raw_sta_stand,3));
error_raw_tar_stand = std(all_raw_tar_stand, [], 3) / sqrt(size(all_raw_tar_stand,3));
error_raw_sta_walk  = std(all_raw_sta_walk,  [], 3) / sqrt(size(all_raw_sta_walk,3));
error_raw_tar_walk  = std(all_raw_tar_walk,  [], 3) / sqrt(size(all_raw_tar_walk,3));

lo_raw_sta_stand = raw_sta_stand - error_raw_sta_stand;
hi_raw_sta_stand = raw_sta_stand + error_raw_sta_stand;

lo_raw_tar_stand = raw_tar_stand - error_raw_tar_stand;
hi_raw_tar_stand = raw_tar_stand + error_raw_tar_stand;

lo_raw_sta_walk = raw_sta_walk - error_raw_sta_walk;
hi_raw_sta_walk = raw_sta_walk + error_raw_sta_walk;

lo_raw_tar_walk = raw_tar_walk - error_raw_tar_walk;
hi_raw_tar_walk = raw_tar_walk + error_raw_tar_walk;

topo_raw_sta_stand = cat(2, ERP_raw(1).sta_stand_topo, ERP_raw(2).sta_stand_topo);
topo_raw_tar_stand = cat(2, ERP_raw(1).tar_stand_topo, ERP_raw(2).tar_stand_topo);
topo_raw_sta_walk  = cat(2, ERP_raw(1).sta_walk_topo,  ERP_raw(2).sta_walk_topo);
topo_raw_tar_walk  = cat(2, ERP_raw(1).tar_walk_topo,  ERP_raw(2).tar_walk_topo);

for idx = 3:14
    topo_raw_sta_stand = cat(2, topo_raw_sta_stand, ERP_raw(idx).sta_stand_topo);
    topo_raw_tar_stand = cat(2, topo_raw_tar_stand, ERP_raw(idx).tar_stand_topo);
    topo_raw_sta_walk  = cat(2, topo_raw_sta_walk,  ERP_raw(idx).sta_walk_topo);
    topo_raw_tar_walk  = cat(2, topo_raw_tar_walk,  ERP_raw(idx).tar_walk_topo);
end

topo_raw_sta_stand_mean = mean(topo_raw_sta_stand, 2);
topo_raw_tar_stand_mean = mean(topo_raw_tar_stand, 2);
topo_raw_sta_walk_mean  = mean(topo_raw_sta_walk,  2);
topo_raw_tar_walk_mean  = mean(topo_raw_tar_walk,  2);


%% Plot – Grand Average ERPs (2x3)

x = ERP(1).times';
f = figure('Color','w');

ylims = [-4 8];


% Standing – iCC
subplot_handle = subplot(2,3,1);
plot_erp_panel(x, ...
    mean(all_ICC_sta_stand,3), mean(all_ICC_tar_stand,3), ...
    lo_ICC_sta_stand, hi_ICC_sta_stand, ...
    lo_ICC_tar_stand, hi_ICC_tar_stand, ...
    topo_ICC_tar_stand_mean - topo_ICC_sta_stand_mean, ...
    ERP(1).chanlocs, ...
    'Standing – iCC', ylims);

% Walking – iCC
subplot_handle = subplot(2,3,4);
plot_erp_panel(x, ...
    mean(all_ICC_sta_walk,3), mean(all_ICC_tar_walk,3), ...
    lo_ICC_sta_walk, hi_ICC_sta_walk, ...
    lo_ICC_tar_walk, hi_ICC_tar_walk, ...
    topo_ICC_tar_walk_mean - topo_ICC_sta_walk_mean, ...
    ERP(1).chanlocs, ...
    'Walking – iCC', ylims);


% Standing – Trad
subplot_handle = subplot(2,3,2);
plot_erp_panel(x, ...
    mean(all_trad_sta_stand,3), mean(all_trad_tar_stand,3), ...
    lo_trad_sta_stand, hi_trad_sta_stand, ...
    lo_trad_tar_stand, hi_trad_tar_stand, ...
    topo_trad_tar_stand_mean - topo_trad_sta_stand_mean, ...
    ERP(1).chanlocs, ...
    'Standing – Trad', ylims);

% Walking – Trad
subplot_handle = subplot(2,3,5);
plot_erp_panel(x, ...
    mean(all_trad_sta_walk,3), mean(all_trad_tar_walk,3), ...
    lo_trad_sta_walk, hi_trad_sta_walk, ...
    lo_trad_tar_walk, hi_trad_tar_walk, ...
    topo_trad_tar_walk_mean - topo_trad_sta_walk_mean, ...
    ERP(1).chanlocs, ...
    'Walking – Trad', ylims);


% Standing – Raw
subplot_handle = subplot(2,3,3);
plot_erp_panel(x, ...
    mean(all_raw_sta_stand,3), mean(all_raw_tar_stand,3), ...
    lo_raw_sta_stand, hi_raw_sta_stand, ...
    lo_raw_tar_stand, hi_raw_tar_stand, ...
    topo_raw_tar_stand_mean - topo_raw_sta_stand_mean, ...
    ERP(1).chanlocs, ...
    'Standing – MinProc', ylims);

% Walking – Raw
subplot_handle = subplot(2,3,6);
plot_erp_panel(x, ...
    mean(all_raw_sta_walk,3), mean(all_raw_tar_walk,3), ...
    lo_raw_sta_walk, hi_raw_sta_walk, ...
    lo_raw_tar_walk, hi_raw_tar_walk, ...
    topo_raw_tar_walk_mean - topo_raw_sta_walk_mean, ...
    ERP(1).chanlocs, ...
    'Walking – MinProc', ylims);


% Global labels
sgtitle('Participants – P3 at Pz','FontSize',14)

han = axes(gcf,'visible','off');
han.XLabel.Visible = 'on';
han.YLabel.Visible = 'on';
xlabel(han,'Time [ms]','FontSize',12);
ylabel(han,'Amplitude [\muV]','FontSize',12);

exportgraphics(f,'GrandAverage-Pz_ERPs_2x3.png','Resolution',300);