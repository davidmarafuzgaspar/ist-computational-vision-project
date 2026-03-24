clear, clc, close all

%% TASK 2: Measure Planar Objects
% Adjust the number of images and the file path if using your own images!
numImages = 9;  % adjust for the max number of your images
files = cell(1, numImages);
for i = 1:numImages
    files{i} = fullfile('task2',sprintf('image%d.jpg', i));  %% MATLAB images
    % files{i} = fullfile('task2',sprintf('c1ima0%d.jpg', i));  % c1 images
    % files{i} = fullfile('task2',sprintf('c2ima0%d.jpg', i));  % c2 images
end

% Calibration image to perform the measurement
magnification = 25;
imgIdx = 9;
img = imread(files{imgIdx});
figure; imshow(img, InitialMagnification = magnification);
title("Input Image");


%% 1) Single Camera Parameters
% Functions to use: detectCheckerboardPoints, generateCheckerboardPoints, estimateCameraParameters

% Checkerboard detection
[imagePoints, boardSize] = detectCheckerboardPoints(files);
squareSize = 29; % in millimeters (EDIT IF USING YOUR OWN IMAGES)

% World coordinates


% Estimation of camera parameters


% Calibration accuracy.


%% 2) Remove distortion
% Functions to use: undistortImage

% Undistort image


%% 3) Coin segmentation and detection
% COMMENT OR CHANGE THIS LINE SO THAT "im" IS YOUR UNDISTORTED IMAGE
im = img;

% Segmentation
imHSV = rgb2hsv(im);
saturation = imHSV(:, :, 2);
t = graythresh(saturation);
imCoin = (saturation > t);
figure; imshow(imCoin, InitialMagnification = magnification);
title("Segmented Coins");

% Detection
blobAnalysis = vision.BlobAnalysis(AreaOutputPort = true,...
    CentroidOutputPort = false,...
    BoundingBoxOutputPort = true,...
    MinimumBlobArea = 200, ExcludeBorderBlobs = true);
[areas, boxes] = step(blobAnalysis, imCoin);

[~, idx] = sort(areas, "Descend");
boxes = double(boxes(idx(1:2), :));

scale = magnification / 100;
imDetectedCoins = imresize(im, scale);

% Labelling
imDetectedCoins = insertObjectAnnotation(imDetectedCoins, "rectangle", ...
    scale * boxes, "penny");
figure; imshow(imDetectedCoins);
title("Detected Coins");


%% 4) Estimation of Extrinsic Parameters
% Functions to use: detectCheckerboardPoints, estimateExtrinsics

% Detect the checkerboard of the image to perform the measurement


% Obtain intrinsics


% Obtain extrinsics


%% 5) Coin measurement
% REMOVE THE "return" SO THAT THE REMAINING CODE RUNS
return

% Diameter
boxes = boxes + [newOrigin, 0, 0]; % zero padding is added for width and height
box1 = double(boxes(1, :));
imagePoints1 = [box1(1:2); ...
                box1(1) + box1(3), box1(2)];  
worldPoints1 = img2world2d(imagePoints1, camExtrinsics, camIntrinsics);
d = worldPoints1(2, :) - worldPoints1(1, :);
diameterInMillimeters = hypot(d(1), d(2));
fprintf("Measured diameter of one penny = %0.2f mm\n", diameterInMillimeters);

% Distance
center1_image = box1(1:2) + box1(3:4)/2;
center1_world  = img2world2d(center1_image, camExtrinsics, camIntrinsics);
center1_world = [center1_world 0];
cameraPose = extr2pose(camExtrinsics);
cameraLocation = cameraPose.Translation;
distanceToCamera = norm(center1_world - cameraLocation);
fprintf("Distance from the camera to the first penny = %0.2f mm\n", ...
    distanceToCamera);
