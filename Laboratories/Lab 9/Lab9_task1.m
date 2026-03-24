clear, clc, close all
%% TASK 1: Stereo Camera Calibration
% Load images
leftImages = imageDatastore("task1_left");
rightImages = imageDatastore("task1_right");

% Detect checkerboard


% Specify world coordinates
squareSize = 108; % replace with the measured size if using your own images

% Calibrate stereo setup


% Show projection errors and camera extrinsics

