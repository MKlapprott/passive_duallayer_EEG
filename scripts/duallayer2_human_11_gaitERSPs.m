%% duallayer2_human_11_gaitERSPs.m
%
%
%
%
% Author: Melanie, 2025


%% Preparations


close all; clear all; clc;                                                                          % start with fresh workspace

% set paths
MAINPATH = 'R:\Ferris-Lab\mklapprott\eegl\';                                                        % adjust this path to your local environment!!!
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

cond_order = {'ICC_WalkDual', 'ICC_WalkOnly', 'trad_WalkDual', 'trad_WalkOnly'};

%% start analysis

for sub = 1:length(SUB)

    % special treatment for our special snowflakes -----------------------------------------------

    if strcmp(SUB(sub).ID, 'sub_03') || strcmp(SUB(sub).ID, 'sub_06') || strcmp(SUB(sub).ID, 'sub_07') ...
            || strcmp(SUB(sub).ID, 'sub_09') || strcmp(SUB(sub).ID, 'sub_11') || strcmp(SUB(sub).ID, 'sub_12')

        disp('Something went wrong with the IMUs here, so we skip this :`)...')
        
    else

        % ICC ------------------------------------------------------------------------------------
        
        SUBGAITPATH = [GAITPATH, SUB(sub).ID, '\step_events\'];
        cd(SUBGAITPATH)                                                                             % set filepath
        files = dir(fullfile(SUBGAITPATH, '*.set'));                                                % get access to data sets
        [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;                                             % start EEGLAB

        for file = 1:length(files)

            file_name = files(file).name;                                                           % get current file name
            EEG = pop_loadset('filename',file_name,'filepath',SUBGAITPATH);
            EEG.setname = file_name(1:end-4);
            
            EEG = pop_eegfiltnew(EEG, 'hicutoff', 60);                                              % low-pass filter
            
            go_chans = EEG.chanlocs(strcmp({EEG.chanlocs.type},'EEG'));                             % mark EEG channels
            go_labels = {go_chans.labels};       
            EEG = pop_select( EEG, 'channel',go_labels);
            
            [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);                                     % store data set
        end

        % get baseline (mean TF of whole walking data)

        EEG = pop_mergeset( ALLEEG, [1 2], 0);                                                      % merge walk dual and walk only data
        [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);                                         % store data set     
        [BL(sub).F_Rest(1).dat, BL(sub).Noise_cov(1).dat] = baselineF(EEG, [4:2:60], 3);                      % chan x freq

        SUB(sub).chanlocs               = EEG.chanlocs;

        figure;
        subplot(131)
        topoplot(mean(BL(sub).F_Rest(1).dat(1,:, 4:5),3), SUB(sub).chanlocs)
        %imagesc([1:32], [4:2:60], squeeze(BL(idx).F_Rest(1).dat))
        %set(gca, 'YDir', 'normal')
        %ylabel('freq'); xlabel('chan')
        title(SUB(sub).ID)
        clim([0 1])
        cbar;

        subplot(132)
        topoplot(mean(BL(sub).F_Rest(1).dat(1,:, 11:12),3), SUB(sub).chanlocs)     
        clim([0 1])
        cbar;

        subplot(133)
        topoplot(mean(BL(sub).F_Rest(1).dat(1,:, 21:22),3), SUB(sub).chanlocs)     
        clim([0 1])
        cbar;
            
   
        % gait cycle ERSPs -----------------------------------------------------------------------

        % time-frequency transformation w/ morlet-wavelets -> DUAL
        [Gait_avg, ERSP, GPM, cycle_cnt, valid_cycle_cnt] = gait_ersp(ALLEEG(1), BL(sub).F_Rest(1).dat,...
            29, [4:2:60], 3, 'RHS', gait_timeNextHs, gait_event_order);

        [ERSP_corr, GPM_corr, PSC1, ~,V] = specPCAdenoising(ERSP);                                  % denoising: spectral PCA, Seeber et al., 2015
        
        % save all info together 
        
        SUB(sub).noise_cov(1).dat    = BL(sub).Noise_cov(1).dat;
        SUB(sub).F_Rest(1).dat       = BL(sub).F_Rest(1).dat;        
        SUB(sub).TF(1).dat           = Gait_avg;
        SUB(sub).ERSP_uncor(1).dat   = ERSP;
        SUB(sub).GPM_uncor(1).dat    = GPM;
        SUB(sub).ERSP(1).dat         = ERSP_corr;
        SUB(sub).GPM(1).dat          = GPM_corr;
        SUB(sub).PSC1(1).dat         = PSC1;        
        SUB(sub).numStrides(1)       = cycle_cnt;
        SUB(sub).numValidStrides(1)  = valid_cycle_cnt;
        SUB(sub).chanlocs               = EEG.chanlocs;

        % also store in dedicated ERSP struct for grand average (time x chan x frex x cond x sub)

        TMP.ERSP(:,:,:,1,sub)        = ERSP_corr;
        TMP.GPM(:,:,:,1,sub)         = GPM_corr;
        TMP.ERSP_uncor(:,:,:,1,sub)  = ERSP;
        TMP.GPM_uncor(:,:,:,1,sub)   = GPM;
        TMP.chanlocs                    = EEG.chanlocs;


        % time-frequency transformation w/ morlet-wavelets -> ONLY
        [Gait_avg, ERSP, GPM, cycle_cnt, valid_cycle_cnt] = gait_ersp(ALLEEG(2), BL(sub).F_Rest(1).dat,...
            29, [4:2:60], 3, 'RHS', gait_timeNextHs, gait_event_order);

        %[ERSP_corr, GPM_corr, PSC1, ~,V] = specPCAdenoising(ERSP);                                  % denoising: spectral PCA, Seeber et al., 2015
        
        % save all info together 
        
        SUB(sub).noise_cov(2).dat    = BL(sub).Noise_cov(1).dat;
        SUB(sub).F_Rest(2).dat       = BL(sub).F_Rest(1).dat;        
        SUB(sub).TF(2).dat           = Gait_avg;
        SUB(sub).ERSP_uncor(2).dat   = ERSP;
        SUB(sub).GPM_uncor(2).dat    = GPM;
        SUB(sub).ERSP(2).dat         = ERSP_corr;
        SUB(sub).GPM(2).dat          = GPM_corr;
        SUB(sub).PSC1(2).dat         = PSC1;        
        SUB(sub).numStrides(2)       = cycle_cnt;
        SUB(sub).numValidStrides(2)  = valid_cycle_cnt;

        % also store in dedicated ERSP struct for grand average (time x chan x frex x cond x sub)

        TMP.ERSP(:,:,:,2,sub)        = ERSP_corr;
        TMP.GPM(:,:,:,2,sub)         = GPM_corr;
        TMP.ERSP_uncor(:,:,:,2,sub)  = ERSP;
        TMP.GPM_uncor(:,:,:,2,sub)   = GPM;



        % TRAD -----------------------------------------------------------------------------------
        
        % get baseline (mean TF of whole walking data)

        EEG = pop_mergeset( ALLEEG, [3 4], 0);                                                      % merge walk dual and walk only data
        [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);                                         % store data set     
        [BL(sub).F_Rest(2).dat, BL(sub).Noise_cov(2).dat] = baselineF(EEG, [4:2:60], 3);                      % chan x freq

            
        % gait cycle ERSPs -----------------------------------------------------------------------

        % time-frequency transformation w/ morlet-wavelets -> DUAL
        [Gait_avg, ERSP, GPM, cycle_cnt, valid_cycle_cnt] = gait_ersp(ALLEEG(3), BL(sub).F_Rest(2).dat,...
            29, [4:2:60], 3, 'RHS', gait_timeNextHs, gait_event_order);

        %[ERSP_corr, GPM_corr, PSC1, ~,V] = specPCAdenoising(ERSP);                                  % denoising: spectral PCA, Seeber et al., 2015
        
        % save all info together 
        
        SUB(sub).noise_cov(3).dat    = BL(sub).Noise_cov(2).dat;
        SUB(sub).F_Rest(3).dat       = BL(sub).F_Rest(2).dat;        
        SUB(sub).TF(3).dat           = Gait_avg;
        SUB(sub).ERSP_uncor(3).dat   = ERSP;
        SUB(sub).GPM_uncor(3).dat    = GPM;
        SUB(sub).ERSP(3).dat         = ERSP_corr;
        SUB(sub).GPM(3).dat          = GPM_corr;
        SUB(sub).PSC1(3).dat         = PSC1;        
        SUB(sub).numStrides(3)       = cycle_cnt;
        SUB(sub).numValidStrides(3)  = valid_cycle_cnt;
        SUB(sub).chanlocs               = EEG.chanlocs;

        % also store in dedicated ERSP struct for grand average (time x chan x frex x cond x sub)

        TMP.ERSP(:,:,:,3,sub)        = ERSP_corr;
        TMP.GPM(:,:,:,3,sub)         = GPM_corr;
        TMP.ERSP_uncor(:,:,:,3,sub)  = ERSP;
        TMP.GPM_uncor(:,:,:,3,sub)   = GPM;
        TMP.chanlocs                    = EEG.chanlocs;


        % time-frequency transformation w/ morlet-wavelets -> ONLY
        [Gait_avg, ERSP, GPM, cycle_cnt, valid_cycle_cnt] = gait_ersp(ALLEEG(4), BL(sub).F_Rest(2).dat,...
            29, [4:2:60], 3, 'RHS', gait_timeNextHs, gait_event_order);

        %[ERSP_corr, GPM_corr, PSC1, ~,V] = specPCAdenoising(ERSP);                                  % denoising: spectral PCA, Seeber et al., 2015
        
        % save all info together 
        
        SUB(sub).noise_cov(4).dat    = BL(sub).Noise_cov(2).dat;
        SUB(sub).F_Rest(4).dat       = BL(sub).F_Rest(2).dat;        
        SUB(sub).TF(4).dat           = Gait_avg;
        SUB(sub).ERSP_uncor(4).dat   = ERSP;
        SUB(sub).GPM_uncor(4).dat    = GPM;
        SUB(sub).ERSP(4).dat         = ERSP_corr;
        SUB(sub).GPM(4).dat          = GPM_corr;
        SUB(sub).PSC1(4).dat         = PSC1;        
        SUB(sub).numStrides(4)       = cycle_cnt;
        SUB(sub).numValidStrides(4)  = valid_cycle_cnt;

        % also store in dedicated ERSP struct for grand average (time x chan x frex x cond x sub)

        TMP.ERSP(:,:,:,4,sub)        = ERSP_corr;
        TMP.GPM(:,:,:,4,sub)         = GPM_corr;
        TMP.ERSP_uncor(:,:,:,4,sub)  = ERSP;
        TMP.GPM_uncor(:,:,:,4,sub)   = GPM;
    
        SUB(sub).strides.file_order = {'iCC_dual', 'iCC_only', 'trad_dual', 'trad_only'};

        % plot ERSPs -------------------------------------------------------------------------

        f = figure;
        for idx = 1:4
            subplot(2,2,idx)
            imagesc([1:100], [4:2:60], squeeze(TMP.GPM(:,18,:,idx,sub))', 'Interpolation','bilinear'); 
            colormap jet; 
            set(gca,'YDir','normal')
            title(['GMP corr for ', cond_order{idx}], 'Interpreter','none')
        end
        sgtitle(SUB(sub).ID, 'Interpreter','none')

        cd(SUBGAITPATH);
        exportgraphics(f, 'ERSPs_nosPCACAR.png', 'Resolution', 300);

    end                                                                                             % end sorting out subs  
end                                                                                                 % end loop across subjects


%% save struct!

save([MAINPATH,'SUBS'],'SUB');                                                                      % save information
save([MAINPATH,'TimeFreq'],'TMP');


%% move over to stats

%load('TimeFreq.mat');

GA_ICC_walk_dual = squeeze(mean(TMP.GPM(:,18,:,1,:), 5));
GA_trad_walk_dual = squeeze(mean(TMP.GPM(:,18,:,3,:), 5));
GA_ICC_walk_only = squeeze(mean(TMP.GPM(:,18,:,2,:), 5));
GA_trad_walk_only = squeeze(mean(TMP.GPM(:,18,:,4,:), 5));



f = [4:2:60];
t = 1:100;

figure;
subplot(221)
imagesc(t,f,GA_ICC_walk_dual', 'Interpolation','bilinear')
title('GA ICC walk dual')
ylim([4 40])
colormap jet; 
set(gca,'YDir','normal')
clim([-0.3 0.3])

subplot(222)
imagesc(t,f,GA_trad_walk_dual', 'Interpolation','bilinear')
title('GA trad walk dual')
ylim([4 40])
colormap jet; 
set(gca,'YDir','normal')
clim([-0.3 0.3])

subplot(223)
imagesc(t,f,GA_ICC_walk_only', 'Interpolation','bilinear')
title('GA ICC walk only')
ylim([4 40])
colormap jet; 
set(gca,'YDir','normal')
clim([-0.3 0.3])

subplot(224)
imagesc(t,f,GA_trad_walk_only', 'Interpolation','bilinear')
title('GA trad walk only')
ylim([4 40])
colormap jet; 
set(gca,'YDir','normal')
colorbar
clim([-0.3 0.3])













