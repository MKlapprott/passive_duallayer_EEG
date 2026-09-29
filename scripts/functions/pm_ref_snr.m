function snr = pm_ref_snr(data, P3_st_idx, P3_sp_idx)

% PM_REF_SNR Estimate ERP signal-to-noise ratio using Schimmel's (+–) reference method.
%
%   snr = PM_REF_SNR(data)
%
%   This function implements the plus-minus reference (Schimmel, 1967) to 
%   estimate the signal-to-noise ratio (SNR) of an ERP component.
%
%   The input data is split into two equal sets of trials, averaged separately, 
%   and then combined to yield:
%       - ERP_PH : (A + B)/2, an estimate of the evoked response (signal)
%       - Noise  : (A – B)/2, an estimate of residual noise
%
%   The SNR is computed as the ratio of the root-mean-square (RMS) amplitude
%   of the ERP to the RMS amplitude of the noise within a specified time window.
%
%   INPUT:
%       data : [channels x time x trials] EEG data matrix
%
%   OUTPUT:
%       snr  : scalar SNR value (RMS(signal) / RMS(noise)) in the selected window
%
%   NOTE:
%       - The time window indices (P3_st_idx, P3_sp_idx) must be defined in the
%         workspace before calling this function.
%       - Since the trial split is random, results can vary across calls.
%         For stable estimates, consider repeating the procedure multiple times
%         and averaging the resulting SNR values.
%
%   Reference:
%       Schimmel, H. (1967). The (+-) reference: Accuracy of estimated mean 
%       components in average response studies. Electroencephalography and 
%       Clinical Neurophysiology, 23(4), 403–405.


id = randperm(size(data, 3));                                                                      % idx to separate the data into 2sets
data = squeeze(data)';                                                                              % trials x time
set1 = data(id(1:floor(size(data, 1)/2)),:);                                                       % set 1
set2 = data(id(floor(size(data, 1)/2)+1:end),:);                                                   % set 2

A = mean(set1,1);                                                                                   % P3 mean set 1
B = mean(set2,1);                                                                                   % P3 mean set 2

le_ERP_PH = (A + B)/2;                                                                                 % whole ERP
Noise = (A - B)/2;                                                                                  % whole Noise estimate       

signalRMS = rms(le_ERP_PH(P3_st_idx:P3_sp_idx));                                                  
noiseRMS  = rms(Noise(P3_st_idx:P3_sp_idx));                                                        % RMS-based SNR in a time window

snr = signalRMS / noiseRMS;


end
