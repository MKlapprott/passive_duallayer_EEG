function plot_panel(nr,nc,idx,x,sta,tar,lo_sta,hi_sta,lo_tar,hi_tar,topo_diff,chanlocs,ttl,ylims)

subplot(nr,nc,idx)
subplot_pos = get(gca,'Position');
iw = 0.3 * subplot_pos(3);
ih = 0.3 * subplot_pos(4);

hold on

hp = patch([x; x(end:-1:1); x(1)], [lo_sta'; hi_sta(end:-1:1)'; lo_sta(1)], 'b');
set(hp,'EdgeColor','none','FaceAlpha',0.1)
hp.Annotation.LegendInformation.IconDisplayStyle = 'off';
plot(x,sta,'b')

hp = patch([x; x(end:-1:1); x(1)], [lo_tar'; hi_tar(end:-1:1)'; lo_tar(1)], 'r');
set(hp,'EdgeColor','none','FaceAlpha',0.1)
hp.Annotation.LegendInformation.IconDisplayStyle = 'off';
plot(x,tar,'Color',[0.85 0.325 0.098],'LineWidth',1.1)

ylim(ylims)
xline(0,'--'); yline(0)
title(ttl,'FontSize',10)

ul = [subplot_pos(1)+0.06, subplot_pos(2)+subplot_pos(4)-ih-0.04, iw, ih];
ax = axes('Position',ul);
topoplot(topo_diff,chanlocs,'electrodes','off');
axis tight
set(ax,'XColor','none','YColor','none')
end