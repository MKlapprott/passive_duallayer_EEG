%% duallayer2_gerd_03_ICA.m
%
%
%
%
% Author: Melanie, 2025

%% Preparations

close all; clear all; clc;                                                                          % start with fresh workspace

% set paths

MAINPATH = 'R:\Ferris-Lab\mklapprott\eegl\';                                                        % adjust this path to your local environment!!!
PATHIN = [MAINPATH, 'rawdata\gerd\'];                                                                % path to raw data (changed from task-Flanker!!!)
PATHOUT = [MAINPATH, 'derivatives\gerd\'];                                                           % path for data derivatives created on the way

CHECKPATH = [PATHOUT, 'duallayer2_gerd_01_first-Check\'];
ICCPATH = [PATHOUT, 'duallayer2_gerd_02_iCC\'];                                                      % path for ICC data 

if ~isfolder(ICCPATH)                                                                                % if the path doesn't exist yet, create it
    mkdir(ICCPATH)
end

file_paths = dir(fullfile(CHECKPATH));                                                               % get access to all folder names
file_paths(1:2) = [];                                                                                % first two entries in the struct are empty
file_paths(end) = [];                                                                                % get rid of plots folder


cd(MAINPATH)
measurement_info = readtable([MAINPATH, 'measurement_info.xlsx']);                                  % load initial info table
load('params.mat');                                                                                 % load params (written in duallayer2_gerd_00_configfiles.m)
load('MEAS.mat');                                                                                   % load info struct, which is extended with each script


[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;                                                            % start EEGLAB
