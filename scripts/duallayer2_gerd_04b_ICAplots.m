%% duallayer2_gerd_04b_ICAplots.m




%% Preparations

close all; clear all; clc;                                                                          % start with fresh workspace

% set paths --------------------------------------------------------------------------------------

MAINPATH = 'R:\Ferris-Lab\mklapprott\eegl\';                                                        % adjust this path to your local environment!!!
PATHOUT = [MAINPATH, 'derivatives\gerd\'];                                                           % path for data derivatives created on the way

ICAPATH = [PATHOUT, 'duallayer2_gerd_03_iCA\'];                                                      % path for ICA data 

% parameters -------------------------------------------------------------------------------------

cd(MAINPATH)
load('MEAS.mat');
load('df_params.mat')

rest_count = 1;
slow_count = 1;
mid_count = 1;
fast_count = 1;
walk_count = 1;


%%


for meas = 1:length(MEASUREMENTS)

    SUBICAPATH = [ICAPATH, MEASUREMENTS(meas).ID, '\'];
    cd(SUBICAPATH)                                                                                  % set filepath
    files = dir(fullfile(SUBICAPATH, '*.set'));                                                     % get access to data sets

    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;                                                        % start EEGLAB


    for file = 1:length(files)

        file_name = files(file).name;                                                               % get current file name
        EEG = pop_loadset('filename',file_name,'filepath',SUBICAPATH);
    
        [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);

        if contains(file_name, 'trad')
            iCC_cond = 'trad';
        elseif contains(file_name, 'ICC')
            iCC_cond = 'ICC';
        end

        pop_dipplot( EEG, 1,'mri',[MAINPATH, 'standard_mri.mat'],'normlen','on', 'view', [1 0 0]);
        saveas(gca, [MEASUREMENTS(meas).ID, '_', iCC_cond, '-DipFit.png']);                                % save plot
        close;
        pop_topoplot(EEG, 0, [1:4] ,[MEASUREMENTS(meas).ID, '_', iCC_cond, '-ICA-Topos'],[2 2] ,1,'electrodes','on');
        saveas(gca, [MEASUREMENTS(meas).ID, '_', iCC_cond, '-ICA-Topos.png']);                                % save plot
        close;



        if contains(file_name, 'rest') && strcmp(iCC_cond, 'trad')
            DIPS(meas).area{file} = EEG.dipfit.model(1).areadk;
            DIPS(meas).rv(file) = EEG.dipfit.model(1).rv;
            rv(meas, file) = EEG.dipfit.model(1).rv;
            areas{meas, file} = EEG.dipfit.model(1).areadk;
            
            rv_rest_t(rest_count) = EEG.dipfit.model(1).rv;
            rest_count = rest_count + 1;
        
        elseif contains(file_name, 'slow') && strcmp(iCC_cond, 'trad')

            if contains(file_name, 'trans')
                DIPS(meas).area{file} = EEG.dipfit.model(3).areadk;
                DIPS(meas).rv(file) = EEG.dipfit.model(3).rv;
                rv(meas, file) = EEG.dipfit.model(3).rv;
                
                areas{meas, file} = EEG.dipfit.model(3).areadk;
                rv_slow_t(slow_count) = EEG.dipfit.model(3).rv;
                slow_count = slow_count + 1;
            elseif contains(file_name, 'roll')
                DIPS(meas).area{file} = EEG.dipfit.model(2).areadk;
                DIPS(meas).rv(file) = EEG.dipfit.model(2).rv;
                rv(meas, file) = EEG.dipfit.model(2).rv;
                
                areas{meas, file} = EEG.dipfit.model(2).areadk;
                rv_slow_t(slow_count) = EEG.dipfit.model(2).rv;
                slow_count = slow_count + 1;
            end

        elseif contains(file_name, 'mid') && strcmp(iCC_cond, 'trad')
            DIPS(meas).area{file} = EEG.dipfit.model(3).areadk;
            DIPS(meas).rv(file) = EEG.dipfit.model(3).rv;
            rv(meas, file) = EEG.dipfit.model(3).rv;
            areas{meas, file} = EEG.dipfit.model(3).areadk;

            rv_mid_t(mid_count) = EEG.dipfit.model(3).rv;
            mid_count = mid_count + 1;
        
        elseif contains(file_name, 'fast') && strcmp(iCC_cond, 'trad')
            DIPS(meas).area{file} = EEG.dipfit.model(4).areadk;
            DIPS(meas).rv(file) = EEG.dipfit.model(4).rv;
            rv(meas, file) = EEG.dipfit.model(4).rv;
            areas{meas, file} = EEG.dipfit.model(4).areadk;

            rv_fast_t(fast_count) = EEG.dipfit.model(4).rv;
            fast_count = fast_count + 1;
        
        elseif contains(file_name, 'walk') && strcmp(iCC_cond, 'trad')
            DIPS(meas).area{file} = EEG.dipfit.model(3).areadk;
            DIPS(meas).rv(file) = EEG.dipfit.model(3).rv;
            rv(meas, file) = EEG.dipfit.model(3).rv;
            areas{meas, file} = EEG.dipfit.model(3).areadk;

            rv_walk_t(walk_count) = EEG.dipfit.model(3).rv;
            walk_count = walk_count + 1;

        elseif contains(file_name, 'rest') && strcmp(iCC_cond, 'ICC')
            DIPS(meas).area{file} = EEG.dipfit.model(1).areadk;
            DIPS(meas).rv(file) = EEG.dipfit.model(1).rv;
            rv(meas, file) = EEG.dipfit.model(1).rv;
            areas{meas, file} = EEG.dipfit.model(1).areadk;

            rv_rest_i(rest_count) = EEG.dipfit.model(1).rv;
            rest_count = rest_count + 1;
        
        elseif contains(file_name, 'slow') && strcmp(iCC_cond, 'ICC')
            DIPS(meas).area{file} = EEG.dipfit.model(1).areadk;
            DIPS(meas).rv(file) = EEG.dipfit.model(1).rv;
            rv(meas, file) = EEG.dipfit.model(1).rv;
            areas{meas, file} = EEG.dipfit.model(1).areadk;

            rv_slow_i(slow_count) = EEG.dipfit.model(1).rv;
            slow_count = slow_count + 1;
        
        elseif contains(file_name, 'mid') && strcmp(iCC_cond, 'ICC')
            DIPS(meas).area{file} = EEG.dipfit.model(1).areadk;
            DIPS(meas).rv(file) = EEG.dipfit.model(1).rv;
            rv(meas, file) = EEG.dipfit.model(1).rv;
            areas{meas, file} = EEG.dipfit.model(1).areadk;

            rv_mid_i(mid_count) = EEG.dipfit.model(1).rv;
            mid_count = mid_count + 1;
        
        elseif contains(file_name, 'fast') && strcmp(iCC_cond, 'ICC')
            DIPS(meas).area{file} = EEG.dipfit.model(1).areadk;
            DIPS(meas).rv(file) = EEG.dipfit.model(1).rv;
            rv(meas, file) = EEG.dipfit.model(1).rv;
            areas{meas, file} = EEG.dipfit.model(1).areadk;

            rv_fast_i(fast_count) = EEG.dipfit.model(1).rv;
            fast_count = fast_count + 1;
        
        elseif contains(file_name, 'walk') && strcmp(iCC_cond, 'ICC')
            DIPS(meas).area{file} = EEG.dipfit.model(1).areadk;
            DIPS(meas).rv(file) = EEG.dipfit.model(1).rv;
            rv(meas, file) = EEG.dipfit.model(1).rv;
            areas{meas, file} = EEG.dipfit.model(1).areadk;

            rv_walk_i(walk_count) = EEG.dipfit.model(1).rv;
            walk_count = walk_count + 1;

        end

    end

end

%%

all_rvs = [rv(1,1), mean([rv(2,1), rv(5,1)]), mean([rv(3,1), rv(6,1)]), mean([rv(4,1), rv(7,1)]), mean([rv(8,1), rv(9,1)]);
    rv(1,2), mean([rv(2,2), rv(5,2)]), mean([rv(3,2), rv(6,2)]), mean([rv(4,2), rv(7,2)]), mean([rv(8,2), rv(9,2)])]';

IDs = {'rest', 'slow', 'mid', 'fast', 'walk', 'rest', 'slow', 'mid', 'fast', 'walk'};
cond = {'iCC', 'iCC',  'iCC', 'iCC',  'iCC',  'trad', 'trad', 'trad' 'trad', 'trad'};

T = table(IDs', cond', vertcat(all_rvs(:,1), all_rvs(:,2)), ...
     'VariableNames', {'ID', 'Pipeline','RV'});

writetable(T, [MAINPATH, 'Gerd_DF_RV.txt']);

figure;
bar(all_rvs)
legend('iCC', 'trad')
title('Residual variace of the 1st component dipole')
ylabel('RV')
