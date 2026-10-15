%% duallayer2_human_10_gaitDetection.m
%
% PURPOSE
%   Detect gait events from right-foot-mounted IMU recordings and estimate
%   walking speed during hallway walking trials. The script processes
%   EEGLAB datasets (.set) containing EEG and IMU data.
%
% DATA
%   - IMU sensor mounted on the right foot.
%   - Three accelerometer channels and three gyroscope channels.
%   - Original IMU sampling frequency: 50 Hz; data are stored in datasets
%     resampled to the EEG sampling frequency (currently 250 Hz).
%   - Walking takes place along a 25 m outdoor hallway.
%   - Walking tasks include dual-task and walking-only conditions.
%
% PROCESSING OVERVIEW
%   1. Load participant information and EEGLAB datasets.
%   2. Select the IMU channels and filter the sensor signals.
%   3. Estimate the active walking interval from accelerometer movement
%      intensity, excluding inactive periods at the beginning and end.
%   4. Retain walking blocks separated by short breaks within the detected
%      overall walking interval.
%   5. Detect turns from abrupt changes in the selected gyroscope signal.
%   6. Apply a minimum temporal separation between detected turns to reduce
%      duplicate detections.
%   7. Estimate total walking distance from the number of detected turns
%      and the known hallway length.
%   8. Calculate average walking speed in km/h.
%   9. Detect right heel strikes (RHS) and right toe-offs (RTO), validate
%      gait-event sequences, and save the resulting EEGLAB datasets.
%  10. Store gait-event statistics and speed estimates for later analysis.
%
% WALKING INTERVAL DETECTION
%   - The accelerometer signals are high-pass filtered to reduce slow
%     components, including much of the gravitational contribution.
%   - Movement intensity is calculated from the combined three-axis
%     acceleration signal using a moving RMS measure.
%   - A threshold is used to distinguish active movement from low movement.
%   - Short inactive gaps can be bridged to accommodate brief pauses.
%   - The first and last detected active segments define the overall
%     walking interval.
%   - Detected boundaries should be visually inspected for quality control.
%
% TURN DETECTION AND SPEED ESTIMATION
%   - Turns are identified from changes in the local mean of the selected
%     gyroscope signal, rather than from isolated signal peaks.
%   - A minimum time interval between detections reduces duplicate turns.
%   - The hallway length is assumed to be 25 m.
%   - Estimated distance is calculated as:
%         distance = (number of detected turns + 1) * hallway length
%   - Average speed is calculated as:
%         speed (km/h) = distance (m) / duration (s) * 3.6
%   - This distance formula assumes that the participant starts at one
%     hallway endpoint, completes a full traverse between successive turns,
%     and finishes after a final full traverse.
%   - Speed estimates depend on accurate turn detection, correct trial
%     boundaries, and the start/end-position assumptions. They should be
%     checked against the sensor plots and trial protocol.
%
% GAIT-EVENT DETECTION
%   - Candidate steps are identified from peaks in filtered acceleration.
%   - Right heel strikes and right toe-offs are added as EEGLAB events.
%   - Gait-event sequences are evaluated using validStrides().
%   - Event detection depends on the sensor orientation, channel mapping,
%     signal quality, and the selected thresholds.
%
% IMPORTANT PARAMETERS
%   - Hallway length: 25 m.
%   - Accelerometer high-pass cutoff: 0.3 Hz.
%   - Movement-intensity window: 0.5 s.
%   - Turn-detection smoothing window: 0.08 s.
%   - Turn-detection comparison window: 0.25 s.
%   - Minimum separation between turns: configurable in the script.
%   - Gait-event filters and peak-detection thresholds are configurable.
%
% OUTPUTS
%   - EEGLAB datasets with detected gait events.
%   - Per-participant stride counts and validity statistics.
%   - Estimated walking speed for each processed dataset.
%   - Diagnostic plots for walking-interval and turn detection.
%
% LIMITATIONS AND QUALITY CONTROL
%   - Resampling from 50 Hz to 250 Hz does not increase the original
%     information content of the IMU signal.
%   - Threshold-based walking and turn detection may require adjustment
%     and visual verification across participants.
%   - A gyroscope transition may reflect stopping or repositioning rather
%     than a genuine hallway turn.
%   - Including breaks in the duration estimates overall trial-average
%     speed; excluding breaks estimates speed during active walking.
%   - Counting turns does not independently establish the exact distance
%     of partial first or last traverses.
%   - Results should be interpreted as estimates, not direct measurements.
%
% Author: Melanie, 2026


