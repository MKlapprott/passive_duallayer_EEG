function [pks, locs, data] = std_findsteps(data, fs, promi, filter, norm, plotit);
% count_steps() - count steps in gyro or accelerometer data, using findpeaks
%
% Usage: >> [pks, locs, data] = std_findsteps(data, fs, promi, filter, norm, plotit);
%        >> [pks, locs, data] = std_findsteps(data, fs);
%
% Inputs:
%   data     - IMU vector 
%   fs       - sampling rate (Hz)
%   filter   - Flag 0 or 1 (default). If 1 applies 2 Hz IIR low-pass filter
%   promi    - Default is 1.5, should work for normalized data. Value is the 
%              minimum peak prominence in findpeaks.m
%   norm     - Flag 0 or 1 (default). If 1 applies z-transform of data
%   plotit   - Flag 1 or 0 (default). If 1 plots data with identified peaks 
%
% Outputs:
%   pks      - vector with peak amplitudes
%   locs     - vector with peak indices
%   data     - filtered and normalized data vector (if filter =1 and norm = 1)
%
% std, 28 nov 2017
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% default inputs
if nargin < 2
    error('Provide data and sampling rate'); end
if nargin < 3
    promi =  1.5; end
if nargin < 4
    filter =  1; end
if nargin < 5
    norm = 1; end
if nargin < 6
    plotit = 0; end


% change sign if neccessary, make sign of largest abs value positive
si = sign(data(abs(data) == max(abs(data))));
data = si(1)*data;

% normalize
if norm
    data = zscore(data);
end

% low pass filter 
if filter
    lpf = 2; % in Hz
    order = 10;
    cutoff = lpf*2/fs;
    [b,a] = butter(order,cutoff,'low');% fvtool(b,a)
    data = filtfilt(b,a,data);
end

% find peaks
[pks, locs] = findpeaks(data,'MinPeakProminence', promi);


% plot result
if plotit
    figure;
    plot(data, '-v', 'MarkerIndices', locs, 'MarkerSize', 8);
    title(['Number of peaks: ', num2str(length(pks))]);
end


        
        
      
