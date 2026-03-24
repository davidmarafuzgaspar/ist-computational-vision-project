clear; clc; close all

%% TASK 1: Stereo Camera Calibration

% Load images
leftImages = imageDatastore("task1_real_left");
rightImages = imageDatastore("task1_real_right");

% Detect checkerboard corners
[imagePoints, boardSize] = detectCheckerboardPoints( ...
    leftImages.Files, rightImages.Files);

% Generate world coordinates (real-world positions of checkerboard corners)
squareSize = 108; % in mm (or your chosen unit)
worldPoints = generateCheckerboardPoints(boardSize, squareSize);

% Get image size
I = readimage(leftImages, 1);
imageSize = [size(I,1), size(I,2)];

% Calibrate stereo camera
stereoParams = estimateCameraParameters( ...
    imagePoints, worldPoints, ...
    'ImageSize', imageSize);

% Show reprojection errors
figure;
showReprojectionErrors(stereoParams);

% Show extrinsic parameters (camera positions)
figure;
showExtrinsics(stereoParams);