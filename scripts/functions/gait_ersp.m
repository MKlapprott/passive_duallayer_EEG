function [Gait_avg, ERDS, GPM, cycle_cnt, si, cycle_len_sec, hFig] = gait_ersp(EEG_block, F_Rest,...
    N_freq, f_axis, FWHM,...
    gait_event,gait_timeNextHs, gait_event_order, sub, cond)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% add documentation here

% length criteria

minCycleDur = 0.4;   % seconds
maxCycleDur = 3.0;   % seconds

minCycleSamp = minCycleDur * EEG_block.srate;
maxCycleSamp = maxCycleDur * EEG_block.srate;

N_chan = EEG_block.nbchan;
timeNextHs = gait_timeNextHs*EEG_block.srate;                                                       % time of next RHS in s

% data preparation -------------------------------------------------------------------------------

data = permute(EEG_block.data, [2, 1]); %                                                            pnts x chans! --> BS way?
data = bsxfun(@minus, data, mean(data,2));                                                          % CAR (common average refrence), make sure you have 'clean' data before

% time frequency transform -----------------------------------------------------------------------
TF = morlet_transform_fast(data,[0,1/EEG_block.srate],f_axis,1, FWHM,'n');
TF = abs(TF);                                                                                       %take magnitude (not power), pnts x chans x freqs

idxHS = find(strcmp({EEG_block.event.type}, gait_event));                                           % identify gait cycles
idxHS = idxHS(2:end-1);                                                                             % delete first and last one
Gait_TF = zeros(length(idxHS)-1,100,N_chan*N_freq);                                                 % strides/trials x pnts x chans x freqs


si = 1;                                                                                             % step counter, increased for each valid step
for cycle_cnt = 1:length(idxHS)-1                                                                   % resample each stride to the same legth (100 pnts)
    
    % find first and last sample of stride  
    cycle_edge = round([EEG_block.event(idxHS(cycle_cnt)).latency,...
        EEG_block.event(idxHS(cycle_cnt+1)).latency-1]);                                            % first and last frame of gait cycle
    cycle_event = {EEG_block.event([idxHS(cycle_cnt):idxHS(cycle_cnt+1)]).type};                    % labels of all events within this cycle

    % find out how long origiinal epochs are?
    epoch_length_samples(cycle_cnt) = cycle_edge(2) - cycle_edge(1) + 1;
    cycle_len(cycle_cnt) = epoch_length_samples(cycle_cnt) / EEG_block.srate;
    
    % only keep labels of gait events to check their order:
    cycle_gaitEvent = cycle_event(contains(cycle_event,gait_event_order));
   
    if gait_timeNextHs(1) <= cycle_edge(2)-cycle_edge(1) &&...                                      % check time until next HS
            cycle_edge(2)-cycle_edge(1) <= timeNextHs(2) &&...
            cycle_len(cycle_cnt) >= minCycleDur && ...
            cycle_len(cycle_cnt) <= maxCycleDur && ...
            all(ismember(gait_event_order,cycle_gaitEvent)) && ...                                  % oder of gait events correct
            all(EEG_block.etc.valid_eeg(cycle_edge(1):cycle_edge(2)))                               % no high amplitude samples
        
        cycle_len_sec(si) = cycle_len(cycle_cnt);
        TF_cycle = TF(cycle_edge(1):cycle_edge(2),:,:);                                             % extract data
        TF_cycle = reshape(TF_cycle,size(TF_cycle,1),N_chan*N_freq);                                % reshape to be able to use the resample function
        Gait_TF(si,:,:) = resample(TF_cycle,100,cycle_edge(2)-cycle_edge(1)+1,0);                   % resample to 100 samples and store
        si = si+1;

        % sanity check

        cycle_events = EEG_block.event(idxHS(cycle_cnt):idxHS(cycle_cnt+1));

        event_lat = [cycle_events.latency] - cycle_edge(1);
        event_type = {cycle_events.type};
        
        % Convert to % gait cycle
        event_pct = event_lat / (cycle_edge(2)-cycle_edge(1)) * 100;

    end
end
disp([num2str(round(si/cycle_cnt*100)) '% of the gait cycles are valid'])

% Gait_TF now: strides/trials x pnts + chans x freqs
Gait_TF = reshape(Gait_TF,size(Gait_TF,1),100,N_chan,N_freq);                                       % reshape to trials x pnts x chans x freqs
Gait_avg = squeeze(mean(Gait_TF));                                                                  % average over trials

ERDS = 20*bsxfun(@minus,log10(Gait_avg), log10(F_Rest));                                            % baseline correct to dB power change to standing baseline (also called ERSP)
GPM = bsxfun(@minus,ERDS,mean(ERDS));                                                               % further baseline correct to dB change to mean gait cycle baseline (aka gait power modulation)

% sanity check figures

hFig = figure;
histogram(cycle_len_sec, 30)
xlabel('Gait cycle duration (s)')
ylabel('Count')
title(['Distribution of gait cycle durations', sub, ': ', cond])


end

