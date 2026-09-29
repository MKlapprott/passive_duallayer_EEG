%   Project Title: Pre-Processing Pipeline for AMICA (HYPERGATOR
%   IMPLMENTATION)
%
%   Code Designer: Jacob salminen
%
%   Version History --> See details at the end of the script.
%   Current Version:  v1.0.20220316.0
%   Previous Version: n/as
%   Summary:
%   Internal Use Only:
%   'cd /blue/jsalminen/GitHub/connectivityMIM/src/1_icaProcess/HG_0_preProcessEEG/'
%## TIME

% Editted by Chang - 20220715
% Add iCC EMG + ChanRej TimeRej option - Chang  20230205

% Theresa - started modifying to test batch processing on HPG, June 20 2023
%june27 - replaced file paths to specify by condition for each subject, ASSUMING MULTIPLE SETS PER SUBJECT
% July 19 2023: updated for Z:dferris drive for storage and computation
%{
THERESA - 2024-07-22 I am considering running the timewindow and channel rejection on the baseline specifically so that only 10% of the baseline can be removed. 
%}
clearvars; close all
USER_NAME = 'theresa.hauge'; %getenv("USERNAME");
if isunix
    addpath([filesep 'blue' filesep 'dferris' filesep USER_NAME filesep 'HY' filesep ...
        'scripts' filesep 'code_Preprocess']) %add path to N/M drive
elseif ispc
    addpath(fullfile('Z:',USER_NAME,'HY','scripts','code_Preprocess'))
end
%% Initialization
P3_HY_config_params
%% --------------------------------------------------------------------- %%
%## PARAMS
% addpath(fullfile('Z:',USER_NAME,'HY','scripts','code_Preprocess','_package','iCanClean'))
% rmpath(fullfile(Z))
%## force all conditions to exist (helps temporarily avoid errors in EEGLAB STUDY we later need to fix for missing data)
fullRankAvRefBool = false;
% ----------------------------------------------------------------------- %
%## Path for the M drive (blue HPG drive) where subject data is stored
subjDataDir = [P3_config.EEG_input];
fileList = dir(fullfile(subjDataDir,'*.set')); % new ext _HP1hz_cleanline_merge_kin
len_subj = length(fileList);
% Path for the R drive (or local drive) where you are strying to transfer data from
% studyDir = [];
% studyDir = [subjDataDir 'studies' filesep];
%## define the name of the study.
% ----------------------------------------------------------------------- %

%% SUBJECT LOOP
storeEEG = cell(length(all_subjStr),1);
txt_cmd = cell(length(fileList),1);
tic
for i = 25 %17:length(all_subjStr)  %9:16 %1:length(all_subjStr)%
    subjStr= all_subjStr{i}; disp(subjStr)
    % subjStr = 'S01_0220'; %'S20_0212';
    % ==== INTERNAL PARAMS ==== % % 20231212 settings for EMG check: do_iCC=1;do_iCC_muscle = 1; do_TimeRej = 1; NO CHANREJ
    ALLEEG = [];
    EMG_highpass = 0;%use .set with highpass filter EMG
    do_iCC = 0;
    do_iCC_and_ChanRej_TimeRej = 0;%This is the pipeline we decide to use - 2022-09-02
    do_iCC_muscle = 0;
    do_iCC_and_ChanRej_TimeRej_iCCMuscle = 1;%Testing this pipeline now - 2023-02-05. recommended by JSal THERESA THIS IS WHAT YOU SHOULD USE.
    do_CCA = 0;
    do_ASR = 0;
    do_ChanRej = 0;
    do_TimeRej = 0; %TimeRej include ChanRej. Pick ChanRej or TimeRej
    do_HP = {}; %{'8std_ChanRej'};%{'8std_ChanRej_TimeRej'};
    do_ChanRej_iCC = 0;
    do_postASR_ChanRej = {};%
    do_postASR_ChanRej_TimeRej = {};
    runAMICA = 0; %default set to 1, testing have it set to 0
    PS_TS_sep = 0;

    autoChRejMethod = [num2str(P3_config.std_threshold),'std'];
    cleaningMethod = '';
    finalChToKeepForICA = {'EEG'};
    CURRENTSET = 1;
    % ==== END: INTERNAL PARAMS ==== %
    %     hgOutputPath = [PATHS.localStorage all_subjStr(subj_i).SubjectStr filesep 'tmpEEG' filesep '_hgout' filesep];
    % subjStr = all_subjStr{subj_i}; % comment out 0801,
    %     mkdir(hgOutputPath)
    %     subjectTrialFolder = [PATHS.localStorage all_subjStr(subj_i).SubjectStr filesep 'tmpEEG' filesep];
    fprintf('==== STARTING %s PROCESSING ====\n\n',subjStr)

    if ischar(finalChToKeepForICA) %e.g. just 'EEG', not {'EEG'} or {'EEG','Noise'}
        finalChToKeepForICA = {finalChToKeepForICA};%turn 'EEG' into {'EEG'} to make code below more robust
    end

    if fullRankAvRefBool
        avgRefPCAReduction = 0;
    else
        avgRefPCAReduction = length(finalChToKeepForICA); %1 for just {'EEG'} and 3 for {'EEG','Noise','EMG'}
    end
    %%
    %     subjectsFolder = fullfile(P3_config.CleanEEG_output,'BATCH-1-Filter-Merge_cleanline_kin');
    %     fileList_MERGE = dir( fullfile(subjectsFolder,[subjStr,'_merged*.set']) );
    fileList_BL_PS = dir(fullfile(subjDataDir,[subjStr, '_BL_PS_HP1hz_cleanline_merge_kin.set']) );
    fileList_PS = dir(fullfile(subjDataDir,[subjStr, '_PS_HP1hz_cleanline_merge_kin.set']) );
    fileList_COND = [fileList_BL_PS;fileList_PS];
    nTrials = 1:size(fileList_COND,1);
    for trial_i = nTrials
        fileName = fileList_COND(trial_i).name; disp(fileName)
        EEG = pop_loadset('filepath',P3_config.EEG_input,'filename',fileName);
        [ALLEEG,EEG,CURRENTSET] = eeg_store(ALLEEG,EEG,0);
    end
    EEG = pop_mergeset( ALLEEG, 1:2, 0); 
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','HP1hz_cleanline_merge_kin',...
        'comments',char('All EEG, IMU, and Pong data in same structure, baseline and trials re-merged',...
        ' ','HPF1Hz and cleanline processed'),'gui','off');

        %% Load subject filtered merged file -- THERESA change this june 21 2023
        %     if EMG_highpass
        %         fileName = [subjStr,'_EEG','_HP1hz_cleanline_merge_EMG.set']; % edit here for file name
        %         cleaningMethod = horzcat(cleaningMethod,'EMG_HP');
        %     else
        %         fileName = [subjStr,'_EEG','_HP1hz_cleanline_merge.set']; % edit here for file name
        %         % 	    fileName = [subjStr,'_HP1hz_cleanline_merge.set'];
        %         fileList= dir( '*.set' );
        %     end
        % initiate processing by conditions for each subject, eg more than one dataset per person; 36 people = 72 sets for D and S sets.
        % processing condition by condition
        % for i = 1:length(fileList)
        fileName = fileList_COND(2).name; disp(fileName)
        EEG.filename = fileName;