%% Preparations


close all; clear all; clc;                                                                          % start with fresh workspace

% set paths
MAINPATH = 'Q:\Neuro\data\projects\all_gait\dual-layerCap\dual-layer-2024_25\eegl\';                % adjust this path to your local environment!!!
cd(MAINPATH)

PATHIN = [MAINPATH, 'rawdata\participants\'];                                                       % path to raw data
PATHOUT = [MAINPATH, 'derivatives\participants\']; 
GAITPATH = [PATHOUT, 'duallayer2_human_07_gait_data\'];

load('SUBS.mat');

% gait parameters
gait_event_order = {'RHS', 'RTO', 'RHS'};
gait_timeNextHs = [.5 1.5];
Step_thresh = 10;
minPeakDist = 0.5;

% filter settings
LPF1 = 6; LPF2 = 30; Order = 2; srate = 250;
[b_low1,a_low1]=butter(Order,LPF1/(srate/2),'low');
[b_low2,a_low2]=butter(Order,LPF2/(srate/2),'low');

%%


for sub = 2:length(SUB)

    % special treatment for our special snowflakes -----------------------------------------------

    if strcmp(SUB(sub).ID, 'sub_03') || strcmp(SUB(sub).ID, 'sub_06') || strcmp(SUB(sub).ID, 'sub_07') || ...
            strcmp(SUB(sub).ID, 'sub_11') || strcmp(SUB(sub).ID, 'sub_12') || ...
            strcmp(SUB(sub).ID, 'sub_13') || strcmp(SUB(sub).ID, 'sub_15')


        disp('Something went wrong with the IMUs here, so we skip this :`)...')
        
    else

        SUBGAITPATH = [GAITPATH, SUB(sub).ID, '\'];
        cd(SUBGAITPATH)                                                                             % set filepath
        files = dir(fullfile(SUBGAITPATH, '*.set'));                                                % get access to data sets
    
        for file = 1%:length(files)

            [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;                                             % start EEGLAB
        
            file_name = files(file).name;                                                           % get current file name
            EEG = pop_loadset('filename',file_name,'filepath',SUBGAITPATH);
            EEG.setname = file_name(1:end-4);
            [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);                                     % store data set

            % focus on IMU channels --------------------------------------------------------------
    
            Acc = pop_select(EEG, 'nochannel', [1:32]);                                             % keep only IMU channels
    
            data = detrend(double(Acc.data'));                                                      % detrending
            data2 = filtfilt(b_low2,a_low2, data);                                                  % 30 Hz
            Acc.data = data2';
            data = filtfilt(b_low1,a_low1, data);                                                   % 6 Hz
            Acc2.data = data';
            
            
            if contains(EEG.setname, 'walk_dual')
                all_starts = find(strcmp({EEG.event.type}, '1 instruction'));
                all_ends = find(strcmp({EEG.event.type}, '5 end_block'));
                START = EEG.event(all_starts(1)).latency-10;
                TO = EEG.event(all_ends(end)).latency+10;
            elseif contains(EEG.setname, 'walk_only')
                all_starts = find(strcmp({EEG.event.type}, 'boundary'));
                all_ends = find(strcmp({EEG.event.type}, '1 instruction'));
                START = EEG.event(all_starts).latency-10;
                TO = EEG.event(all_ends(end)).latency+10;
            end

          
            if contains(EEG.setname, 'walk_dual')

                 % walking phase detection ------------------------------------------------------------

                fs = double(EEG.srate);
    
                % Find the three accelerometer channels by label
                accLabels = {'rightFootAcc1', 'rightFootAcc2', 'rightFootAcc3'};
                accIdx = zeros(1,3);
                
                for k = 1:3
                    idx = find(strcmpi({EEG.chanlocs.labels}, accLabels{k}), 1);
                    if isempty(idx)
                        error('Accelerometer channel "%s" not found.', accLabels{k});
                    end
                    accIdx(k) = idx;
                end
                
                % Extract accelerometer data from the full recording
                acc = double(EEG.data(accIdx, :));
                
                % Remove slow components, including much of the gravity component
                [bHP, aHP] = butter(2, 0.3/(fs/2), 'high');
                accHP = filtfilt(bHP, aHP, acc')';
                
                % Overall movement intensity across all three axes
                accMagnitude = sqrt(sum(accHP.^2, 1));
                
                % Smooth by calculating RMS movement in short windows
                windowSec = 0.5;
                windowN = max(1, round(windowSec * fs));
                
                movementIntensity = sqrt(movmean(accMagnitude.^2, windowN));
                
                % ADAPTIVE THRESHOLD
                
                % Ensure the threshold is not effectively zero
                threshold = 10;
                
                active = movementIntensity > threshold;
                
                % CLEAN UP THE ACTIVE MASK
                
                % Fill short inactive gaps within walking
                maxGapSec = 35;  % allow breaks up to 3 seconds
                maxGapN = round(maxGapSec * fs);
                
                inactiveRuns = diff([false, ~active, false]);
                gapStarts = find(inactiveRuns == 1);
                gapEnds = find(inactiveRuns == -1) - 1;
                
                for k = 1:numel(gapStarts)
                    gapLength = gapEnds(k) - gapStarts(k) + 1;
                
                    if gapLength <= maxGapN && ...
                       gapStarts(k) > 1 && gapEnds(k) < numel(active)
                
                        if active(gapStarts(k)-1) && active(gapEnds(k)+1)
                            active(gapStarts(k):gapEnds(k)) = true;
                        end
                    end
                end
                
                % Find all active segments
                edges = diff([false, active, false]);
                segmentStarts = find(edges == 1);
                segmentEnds = find(edges == -1) - 1;
                
                if isempty(segmentStarts)
                    error('No active interval detected. Inspect the activity plot.');
                end
                
                % Keep segments lasting at least 2 seconds
                minActiveSec = 2;
                validSegments = ...
                    (segmentEnds - segmentStarts + 1) >= round(minActiveSec * fs);
                
                segmentStarts = segmentStarts(validSegments);
                segmentEnds = segmentEnds(validSegments);
                
                if isempty(segmentStarts)
                    error('No sufficiently long active segments detected.');
                end
                
                % Merge the walking blocks by taking the first start and last end
                walkStart = segmentStarts(1);
                walkEnd = segmentEnds(end);
                
                % Ignore very short activity bursts
                minActiveSec = 3;
                validSegments = (segmentEnds - segmentStarts + 1) >= minActiveSec * fs;
                segmentStarts = segmentStarts(validSegments);
                segmentEnds = segmentEnds(validSegments);
                
                if isempty(segmentStarts)
                    error('No sufficiently long active interval detected. Adjust the threshold.');
                end
                
                % Select the longest continuous active interval
                [~, longestIdx] = max(segmentEnds - segmentStarts + 1);
                walkStart = segmentStarts(longestIdx);
                walkEnd = segmentEnds(longestIdx);
                
                % DISPLAY DETECTED INTERVAL
                
                timeSec = (0:EEG.pnts-1) / fs;
                
                figure('Color','w');
                
                subplot(2,1,1);
                plot(timeSec, accMagnitude);
                hold on;
                xline(timeSec(walkStart), 'g--', 'Start walking');
                xline(timeSec(walkEnd), 'r--', 'End walking');
                xlabel('Time (s)');
                ylabel('High-pass acceleration magnitude');
                title('Accelerometer movement');
                grid on;
                
                subplot(2,1,2);
                plot(timeSec, movementIntensity);
                hold on;
                yline(threshold, 'k--', 'Threshold');
                xline(timeSec(walkStart), 'g--');
                xline(timeSec(walkEnd), 'r--');
                xlabel('Time (s)');
                ylabel('Movement intensity');
                title('Detected walking interval');
                grid on;

                % find turns and estimate walking speed ----------------------------------------------
    
                gyro = double(Acc2.data(6, walkStart:walkEnd));
                gyro = gyro(:);
                
                walkingDurationSec = numel(gyro) / fs;
    
                % Tune these parameters after inspecting the plot
                smoothWindowSec = 0.08;
                comparisonWindowSec = 0.25;
                minTurnSeparationSec = 2.5;
                
                % Minimum change in local mean, in deg/s
                changeThreshold = 50;  % starting value; tune to your data
                
                % Smooth the signal
                smoothN = max(1, round(smoothWindowSec * srate));
                gyroSmooth = movmean(gyro, smoothN);
                
                % Compare mean before and after each sample
                windowN = max(1, round(comparisonWindowSec * srate));
                
                meanBefore = movmean(gyroSmooth, [2*windowN-1 0]);
                meanAfter  = movmean(gyroSmooth, [0 2*windowN-1]);
                
                % Difference between the local means
                baselineChange = abs(meanAfter - meanBefore);
                
                % Find candidate change points
                candidateSamples = find(baselineChange > changeThreshold);
                
                % Collapse consecutive threshold crossings into one candidate
                if ~isempty(candidateSamples)
                
                    groupBreaks = find(diff(candidateSamples) > 1);
                    groupStart = [1; groupBreaks(:) + 1];
                    groupEnd = [groupStart(2:end) - 1; numel(candidateSamples)];
                
                    turnSamples = zeros(numel(groupStart), 1);
                
                    for k = 1:numel(groupStart)
                        group = candidateSamples(groupStart(k):groupEnd(k));
                
                        [~, ix] = max(baselineChange(group));
                        turnSamples(k) = group(ix);
                    end
                
                    % Enforce minimum separation
                    minSepN = round(minTurnSeparationSec * srate);
                    keep = true(size(turnSamples));
                
                    for k = 2:numel(turnSamples)
                        if turnSamples(k) - turnSamples(k-1) < minSepN
                            if baselineChange(turnSamples(k)) > ...
                                    baselineChange(turnSamples(k-1))
                                keep(k-1) = false;
                            else
                                keep(k) = false;
                            end
                        end
                    end
                
                    turnSamples = turnSamples(keep);
                
                else
                    turnSamples = [];
                end
    
                % validate turns
    
                minTurnSeparationSec = 15;  % initial value; adjust after inspection
                minSepSamples = round(minTurnSeparationSec * fs);
                
                if ~isempty(turnSamples)
                
                    % Ensure chronological order
                    turnSamples = sort(turnSamples(:));
                
                    keep = true(size(turnSamples));
                    lastKept = 1;
                
                    for k = 2:numel(turnSamples)
                
                        if turnSamples(k) - turnSamples(lastKept) < minSepSamples
    
                            keep(k) = false;
                            
                        end
                        lastKept = k;
                    end
                
                    turnSamples = turnSamples(keep);
                end
                            
                turnTimes = (turnSamples - 1) / srate;
                nTurns = numel(turnSamples);
                
                % PLOT RESULTS
                timeSec = (0:numel(gyro)-1) / srate;
                
                figure('Color','w');
                
                subplot(2,1,1);
                plot(timeSec, gyro, 'Color', [0.65 0.65 0.65]);
                hold on;
                plot(timeSec, gyroSmooth, 'b');
                if ~isempty(turnSamples)
                    xline(turnTimes, 'r--');
                end
                ylabel('Gyroscope (deg/s)');
                title('Gyroscope signal and detected turns');
                legend('Raw signal', 'Smoothed signal', 'Location', 'best');
                grid on;
                
                subplot(2,1,2);
                plot(timeSec, baselineChange, 'k');
                hold on;
                yline(changeThreshold, 'b--', 'Threshold');
                if ~isempty(turnSamples)
                    xline(turnTimes, 'r--');
                end
                xlabel('Time (s)');
                ylabel('Baseline change (deg/s)');
                title(sprintf('Detected change points: %d', nTurns));
                grid on;
                
                fprintf('Detected turns: %d\n', nTurns);
    
    
                hallwayLength = 25;
                walkingDurationSec = sum(segmentEnds - segmentStarts + 1) / fs;
                nTraverses = nTurns + 1;
                
                estimatedDistanceM = nTraverses * hallwayLength;
                estimatedSpeedMps = estimatedDistanceM / walkingDurationSec;
                estimatedSpeedKmh = estimatedSpeedMps * 3.6;
    
                speeds(sub) = estimatedSpeedKmh;
            end


            % find peaks in vertical acceleration (2nd Acc channel) ------------------------------
    
            [~, idxMS] =findpeaks(Acc2.data(2,:), 'MinPeakHeight', Step_thresh,'minPeakDist', minPeakDist*Acc.srate); % identify peaks in 6Hz filtered data
            %findpeaks(Acc2.data(2,:), 'MinPeakHeight', Step_thresh,'minPeakDist', minPeakDist*Acc.srate)


            for ev = 2:length(idxMS)-1                                                              %loop through all peaks

                FROM = idxMS(ev)-.2*Acc.srate;

                % HEAL STRIKE: find peak in the 30 Hz LPF filtered vertical acceleration signal in
                % the surronding 200 ms

                tmp = Acc.data(2, FROM : FROM+.2*Acc.srate);                                        % use 30Hz filtered data for event making 
                [maxVal, idxHS] = max(tmp);

                if ~isempty(idxHS)                                                                  % if present add as event
                    EEG.event(end+1).type = 'RHS';
                    EEG.event(end).latency = START+FROM+idxHS;
                    EEG.event(end).duration = 1;
                end

                % TOE OFF: get AP acceleration of half a second before ---------------------------

                shift =.5*Acc.srate;
                tmp = Acc.data(2, START+FROM+idxHS-shift : START+FROM+idxHS);                       % use 30Hz filtered data for event making 

                [~, idxTO] = findpeaks(tmp, 'NPeaks', 2, 'SortStr' ,'descend');                     %find two highest peaks

                if ~isempty(idxTO)
                    EEG.event(end+1).type = 'RTO';                                                  % if present add as event
                    EEG.event(end).latency = START+FROM-shift+mean(idxTO);                          % get mean position as TO estimate
                    EEG.event(end).duration = 1;
                end
                clearvars idxIC idxTO
            end


            EEG = eeg_checkset(EEG, 'eventconsistency');                                             % sort events by latency

            % check for validity -----------------------------------------------------------------

            evalc('EEG = pop_select(EEG, ''point'', [START TO]);');   
            EEG.etc.valid_eeg = true(1, EEG.pnts);
            [EEG.etc.strides.number,EEG.etc.strides.numValid] = validStrides(EEG, gait_event_order,gait_timeNextHs);

            pause(3)

            SUB(sub).strides.number(file) = EEG.etc.strides.number;
            SUB(sub).strides.percValid(file) = EEG.etc.strides.numValid;

            SUBGAITPATHOUT = [GAITPATH, SUB(sub).ID '\step_events\'];
            if ~isfolder(SUBGAITPATHOUT)    
                mkdir(SUBGAITPATHOUT)
            end

            EEG.setname = [EEG.setname,'_steps'];
            [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);                                     % store data set
            EEG = pop_saveset(EEG, 'filename', EEG.setname, 'filepath', SUBGAITPATHOUT);            % save data set
    
        end                                                                                         % end loop across iCC files
        % SUB(sub).strides.file_order = {'iCC_dual', 'iCC_only', 'trad_dual', 'trad_only'};
    end                                                                                             % end sorting out subs  
end                                                                                                 % end loop across subjects


%% save struct!

save([MAINPATH,'SUBS'],'SUB');                                                                      % save information

real_speeds = nonzeros(speeds);

mean_speeds = mean(real_speeds);