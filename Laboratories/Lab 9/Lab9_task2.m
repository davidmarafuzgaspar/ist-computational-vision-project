clear; clc; close all

%% TASK 2: Measure Planar Objects

% Adjust number of images if needed
numImages = 9;
files = cell(1, numImages);

for i = 1:numImages
    files{i} = fullfile('task2_real', sprintf('c2ima0%d.jpg', i));
end

% Select image for measurement
magnification = 25;
imgIdx = 9;
img = imread(files{imgIdx});

figure; imshow(img, 'InitialMagnification', magnification);
title("Input Image");

%% 1) Single Camera Calibration

% Detect checkerboard points
[imagePoints, boardSize] = detectCheckerboardPoints(files);

% Define square size (mm)
squareSize = 19;

% Generate world coordinates
worldPoints = generateCheckerboardPoints(boardSize, squareSize);

% Get image size
I = imread(files{1});
imageSize = [size(I,1), size(I,2)];

% Estimate camera parameters
cameraParams = estimateCameraParameters( ...
    imagePoints, worldPoints, ...
    'ImageSize', imageSize);

% Show calibration accuracy
figure;
showReprojectionErrors(cameraParams);
title("Reprojection Errors");

%% 2) Remove distortion

[im, newOrigin] = undistortImage(img, cameraParams);

figure; imshow(im, 'InitialMagnification', magnification);
title("Undistorted Image");

%% 3) Coin segmentation and detection

% Convert to HSV
imHSV = rgb2hsv(im);
saturation = imHSV(:, :, 2);

% Thresholding
t = graythresh(saturation);
imCoin = (saturation > t);

figure; imshow(imCoin, 'InitialMagnification', magnification);
title("Segmented Coins");

% Blob detection
blobAnalysis = vision.BlobAnalysis( ...
    'AreaOutputPort', true, ...
    'CentroidOutputPort', false, ...
    'BoundingBoxOutputPort', true, ...
    'MinimumBlobArea', 200, ...
    'ExcludeBorderBlobs', true);

[areas, boxes] = step(blobAnalysis, imCoin);

% Sort largest blobs (coins)
[~, idx] = sort(areas, "descend");
boxes = double(boxes(idx(1:2), :));

% Display detected coins
scale = magnification / 100;
imDetectedCoins = imresize(im, scale);

imDetectedCoins = insertObjectAnnotation( ...
    imDetectedCoins, "rectangle", ...
    scale * boxes, "coin");

figure; imshow(imDetectedCoins);
title("Detected Coins");

%% 4) Estimate Extrinsic Parameters

% Detect checkerboard in measurement image
[imagePoints2, ~] = detectCheckerboardPoints(img);

% Get intrinsics
camIntrinsics = cameraParams.Intrinsics;

% Estimate extrinsics
camExtrinsics = estimateExtrinsics( ...
    imagePoints2, worldPoints, camIntrinsics);

%% 5) Coin Measurement

% Adjust coordinates due to undistortion
boxes = boxes + [newOrigin, 0, 0];

% Select one coin
box1 = double(boxes(1, :));

% Two points across diameter
imagePoints1 = [ ...
    box1(1:2); ...
    box1(1) + box1(3), box1(2)];

% Convert to world coordinates
worldPoints1 = pointsToWorld( ...
    camIntrinsics, ...
    camExtrinsics.Rotation, ...
    camExtrinsics.Translation, ...
    imagePoints1);

% Compute diameter
d = worldPoints1(2,:) - worldPoints1(1,:);
diameterInMillimeters = hypot(d(1), d(2));

fprintf("Measured diameter of coin = %.2f mm\n", diameterInMillimeters);

%% Distance to camera

% Center of coin (image)
center1_image = box1(1:2) + box1(3:4)/2;

% Convert to world coordinates
center1_world = pointsToWorld( ...
    camIntrinsics, ...
    camExtrinsics.Rotation, ...
    camExtrinsics.Translation, ...
    center1_image);

center1_world = [center1_world 0];

% Camera pose
cameraPose = extr2pose(camExtrinsics);
cameraLocation = cameraPose.Translation;

% Distance
distanceToCamera = norm(center1_world - cameraLocation);

fprintf("Distance from camera = %.2f mm\n", distanceToCamera);
