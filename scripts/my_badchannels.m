function my_badchannels(EEG, varargin)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

if length(varargin) == 4
    measurement_info = varargin{1};
    check = varargin{2};
    meas = varargin{3};
    noise_cond = varargin{4};

    title_str = ['Channel RMS for condition: ', ...
        measurement_info{meas, 'cond'}{1}, '_', ...
        check.noise_conds{noise_cond}];

    nchans = 31;

elseif length(varargin) == 2
     measurement_info = varargin{1};
     meas = varargin{2};

    title_str = ['Channel RMS for condition: ', ...
        measurement_info{meas, 'ID'}{1}];

    nchans = 32;
end

figure('Position', [100, 100, 500, 700]);
        
rms = std(EEG.data(1:size(EEG.data(1:nchans,:), 1),:), [],2);                               % calc standard deviation across channels
thres = mean(mean(rms)+3*std(rms));                                                     % define threshold for bad channel marking (take higher threshold??)
ind = find(rms>thres | rms<1);                                                          % find bits of data exceeding thres & flat channels

subplot(3, 1, 1);                                                                       % plot topo of channel stds
topoplot(rms, EEG.chanlocs(1:nchans));                                                      % topography of rms
colorbar;
title('Topography');
        
subplot(3, 1, 2);                                                                       % plot lines of channel stds with threshold
plot(rms, 'k');                                                                         % channels
hold on;
plot(repmat(thres,1,size(EEG.data(1:nchans,:), 1)), 'r');                                   % threshold
xlabel('Channels'); ylabel('rms')
plottitle = ['RMS per Channel'];
title(plottitle, 'Interpreter', 'none');
axis tight

% then, additionally, plot rms over time (image plot) for each subject and each run
% cut windows, calculate stds, plot in image

sec = 10;
LeWin = EEG.srate*sec;                                                                  % define window length
timeVec = 0 : 1/EEG.srate : sec-1/EEG.srate;                                            % define time vector
idx_loop = 1:LeWin:size(EEG.data(1:nchans,:),2);                                            % check how loop index will look like
rms_t = zeros(size(EEG.data(1:nchans,:), 1), length(idx_loop));                             % pre-allocate matrix of rms over time
row_count = 1;                                                                          % set counter

for idx = 1: LeWin: size(EEG.data(1:nchans,:),2)-LeWin                                      % go through data in steps of 10s
    
    signal = EEG.data(1:size(EEG.data(1:nchans,:), 1),idx:idx+(LeWin-1));                   % get short extract from data
    rms_t(:, row_count) = std(signal, [],2);                                            % calc standard deviation across channels
    row_count = row_count +1;                                                           % update counter

end

subplot(3, 1, 3)                                                        
imagesc(rms_t);                                                                         % colormap for channel stds over time
colorbar;
colormap(turbo);
xlabel('Time (10s windows)'); ylabel('Channels');

sgt = sgtitle(strrep(title_str, '_', ' '), 'Interpreter', 'none');
drawnow

end