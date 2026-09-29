function plot_erp_panel(x, sta, tar, lo_sta, hi_sta, lo_tar, hi_tar, topo_diff, chanlocs, ttl, ylims)

subplot_pos = get(gca,'Position');
inset_w = 0.35 * subplot_pos(3);
inset_h = 0.35 * subplot_pos(4);

hold on

% SEM – Standard
hp = patch([x; x(end:-1:1); x(1)], ...
           [lo_sta'; hi_sta(end:-1:1)'; lo_sta(1)], 'b');
set(hp,'EdgeColor','none','FaceAlpha',0.1);
hp.Annotation.LegendInformation.IconDisplayStyle = 'off';

plot(x, sta, 'b')

% SEM – Target
hp = patch([x; x(end:-1:1); x(1)], ...
           [lo_tar'; hi_tar(end:-1:1)'; lo_tar(1)], 'r');
set(hp,'EdgeColor','none','FaceAlpha',0.1);
hp.Annotation.LegendInformation.IconDisplayStyle = 'off';

plot(x, tar, 'Color',[0.85 0.325 0.098],'LineWidth',1.1)

ylim(ylims)
xline(0,'--'); 
yline(0);

rectangle('Position',[300 ylims(1) 300 diff(ylims)], ...
          'FaceColor',[.5 .5 .5],'LineStyle','none','FaceAlpha',0.2)

title(ttl,'FontSize',11)

legend('Standard','Target')

% Topography inset
upper_left = [subplot_pos(1)-0.01, ...
              subplot_pos(2)+subplot_pos(4)-inset_h-0.04, ...
              inset_w, inset_h];

ax = axes('Position',upper_left);
topoplot(topo_diff, chanlocs, 'electrodes','off');
axis tight
set(ax,'XColor','none','YColor','none')
end