clear, clc, close all
%% TASK 2: Estimation of Extrinsic Parameters

%% Image Loading and Stereo Camera Calibration
% Load images from location
leftImages = imageDatastore('left');
rightImages = imageDatastore('right');

% Square size
squareSize = 108;

% Image size
I = readimage(leftImages, 1); 
imageSize = [size(I,1), size(I,2)];

% Left camera calibration (intrisic parameters)
[pointsLeft, boardSizeLeft] = detectCheckerboardPoints(leftImages.Files);
worldPointsLeft = generateCheckerboardPoints(boardSizeLeft, squareSize);
paramsLeft = ...
    estimateCameraParameters(pointsLeft, worldPointsLeft, 'ImageSize', imageSize);

% Right camera calibration (intrisic parameters)
[pointsRight, boardSizeRight] = detectCheckerboardPoints(rightImages.Files);
worldPointsRight = generateCheckerboardPoints(boardSizeRight, squareSize);
paramsRight = ...
    estimateCameraParameters(pointsRight, worldPointsRight, 'ImageSize', imageSize);


%% Load a Specific Pair of Images for Measuring
% Index (to choose from several images)
index = 10;
I1 = readimage(leftImages, index);
I2 = readimage(rightImages, index);

% Grayscale conversion
I1gray = im2gray(I1);
I2gray = im2gray(I2);

% Detect, extract and match features
imagePoints1 = detectSURFFeatures(I1gray);
imagePoints2 = detectSURFFeatures(I2gray);
features1 = extractFeatures(I1gray, imagePoints1);
features2 = extractFeatures(I2gray, imagePoints2);
indexPairs = matchFeatures(features1,features2);
matchedPoints1 = imagePoints1(indexPairs(:,1));
matchedPoints2 = imagePoints2(indexPairs(:,2));

% Essential/Fundamental matrix estimation


% Relative orientation and relative location