%         EEG = pop_loadset('filepath',P3_config.EEG_input,'filename',fileName); oEEG = EEG;
        EEG.urchanlocs = EEG.chanlocs; % keep one copy of old channel info; needed for chan_rej
        % fileNameNoExt = EEG.filename(1:11); % for _PS _PD _TS _TD processing
        fileNameNoExt = EEG.filename(1:end-30);% of -26 for S/D merged datasets, change to EEG.filename(1:10)
        subjStr = EEG.filename(1:8);
        % used to be set to this, changed it up a little.
        %% Session Level Processing
        %         EEG.subject = subjStr;
        %         EEG.setname = [subjStr,' Merged EEG'];

        % eeglab redraw;
        EEG.subject = subjStr;

        %Re-ref EEG, EMG, and Noise to themselves
        fprintf('==== %s 1.) REREFERENCING ====\n',fileNameNoExt)
        EEG = rerefC2CN2NExt2Ext_func(EEG,fullRankAvRefBool);
% % merge here??

        %Reject bad channels, 1st iteration
        fprintf('==== %s 2.) AUTOREJECTION OF BAD CHANS ====\n',fileNameNoExt)
        EEG = autoRejCh_func_CL(EEG,P3_config.std_threshold);

        %Re-ref again (since remnants of rejected channels still exist from
        %last average referencing
        fprintf('==== %s 3.) REREFERENCING pt.2 ====\n',fileNameNoExt)
        EEG = rerefC2CN2NExt2Ext_func(EEG,fullRankAvRefBool);

        % reject bad channels again and re-ref again
        fprintf('==== %s 4.) AUTOREJECTION OF BAD CHANS pt.2 ====\n',fileNameNoExt)
        EEG = autoRejCh_func_CL(EEG,P3_config.std_threshold);
        % re-ref
        fprintf('==== %s 5.) REREFERENCING pt.3 ====\n',fileNameNoExt)
        EEG = rerefC2CN2NExt2Ext_func(EEG,fullRankAvRefBool);
        cleaningMethod = horzcat(cleaningMethod,autoChRejMethod);

        %update channel types b/c that is always a good idea
        EEG_chans = find(strcmpi('EEG',{EEG.chanlocs.type})); %redefine channels (numbering changed since we took subset of channels)
        EMG_chans = find(strcmpi('EMG',{EEG.chanlocs.type}));
        Noise_chans = find(strcmpi('Noise',{EEG.chanlocs.type}));
        Pong_chans = find(strcmpi('pong',{EEG.chanlocs.type}));
        %% find baseline start and stop, make sure you preserve both Baseline time ranges / run time rejection separately
        %{
IMUst = find(strcmp({EEG.event.type}, {'TrialStart'})); % IMUstLat = EEG.event(IMUst).latency; IMUst([2 3 5 7 9 11 14 15 17 19 21 24 25])=[];
    IMUend = find(strcmp({EEG.event.type}, {'TrialEnd'})); % IMUendLat T= EEG.event(IMUend).latency ;
%     BaselineSt = find(contains({EEG.event(IMUst).trialName},{'BL','S'}));
%     BaselineEnd = find(contains({EEG.event(IMUend).trialName},{'BL'}));
%     BLSst = find(contains({EEG.event(BaselineSt).trialName},{'S'}));
%     BSLend = find(contains({EEG.event(BaselineEnd).trialName},{'S_'}));
    % IMUtimes = [IMUst;IMUend]';
%     % remove any dual tasking events
    for i = 1:length(IMUst)
%         BaselineSt(i) = find(contains({EEG.event(IMUst(i)).trialName(9:end)},{'BL_PS'})) || find(contains({EEG.event(IMUst(i)).trialName(9:end)},{'BL_TS'})) ;
%         BaselineEnd(i) = find(contains({EEG.event(IMUend(i)).trialName(9:end)},{'BL_PS'})) || find(contains({EEG.event(IMUend(i)).trialName(9:end)},{'BL_TS'}));
        if any(find(contains({EEG.event(IMUst(i)).trialName(9:end)},{'BL_PD'}))) || any(find(contains({EEG.event(IMUst(i)).trialName(9:end)},{'BL_TD'})))
            rm_eventSt(i) = i;
        else
            rm_eventSt(i) = 0;
        end
    end
    IMUst(rm_eventSt>0) = [];
    for i1 = 1:length(IMUend)
        if any((contains({EEG.event(IMUend(i1)).trialName(9:end)},{'BL_PD'}))) || any((contains({EEG.event(IMUend(i1)).trialName(9:end)},{'BL_TD'})))
            rm_eventEnd(i1) = i1;
        else 
            rm_eventEnd(i1)=0;
        end
    end
    IMUend(rm_eventEnd>0)=[];


    clear IMUstartLatencies IMUendLatencies TrialSeg BaselineSt BaselineEnd
    for i2 = 1:length(IMUst) % make a loop with the TrialStart and TrialEnd bits from the IMUs for these trials...
        BaselineSt(i2) = find(contains({EEG.event(IMUst(i2)).trialName(9:end)},{'BL_PS'})) || find(contains({EEG.event(IMUst(i2)).trialName(9:end)},{'BL_TS'})) ;
        BaselineEnd(i2) = find(contains({EEG.event(IMUend(i2)).trialName(9:end)},{'BL_PS'})) || find(contains({EEG.event(IMUend(i2)).trialName(9:end)},{'BL_TS'}));
        IMUstartLatencies(i2) =  EEG.event(IMUst(i2)).latency;
        IMUendLatencies(i2) = EEG.event(IMUend(i2)).latency;
        TrialSeg(i2,:) = [IMUstartLatencies(i2); IMUendLatencies(i2)]; % ideally in the future this will replace the monstrosity above
    end

    all_trMarkers = EEG.event(contains({EEG.event.trialName},{subjStr}));
    all_Starts = all_trMarkers(contains({all_trMarkers.type},'TrialStart')); % isolate all starts
    all_Stops = all_trMarkers(contains({all_trMarkers.type},'TrialEnd')); %variable for ends

    all_labs = {all_Starts.trialName}';
    all_datetimes = [all_Starts.datetime; all_Stops.datetime]'; %make two column matrix of datetimes
    all_difftimes = diff(all_datetimes,1,2); % also print the trial duration

    if any(all_difftimes < minutes(1)) == true
        a = find(all_difftimes < minutes(1));
        disp(strcat('APDMs did not record entire trial at ', all_labs(a) ))
    end
        %}

        %% CLEANING
        %iCC
        %         %{
        if do_iCC
            rho = num2str(P3_config.ICC.params.rhoSqThres_source);idx_rho = strfind(rho,'.');
            cleaningMethod = horzcat(cleaningMethod,'_iCC','0p',rho(idx_rho+1:end));
            fprintf('==== %s STARTING: ICANCLEAN ====\n',fileNameNoExt);
            [EEG_chans, EMG_chans, Noise_chans] = getChannelTypes_func(EEG) ;
            [EEG] = iCanClean(EEG,[EEG_chans], [Noise_chans], 0, P3_config.ICC.params);
            EEG = rerefC2CN2NExt2Ext_func(EEG,fullRankAvRefBool);
        end
        % iCC and Chan Rej and Time Rej
        if do_iCC_and_ChanRej_TimeRej % Roehl look here
            rho = num2str(P3_config.ICC.params.rhoSqThres_source);idx_rho = strfind(rho,'.');
            cleaningMethod = horzcat(cleaningMethod,'_iCC','0p',rho(idx_rho+1:end));
            fprintf('==== %s STARTING: ICANCLEAN ====\n',fileNameNoExt);
            [EEG_chans, EMG_chans, Noise_chans] = getChannelTypes_func(EEG) ;
            [EEG] = iCanClean(EEG,[EEG_chans], [Noise_chans], 0, P3_config.ICC.params); % iCC using noise channels
            EEG = rerefC2CN2NExt2Ext_func(EEG,fullRankAvRefBool);
            if P3_config.kurt_prob_std_rm == 0 ; kurt_prob_std_rm = '';else;kurt_prob_std_rm = '_MoreChanRej';end;
            winParam = num2str(P3_config.wind_crit);chanParam = num2str(P3_config.chan_crit1);winTol = num2str(P3_config.window_crit_tolerances(2));
            fprintf('==== %s STARTING: CHAN TIME REJ ====\n',fileNameNoExt);
            [EEG_temp_clean,EEG_temp_clean_timerej,p_frames_rej,p_chan_rej] = channelrejection_wrap(EEG,P3_config);
            %Time Rej
            EEG = EEG_temp_clean_timerej;zthreshold = EEG.etc.clean_artifacts.window_zthreshold;
            cleaningMethod = horzcat(cleaningMethod,'_ChanRej','0p',chanParam(strfind(chanParam,'.')+1:end),'_TimeRej','0p',winParam(strfind(winParam,'.')+1:end),'_winTol',winTol,kurt_prob_std_rm);
            EEG = rerefC2CN2NExt2Ext_func(EEG,fullRankAvRefBool);
            preprocess_pipeline = [cleaningMethod];
            mkdir(fullfile(P3_config.CleanEEG_output,fileNameNoExt))
            %             mkdir(fullfile(P3_config.CleanEEG_output,preprocess_pipeline,fileNameNoExt))
            fid = fopen(fullfile(P3_config.CleanEEG_output,fileNameNoExt,'info.txt'),'w') ;
            %             fid = fopen(fullfile(P3_config.CleanEEG_output,preprocess_pipeline,fileNameNoExt,'info.txt'),'w');
            fprintf(fid,['\n %.2f percent of frames were rejected\n'], p_frames_rej);
            fprintf(fid,['\n %.2f channels were rejected\n'], p_chan_rej);
            fclose(fid);
            save(fullfile(P3_config.CleanEEG_output,fileNameNoExt,'rejection_info.mat'),'p_frames_rej','p_chan_rej','zthreshold');
            %             save(fullfile(P3_config.CleanEEG_output,preprocess_pipeline,fileNameNoExt,'rejection_info.mat'),'p_frames_rej','p_chan_rej','zthreshold');
        end
        if do_iCC_muscle
            rho_iCC_muscle = num2str(P3_config.ICC_muscle.params.rhoSqThres_source);
            cleaningMethod = horzcat(cleaningMethod,'_iCCEMG','0p',rho_iCC_muscle(strfind(rho_iCC_muscle,'.')+1:end));
            fprintf('==== %s STARTING: ICANCLEAN MUSCLE ====\n',fileNameNoExt);
            [EEG_chans, EMG_chans, Noise_chans] = getChannelTypes_func(EEG) ;
            [EEG] = iCanClean(EEG,[EEG_chans], [EMG_chans], 0, P3_config.ICC_muscle.params);
            EEG = rerefC2CN2NExt2Ext_func(EEG,fullRankAvRefBool);
        end
        %         %}
        if do_iCC_and_ChanRej_TimeRej_iCCMuscle
            rmpath('Z:\theresa.hauge\eeglab2021.0\plugins\iCanClean')
            addpath('Z:\theresa.hauge\HY\scripts\code_Preprocess\_package\iCanClean')
            rho = num2str(P3_config.ICC.params.rhoSqThres_source);idx_rho = strfind(rho,'.');
            cleaningMethod = horzcat(cleaningMethod,'_iCC','0p',rho(idx_rho+1:end));
            fprintf('==== %s STARTING: ICANCLEAN EEG with Noise ====\n',fileNameNoExt);
            [EEG_chans, EMG_chans, Noise_chans] = getChannelTypes_func(EEG) ;
            [EEG] = iCanClean(EEG,[EEG_chans], [Noise_chans], 0, P3_config.ICC.params); % first iCC, noise channels
            EEG = rerefC2CN2NExt2Ext_func(EEG,fullRankAvRefBool);

            rho_iCC_muscle = num2str(P3_config.ICC_muscle.params.rhoSqThres_source);
            cleaningMethod = horzcat(cleaningMethod,'_iCCEMG','0p',rho_iCC_muscle(strfind(rho_iCC_muscle,'.')+1:end));
            fprintf('==== %s STARTING: ICANCLEAN EEG with EMG ====\n',fileNameNoExt);
            [EEG_chans, EMG_chans, Noise_chans] = getChannelTypes_func(EEG) ;
            [EEG] = iCanClean(EEG,[EEG_chans], [EMG_chans], 0, P3_config.ICC_muscle.params); % second iCC, EMG
            EEG = rerefC2CN2NExt2Ext_func(EEG,fullRankAvRefBool);

            if P3_config.kurt_prob_std_rm == 0 ; kurt_prob_std_rm = '';else;kurt_prob_std_rm = '_MoreChanRej';end;
            winParam = num2str(P3_config.wind_crit);
            chanParam = num2str(P3_config.chan_crit1);
            winTol = num2str(P3_config.window_crit_tolerances(2));

            fprintf('==== %s STARTING: CHAN TIME REJ ====\n',fileNameNoExt);
            EEG_pretimerej = EEG; % added to pull behavioral channels and remove time windows taken out based on the EEG data, also debugging
            [EEG_temp_clean,EEG_temp_clean_timerej,p_frames_rej,p_chan_rej] = channelrejection_wrap(EEG,P3_config); % channel and time window rejection step
            %Time Rej
            EEG = EEG_temp_clean_timerej;
            zthreshold = EEG.etc.clean_artifacts.window_zthreshold;
            cleaningMethod = horzcat(cleaningMethod,'_ChanRej','0p',chanParam(strfind(chanParam,'.')+1:end),'_TimeRej','0p',winParam(strfind(winParam,'.')+1:end),'_winTol',winTol,kurt_prob_std_rm);
            EEG = rerefC2CN2NExt2Ext_func(EEG,fullRankAvRefBool);
            preprocess_pipeline = [cleaningMethod];
            mkdir(fullfile(P3_config.CleanEEG_output,fileNameNoExt))
            %             mkdir(fullfile(P3_config.CleanEEG_output,preprocess_pipeline,fileNameNoExt))
            fid = fopen(fullfile(P3_config.CleanEEG_output,fileNameNoExt,'info.txt'),'w') ;
            %             fid = fopen(fullfile(P3_config.CleanEEG_output,preprocess_pipeline,fileNameNoExt,'info.txt'),'w');
            fprintf(fid,['\n %.2f percent of frames were rejected\n'], p_frames_rej);
            fprintf(fid,['\n %.2f channels were rejected\n'], p_chan_rej);
            fclose(fid);
            save(fullfile(P3_config.CleanEEG_output,fileNameNoExt,'rejection_info.mat'),'p_frames_rej','p_chan_rej','zthreshold');
            %             save(fullfile(P3_config.CleanEEG_output,preprocess_pipeline,fileNameNoExt,'rejection_info.mat'),'p_frames_rej','p_chan_rej','zthreshold');
        end

        % CCA
        %         %{
        if do_CCA
            rho_CCA = num2str(P3_config.CCA.CCA_Rsq_thres);idx_rho_CCA = strfind(rho_CCA,'.');
            cleaningMethod = horzcat(cleaningMethod,'_CCA','0p',rho_CCA(idx_rho_CCA+1:end));
            fprintf('==== %s STARTING: CCA ====\n',fileName);
            [EEG_chans, EMG_chans, Noise_chans] = getChannelTypes_func(EEG)
            EEG = autoLagCCA_wrap(EEG,P3_config.CCA);
            EEG = rerefC2CN2NExt2Ext_func(EEG,fullRankAvRefBool);
        end
        %ASR
        if do_ASR
            BurstCriteria = num2str(P3_config.ASR_correct.burstCritASR);
            cleaningMethod = horzcat(cleaningMethod,'_ASRcorr',BurstCriteria);
            fprintf('==== %s STARTING: AUTOMATIC SUBSPACE RECONSTRUCTION ====\n',fileNameNoExt); %#ok<UNRCH>
            [EEG] = ASR_correction(EEG,P3_config.ASR_correct);
            EEG = rerefC2CN2NExt2Ext_func(EEG,fullRankAvRefBool);
        end

        %ChanRej
        if do_ChanRej | do_TimeRej
            if P3_config.kurt_prob_std_rm == 0 ; kurt_prob_std_rm = '';else;kurt_prob_std_rm = '_MoreChanRej';end;
            winParam = num2str(P3_config.wind_crit);chanParam = num2str(P3_config.chan_crit1);winTol = num2str(P3_config.window_crit_tolerances(2));
            fprintf('==== %s STARTING: CHAN TIME REJ ====\n',fileNameNoExt);
            [EEG_temp_clean,EEG_temp_clean_timerej,p_frames_rej,p_chan_rej] = channelrejection_wrap(EEG,P3_config);
            %Time Rej
            if do_ChanRej
                cleaningMethod = horzcat(cleaningMethod,'_ChanRej','0p',chanParam(strfind(chanParam,'.')+1:end),'_','0p',winParam(strfind(winParam,'.')+1:end),'_winTol',winTol,kurt_prob_std_rm);
                EEG = EEG_temp_clean;
                EEG = rerefC2CN2NExt2Ext_func(EEG,fullRankAvRefBool);
            end
            if do_TimeRej
                if p_frames_rej < 10 % if time window rejected under 10%, rejection
                    Rej_time_window = 1;
                else
                    Rej_time_window = 0;
                end

                if Rej_time_window
                    EEG = EEG_temp_clean_timerej;zthreshold = EEG.etc.clean_artifacts.window_zthreshold;
                    cleaningMethod = horzcat(cleaningMethod,'_ChanRej','0p',chanParam(strfind(chanParam,'.')+1:end),'_TimeRej','0p',winParam(strfind(winParam,'.')+1:end),'_winTol',winTol,kurt_prob_std_rm);
                    EEG = rerefC2CN2NExt2Ext_func(EEG,fullRankAvRefBool);
                else
                    EEG = EEG_temp_clean;
                    cleaningMethod = horzcat(cleaningMethod,'_ChanRej','0p',chanParam(strfind(chanParam,'.')+1:end),'_TimeRej','0p',winParam(strfind(winParam,'.')+1:end),'_winTol',winTol,kurt_prob_std_rm);
                    subjStr = horzcat(subjStr,'_noTimeRej');
                    EEG = rerefC2CN2NExt2Ext_func(EEG,fullRankAvRefBool);
                end
            end
            preprocess_pipeline = [cleaningMethod];
            mkdir(fullfile(P3_config.CleanEEG_output,fileNameNoExt))
            %             mkdir(fullfile(P3_config.CleanEEG_output,preprocess_pipeline,fileNameNoExt))
            fid = fopen(fullfile(P3_config.CleanEEG_output,fileNameNoExt,'info.txt'),'w') ;
            %             fid = fopen(fullfile(P3_config.CleanEEG_output,preprocess_pipeline,fileNameNoExt,'info.txt'),'w');
            fprintf(fid,['\n %.2f percent of frames were rejected\n'], p_frames_rej);
            fprintf(fid,['\n %.2f channels were rejected\n'], p_chan_rej);
            fclose(fid);
            save(fullfile(P3_config.CleanEEG_output,fileNameNoExt,'rejection_info.mat'),'p_frames_rej','p_chan_rej','zthreshold');
            %             save(fullfile(P3_config.CleanEEG_output,preprocess_pipeline,fileNameNoExt,'rejection_info.mat'),'p_frames_rej','p_chan_rej','zthreshold');
        end

        if ~isempty(do_HP)
            fprintf('==== %s STARTING: HIGH PASS FILTERING ====\n',fileNameNoExt);
            cleaningMethod = horzcat(do_HP{1},'_HP');
            EEGpreprocess_fileName = [subjStr,'_cleanEEG_',do_HP{1},'.set'];
            EEGpreprocess_filePath = fullfile(P3_config.CleanEEG_output,do_HP{1},subjStr);
            EEG_preprocessed = pop_loadset('filepath',EEGpreprocess_filePath,'filename',EEGpreprocess_fileName);
            [EEG] = bemobil_filter_CL(EEG_preprocessed,...
                P3_config.filter_lowCutoffFreqAMICA, P3_config.filter_highCutoffFreqAMICA,...
                P3_config.filter_AMICA_highPassOrder, P3_config.filter_AMICA_lowPassOrder);
            EEG = rerefC2CN2NExt2Ext_func(EEG,fullRankAvRefBool);
        end

        if do_ChanRej_iCC
            cleaningMethod = horzcat(cleaningMethod,'_ChanRej_iCC');
            [EEG_temp_clean,EEG_temp_clean_timerej,p_frames_rej,p_chan_rej] = channelrejection_wrap(EEG,P3_config);
            [EEG_chans, EMG_chans, Noise_chans] = getChannelTypes_func(EEG) ;
            [EEG] = iCanClean(EEG_temp_clean,[EEG_chans], [Noise_chans], 0, P3_config.ICC.params);
            EEG = rerefC2CN2NExt2Ext_func(EEG,fullRankAvRefBool);
        end

        if ~isempty(do_postASR_ChanRej)
            winParam = num2str(P3_config.wind_crit);chanParam = num2str(P3_config.chan_crit1);winTol = num2str(P3_config.window_crit_tolerances(2));
            cleaningMethod = horzcat(do_postASR_ChanRej{1},'_ChanRej','0p',chanParam(strfind(chanParam,'.')+1:end),'_','0p',winParam(strfind(winParam,'.')+1:end),'_winTol',winTol);
            [EEG] = do_postASR_ChanRej_wrap(EEG,subjStr,cleaningMethod, do_postASR_ChanRej,P3_config,fullRankAvRefBool);
        end

        if ~isempty(do_postASR_ChanRej_TimeRej)
            winParam = num2str(P3_config.wind_crit);chanParam = num2str(P3_config.chan_crit1);winTol = num2str(P3_config.window_crit_tolerances(2));
            cleaningMethod = horzcat(do_postASR_ChanRej_TimeRej{1},'_ChanRej','0p',chanParam(strfind(chanParam,'.')+1:end),'_','TimeRej','0p',winParam(strfind(winParam,'.')+1:end),'_winTol',winTol);
            [~,EEG] = do_postASR_ChanRej_wrap(EEG,subjStr,cleaningMethod,do_postASR_ChanRej_TimeRej,P3_config,fullRankAvRefBool);
        end
        %         %}

        %%

        %% Save EEG and log
        preprocess_pipeline = [cleaningMethod];
        fprintf('Saving %s EEG to %s\n',fileNameNoExt,fullfile(P3_config.CleanEEG_output));
        EEG.etc.CleanType  = preprocess_pipeline;
        EEG.etc.Params     = P3_config;
        mkdir(fullfile(P3_config.CleanEEG_output,fileNameNoExt))
        %         mkdir(fullfile(P3_config.CleanEEG_output,preprocess_pipeline,fileNameNoExt))

        [EEG_chans, EMG_chans, Noise_chans] = getChannelTypes_func(EEG); % modified to include pong and other channels
        % re-ref
        fprintf('==== %s FINAL REREFERENCING ====\n',fileNameNoExt)
        EEG = rerefC2CN2NExt2Ext_func(EEG,fullRankAvRefBool);
        %         subjStr = fileNameNoExt;
        origEEG = EEG;


        EEG = pop_select(origEEG,'channel',sort([EEG_chans]));%2022-5-13 not use EMG
        [ALLEEG,EEG ] = eeg_store(ALLEEG,EEG,0);
        % EEG = pop_select(EEG,'channel',sort([EMG_chans]));%2023-12-11 TH looking at ERSP of muscle channels between conditions to see what we are getting
        EEGclean = pop_saveset(EEG,'filepath',fullfile(P3_config.CleanEEG_output,fileNameNoExt),...
            'filename',sprintf('%s_cleanEEG',fileNameNoExt)); %change to remove pipeline, this should be the STUDY-preprocess... folder.
        %         [ALLEEG,EEG ] = eeg_store(ALLEEG,EEG1,0);

        % Theresa 2024-08-22 saving Pong and IMU channels as separate dataset?
        %% THERESA USE THE CLEAN_ARTIFACTS.SAMPLE_CLEAN_MASK TO USE ONLY SPECIFIC
        % TIME POINTS FOR BEHAVIORAL DATA.
        % % first, make sure you are only keeping the EEG channels that were kept after
        % the channel rejection step
        cropEEG = EEG_temp_clean_timerej; [cropEEG_chans, cropEMG_chans, cropNoise_chans] = getChannelTypes_func(cropEEG);
        origEEG = EEG_pretimerej; % contains all channels with kinematic data
        EEG_chans = find(strcmpi('EEG',{origEEG.chanlocs.type})); %define channels
        EMG_chans = find(strcmpi('EMG',{origEEG.chanlocs.type}));
        Noise_chans = find(strcmpi('Noise',{origEEG.chanlocs.type}));
        Pong_chans = find(strcmpi('pong',{origEEG.chanlocs.type}));
        CIMU_chans = find(strcmpi('BioM',{origEEG.chanlocs.type}));
        EEG2 = pop_select( origEEG, 'channel', sort([EEG_chans, EMG_chans, Noise_chans,Pong_chans,CIMU_chans]));

        % check at indices for matching labels
        origChans_eeg = string({EEG2.chanlocs(EEG_chans).labels})';
        cropChans_eeg =  string({cropEEG.chanlocs(cropEEG_chans).labels})';
        g = setdiff(origChans_eeg,cropChans_eeg); %find channels that are missing from the clean_timerej dataset
        loc_idx = find(matches(origChans_eeg,g)); % this is the only type additionally rejecting channels
        % use loc_idx to remove the channels and then find new index numbers
        EEG3 = pop_select(EEG2, 'nochannel',loc_idx);
        EEG_chans = find(strcmpi('EEG',{EEG3.chanlocs.type})); %define channels
        EMG_chans = find(strcmpi('EMG',{EEG3.chanlocs.type}));
        Noise_chans = find(strcmpi('Noise',{EEG3.chanlocs.type}));
        Pong_chans = find(strcmpi('pong',{EEG3.chanlocs.type}));
        CIMU_chans = find(strcmpi('BioM',{EEG3.chanlocs.type}));


        % crop_index = EEG_temp_clean_timerej.etc.clean_sample_mask;
        % cropout_index = find(~crop_index); % find the time windows that get pulled
        % % make sure the data is removed from same locations across all channels
        EEG = pop_select(EEG3, 'point', EEG_temp_clean_timerej.etc.clean_artifacts.retain_data_intervals);

        [ALLEEG,EEG] = eeg_store(ALLEEG,EEG,0); eeglab redraw
        mkdir(fullfile(P3_config.CleanEEG_output,'kin',fileNameNoExt))
        EEG3 = pop_saveset(EEG3,'filepath',fullfile(P3_config.CleanEEG_output,'kin',fileNameNoExt),...
            'filename',sprintf('%s_cleanEEG_kin',fileNameNoExt),'version','7.3','savemode','twofiles'); %change to remove pipeline, this should be the STUDY-preprocess... folder. put into main folder or another folder set before AMICA
        %         [ALLEEG,EEG ] = eeg_store(ALLEEG,EEG2,0);

%     end

    % % merge the cleaned baseline trial and trials together for AMICA


    %% HPG IMPLEMENTATION ONLY
    % SEND to HPG
    % define output paths
    %     amicaOutputFolder_local = [MiM_config.amicaOutputFolder_Mdrive,'\',preprocess_pipeline,'\AMICA\',subjStr] %main amica directory on M drive you want to save to
    %     amicaOutputFolder_unix = [MiM_config.amicaOutputFolder_unix,'/preprocess_pipeline/','AMICA/',[subjStr,'/']]
    amicaOutputFolder_local = fullfile(P3_config.CleanEEG_output,fileNameNoExt); %TH changed to match dir in line 326
    amicaOutputFolder_unix = fullfile(P3_config.amicaOutputFolder_unix,fileNameNoExt);
    %         amicaOutputFolder_local = fullfile(P3_config.CleanEEG_output,preprocess_pipeline,fileNameNoExt);
    %         amicaOutputFolder_unix = fullfile(P3_config.CleanEEG_output,preprocess_pipeline,fileNameNoExt);
    % write .sh script to subject folders
    disp([num2str(length(EEG_chans)),' remained']);
    txt_cmd{i} = prepare_HPG_AMICA_func_batch(EEG,sprintf('%s_cleanEEG',fileNameNoExt),...
        amicaOutputFolder_local,amicaOutputFolder_unix,...
        avgRefPCAReduction,P3_config.emailStr) %prepare AMICA files then follow instructions to manually run amica on hipergator
    % need to run script on HPG?
    if runAMICA
        system([txt_cmd{i},''])
    end

    fprintf('==== FINISHING %s PROCESSING ====\n\n',fileNameNoExt)
    %% split EEG-only data into PS and TS files after preprocessing to submit to AMICA separately and compare muscle activity
    % EEG = pop_loadset('filepath',fullfile(P3_config.CleanEEG_output,fileNameNoExt),'filename',strcat(fileNameNoExt,'_cleanEEG.set'));
    origEEG = EEG;
    PS_TS_sep = 0;
    if PS_TS_sep
        EEG = addConditiontoEEG2(EEG,subjStr,2);

        Condst = find(strcmp({EEG.event.code}, {'ConditionStart'})); % IMUstLat = EEG.event(IMUst).latency; IMUst([2 3 5 7 9 11 14 15 17 19 21 24 25])=[];
        Condend = find(strcmp({EEG.event.code}, {'ConditionEnd'})); % IMUendLat T= EEG.event(IMUend).latency ;
        clear CondstartLatencies; clear CondendLatencies; clear TrialSeg
        for k = 1:length(Condst) %
            CondstartLatencies(k) =  EEG.event(Condst(k)).latency;
            CondendLatencies(k) = EEG.event(Condend(k)).latency;
            TrialSeg(k,:) = [CondstartLatencies(k); CondendLatencies(k)]; % ideally in the future this will replace the monstrosity above
            allIMUorder{k} = EEG.event(Condst(k)).type(1:2);
        end

        EEG_keep = CURRENTSET; % CHECK THIS BEFORE RUNNING
        for ii = 1:length(TrialSeg)
            EEG = origEEG;
            EEG = eeg_checkset(EEG);
            EEG = pop_select(EEG, 'point', TrialSeg(ii,:));  % ;trialTimes(i,:)
            [ALLEEG,EEG,~] = pop_newset(ALLEEG,EEG,0,'setname',char(strcat(subjStr,'_',allIMUorder(ii))),... % or IMUorderIMUorder
                'comments', strvcat('All EEG, IMU, Pong, GoPro data preprocessed and separated into conditions.',...
                ' ',char(allIMUorder(ii)), 'all channels.')); % or IMUorder
            disp(strcat({'Trial cropping for '},{char(allIMUorder(ii))} , {' complete'}))

            %             save(fullfile(P3_config.CleanEEG_output,fileNameNoExt,'rejection_info.mat'),'p_frames_rej','p_chan_rej','zthreshold');
            % currently saving the same rejection info.mat file and variables
            % as the combined dataset. if there are errors, change it
            fileNameNoExt = EEG.setname; disp(fileNameNoExt)

            preprocess_pipeline = [cleaningMethod];
            fprintf('Saving %s EEG to %s\n',fileNameNoExt,fullfile(P3_config.CleanEEG_output,fileNameNoExt));
            EEG.etc.CleanType  = preprocess_pipeline;
            EEG.etc.Params     = P3_config;
            mkdir(fullfile(P3_config.CleanEEG_output,fileNameNoExt))

            [EEG_chans, EMG_chans, Noise_chans] = getChannelTypes_func(EEG) ;
            % re-ref
            fprintf('==== %s FINAL REREFERENCING ====\n',fileNameNoExt)
            EEG = rerefC2CN2NExt2Ext_func(EEG,fullRankAvRefBool);

            EEG1 = pop_select(EEG,'channel',sort([EEG_chans]));%2022-5-13 not use EMG
            %                     [ALLEEG,EEG ] = eeg_store(ALLEEG,EEG2,0);
            EEG1 = pop_saveset(EEG1,'filepath',fullfile(P3_config.CleanEEG_output,fileNameNoExt),...
                'filename',sprintf('%s_cleanEEG',fileNameNoExt),'savemode','twofiles'); %change to remove pipeline, this should be the STUDY-preprocess... folder.

            % HPG IMPLEMENTATION ONLY
            % SEND to HPG
            % define output paths
            amicaOutputFolder_local = fullfile(P3_config.CleanEEG_output,fileNameNoExt); %TH changed to match dir in line 326
            amicaOutputFolder_unix = fullfile(P3_config.amicaOutputFolder_unix,fileNameNoExt);

            % write .sh script to subject folders
            disp([num2str(length(EEG_chans)),' remained']);
            txt_cmd{i} = prepare_HPG_AMICA_func_batch(EEG,sprintf('%s_cleanEEG',fileNameNoExt),...
                amicaOutputFolder_local,amicaOutputFolder_unix,...
                avgRefPCAReduction,P3_config.emailStr) %prepare AMICA files then follow instructions to manually run amica on hipergator
            % need to run script on HPG?
            if runAMICA
                system([txt_cmd{i},''])
            end
            %              [ALLEEG, EEG, ~] = pop_newset(ALLEEG, EEG, 0,'retrieve',EEG_keep,'study',0);
            %              clear EEG
        end
        %         eeglab redraw

    end
    %     clear ALLEEG
    %     fprintf('==== FINISHING %s PROCESSING ====\n\n',fileNameNoExt)

    %% SECOND TIME: split behavioral channels into PS and TS files after preprocessing to submit to AMICA separately and compare muscle activity
    % EEG = pop_loadset('filepath',fullfile(P3_config.CleanEEG_output,fileNameNoExt),'filename',strcat(fileNameNoExt,'_cleanEEG_kin.set'));
    origEEG = EEG3;
    PS_TS_sep = 0;
    if PS_TS_sep
        nEEG = addConditiontoEEG2(origEEG,subjStr,2);

        Condst = find(strcmp({nEEG.event.code}, {'ConditionStart'})); % IMUstLat = EEG.event(IMUst).latency; IMUst([2 3 5 7 9 11 14 15 17 19 21 24 25])=[];
        Condend = find(strcmp({nEEG.event.code}, {'ConditionEnd'})); % IMUendLat T= EEG.event(IMUend).latency ;
        clear CondstartLatencies; clear CondendLatencies; clear TrialSeg
        for k = 1:length(Condst) %
            CondstartLatencies(k) =  nEEG.event(Condst(k)).latency;
            CondendLatencies(k) = nEEG.event(Condend(k)).latency;
            TrialSeg(k,:) = [CondstartLatencies(k); CondendLatencies(k)]; % ideally in the future this will replace the monstrosity above
            allIMUorder{k} = nEEG.event(Condst(k)).type(1:2);
        end

        EEG_keep = CURRENTSET; % CHECK THIS BEFORE RUNNING
        for ii = 1:length(TrialSeg)
            EEG = nEEG;
            EEG = eeg_checkset(EEG);
            EEG = pop_select(EEG, 'point', TrialSeg(ii,:));  % ;trialTimes(i,:)
            [ALLEEG,EEG,~] = pop_newset(ALLEEG,EEG,0,'setname',char(strcat(subjStr,'_',allIMUorder(ii))),... % or IMUorderIMUorder
                'comments', strvcat('All EEG, IMU, Pong, GoPro data preprocessed and separated into conditions.',...
                ' ',char(allIMUorder(ii)), 'all channels.')); % or IMUorder
            disp(strcat({'Trial cropping for '},{char(allIMUorder(ii))} , {' complete'}))

            %             save(fullfile(P3_config.CleanEEG_output,fileNameNoExt,'rejection_info.mat'),'p_frames_rej','p_chan_rej','zthreshold');
            % currently saving the same rejection info.mat file and variables
            % as the combined dataset. if there are errors, change it
            fileNameNoExt = EEG.setname; disp(fileNameNoExt)

            preprocess_pipeline = [cleaningMethod];
            fprintf('Saving %s EEG to %s\n',fileNameNoExt,fullfile(P3_config.CleanEEG_output,'kin',fileNameNoExt));
            EEG.etc.CleanType  = preprocess_pipeline;
            EEG.etc.Params     = P3_config;
            mkdir(fullfile(P3_config.CleanEEG_output,'kin',fileNameNoExt))

            %             [EEG_chans, EMG_chans, Noise_chans] = getChannelTypes_func(EEG) ;
            EEG_chans = find(strcmpi('EEG',{EEG.chanlocs.type})); %define channels
            EMG_chans = find(strcmpi('EMG',{EEG.chanlocs.type}));
            Noise_chans = find(strcmpi('Noise',{EEG.chanlocs.type}));
            Pong_chans = find(strcmpi('pong',{EEG.chanlocs.type}));
            CIMU_chans = find(strcmpi('BioM',{EEG.chanlocs.type}));
            % re-ref
            fprintf('==== %s FINAL REREFERENCING ====\n',fileNameNoExt)
            EEG = rerefC2CN2NExt2Ext_func(EEG,fullRankAvRefBool);

            EEG1 = pop_select(EEG,'channel',sort([EEG_chans, EMG_chans, Noise_chans,Pong_chans,CIMU_chans]));%2022-5-13 not use EMG
            %                     [ALLEEG,EEG ] = eeg_store(ALLEEG,EEG2,0);
            EEG1 = pop_saveset(EEG1,'filepath',fullfile(P3_config.CleanEEG_output,'kin',fileNameNoExt),...
                'filename',sprintf('%s_cleanEEG_kin',fileNameNoExt),'savemode','twofiles'); %change to remove pipeline, this should be the STUDY-preprocess... folder.

            %             % HPG IMPLEMENTATION ONLY
            %             % SEND to HPG
            %             % define output paths
            %             amicaOutputFolder_local = fullfile(P3_config.CleanEEG_output,fileNameNoExt); %TH changed to match dir in line 326
            %             amicaOutputFolder_unix = fullfile(P3_config.amicaOutputFolder_unix,fileNameNoExt);
            %
            %             % write .sh script to subject folders
            %             disp([num2str(length(EEG_chans)),' remained']);
            %             txt_cmd{i} = prepare_HPG_AMICA_func_batch(EEG,sprintf('%s_cleanEEG',fileNameNoExt),...
            %                 amicaOutputFolder_local,amicaOutputFolder_unix,...
            %                 avgRefPCAReduction,P3_config.emailStr) %prepare AMICA files then follow instructions to manually run amica on hipergator
            %             % need to run script on HPG?
            %             if runAMICA
            %                 system([txt_cmd{i},''])
            %             end
            %             %              [ALLEEG, EEG, ~] = pop_newset(ALLEEG, EEG, 0,'retrieve',EEG_keep,'study',0);
            %             %              clear EEG
        end
        %         eeglab redraw

    end
    clear ALLEEG
    fprintf('==== FINISHING %s PROCESSING ====\n\n',fileNameNoExt)

end

%             PEEG = pop_select(EEG,'channel',sort([EEG_chans,Pong_chans,EMG_chans]));
%             % EEG = pop_select(EEG,'channel',sort([EMG_chans]));%2023-12-11 TH looking at ERSP of muscle channels between conditions to see what we are getting
%             %                     [ALLEEG,EEG ] = eeg_store(ALLEEG,EEG2,0);
%             PEEG = pop_saveset(PEEG,'filepath',fullfile(P3_config.CleanEEG_output,'kin',fileNameNoExt),...
%                 'filename',sprintf('%s_cleanEEG_kin',fileNameNoExt),'savemode','twofiles');
%




% fprintf('==== ENDING %s PROCESSING ====\n\n',subjStr)


% function saveTxt_prct(cleaningMethod)
%     preprocess_pipeline = [cleaningMethod];
%     mkdir(fullfile(MiM_config.CleanEEG_output,preprocess_pipeline,subjStr))
%     fid = fopen(fullfile(MiM_config.CleanEEG_output,preprocess_pipeline,subjStr,'info.txt'),'w');
%     fprintf(fid,['\n %.2f percent of frames were rejected\n'], p_frames_rej);
%     fprintf(fid,['\n %.2f channels were rejected\n'], p_chan_rej);
%     fclose(fid);
% end
%## TIME
toc
