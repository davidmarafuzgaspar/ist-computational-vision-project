clear, clc, close all
%% TASK 1: Measure Distance to Objects

%% Image Loading and Stereo Camera Calibration
% Load images from location
leftImages = imageDatastore('left');
rightImages = imageDatastore('right');

% Square size
squareSize = 108;

% Image size
I = readimage(leftImages, 1); 
imageSize = [size(I,1), size(I,2)];

% Stereo calibration
[imagePoints,boardSize] = detectCheckerboardPoints(leftImages.Files,rightImages.Files);

% Specify world coordinates
worldPoints = generateCheckerboardPoints(boardSize,squareSize);

params = estimateCameraParameters(imagePoints,worldPoints, ...
    "ImageSize",imageSize);


%% Load a Specific Pair of Images for Measuring
% Index (to choose from several images)
index = 10;
I1 = readimage(leftImages, index);
I2 = readimage(rightImages, index);
imshowpair(I1, I2, 'montage');

% Undistort images


% Face detection


% Center computation


% Triangulation


% Image display
% distanceAsString = sprintf('%0.2f meters', distanceInMeters);
% I1 = insertObjectAnnotation(I1,'rectangle',face1,distanceAsString,'FontSize',18);
% I2 = insertObjectAnnotation(I2,'rectangle',face2, distanceAsString,'FontSize',18);
% I1 = insertShape(I1,'filled-rectangle',face1);
% I2 = insertShape(I2,'filled-rectangle',face2);
% imshowpair(I1, I2, 'montage');
