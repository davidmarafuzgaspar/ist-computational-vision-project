% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Instituto Superior Tecnico
% Computational Vision - Lab 10 - Task 2
%
% Authors:
% David Marafuz Gaspar - 106541
% Pedro Gaspar Mónico - 106626
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

% Load images from location
leftImages = imageDatastore('./Data/real_left');
rightImages = imageDatastore('./Data/real_right');

% Square size (in mm)
squareSize = 17;

% Image size
I = readimage(leftImages, 1);
imageSize = [size(I,1), size(I,2)];

% Left camera calibration (intrinsic parameters only)
[pointsLeft, boardSizeLeft] = detectCheckerboardPoints(leftImages.Files);
worldPointsLeft = generateCheckerboardPoints(boardSizeLeft, squareSize);
paramsLeft = estimateCameraParameters(pointsLeft, worldPointsLeft, ...
    'ImageSize', imageSize);

% Right camera calibration (intrinsic parameters only)
[pointsRight, boardSizeRight] = detectCheckerboardPoints(rightImages.Files);
worldPointsRight = generateCheckerboardPoints(boardSizeRight, squareSize);
paramsRight = estimateCameraParameters(pointsRight, worldPointsRight, ...
    'ImageSize', imageSize);

%% Load a Specific Pair of Images for Measuring
% Index (to choose from several images)
index = 10;
I1 = readimage(leftImages, index);
I2 = readimage(rightImages, index);

%% Step 1: Undistort Images Using Individual Intrinsic Parameters
I1_undistorted = undistortImage(I1, paramsLeft);
I2_undistorted = undistortImage(I2, paramsRight);

%% Step 2: Detect, Extract and Match SURF Features
I1gray = im2gray(I1_undistorted);
I2gray = im2gray(I2_undistorted);

% Use only the strongest features to reduce noise
imagePoints1 = detectSURFFeatures(I1gray, 'MetricThreshold', 1000);
imagePoints2 = detectSURFFeatures(I2gray, 'MetricThreshold', 1000);

features1 = extractFeatures(I1gray, imagePoints1);
features2 = extractFeatures(I2gray, imagePoints2);

% Lowe's ratio test (MaxRatio) + Unique=true removes ambiguous 1-to-many matches
indexPairs = matchFeatures(features1, features2, ...
    'MaxRatio',    0.7,  ... % default is 0.6–0.75; lower = stricter
    'Unique',      true, ... % each feature can only appear in one pair
    'MatchThreshold', 50);   % lower = fewer but more confident matches

matchedPoints1 = imagePoints1(indexPairs(:, 1));
matchedPoints2 = imagePoints2(indexPairs(:, 2));

%% Step 2b: Geometric Outlier Rejection via Fundamental Matrix (RANSAC)
% A second RANSAC pass using epipolar geometry removes remaining spatial outliers
% before the Essential Matrix is estimated.
if size(matchedPoints1, 1) < 8
    error('Too few matches (%d) for robust estimation.', size(matchedPoints1,1));
end

[~, epipolarInliers] = estimateFundamentalMatrix( ...
    matchedPoints1, matchedPoints2, ...
    'Method',       'RANSAC', ...
    'NumTrials',    2000,     ...
    'DistanceThreshold', 1.5, ...  % pixels; tighter = stricter
    'Confidence',   99.99);

matchedPoints1 = matchedPoints1(epipolarInliers);
matchedPoints2 = matchedPoints2(epipolarInliers);

fprintf('After geometric filtering: %d inliers from %d initial matches.\n', ...
    sum(epipolarInliers), numel(epipolarInliers));

% Visualise matched feature points (post-filtering)
figure;
showMatchedFeatures(I1gray, I2gray, matchedPoints1, matchedPoints2, 'montage');
title(sprintf('Matched SURF Features — %d inliers (post-filtering)', sum(epipolarInliers)));

%% Step 3: Estimate the Essential Matrix
% Requires intrinsic parameters of both cameras
% RANSAC is used internally to reject outliers
[E, inliersIdx, status] = estimateEssentialMatrix( ...
    matchedPoints1, matchedPoints2, ...
    paramsLeft.Intrinsics, paramsRight.Intrinsics, ...
    'Confidence', 99, ...
    'MaxNumTrials', 2000);

if status ~= 0
    error('Essential Matrix estimation failed. Try increasing MaxNumTrials or check feature matches.');
end

fprintf('Essential Matrix estimated with %d inliers out of %d matches.\n', ...
    sum(inliersIdx), numel(inliersIdx));

% Keep only inlier matched points for a more robust pose estimate
inlierPoints1 = matchedPoints1(inliersIdx);
inlierPoints2 = matchedPoints2(inliersIdx);

%% Step 4: Recover Relative Camera Pose from Essential Matrix
% relativeOrientation : 3x3 rotation matrix  (R)  — orientation of cam 2 w.r.t cam 1
% relativeLocation    : 1x3 unit translation vector (t) — direction only, no scale
[relativeOrientation, relativeLocation] = relativeCameraPose( ...
    E, paramsLeft.Intrinsics, paramsRight.Intrinsics, ...
    inlierPoints1, inlierPoints2);

fprintf('Relative Location (unit vector): [%.4f, %.4f, %.4f]\n', ...
    relativeLocation(1), relativeLocation(2), relativeLocation(3));

%% Step 5: Recover the Translation Scale Using the Checkerboard
% relativeLocation is a unit vector — scale must be recovered externally.
% Strategy: use the known stereo baseline from a checkerboard image pair.
%   triangulate a checkerboard corner using Task-1 stereo params, then
%   solve for the scalar s such that  s * relativeLocation  matches that baseline.
%
% Here we use the first calibration image pair (known geometry) to estimate
% the baseline via triangulation of the (1,1) checkerboard corner.

I1_cal = readimage(leftImages, 10);
I2_cal = readimage(rightImages, 10);

I1_cal_u = undistortImage(I1_cal, paramsLeft);
I2_cal_u = undistortImage(I2_cal, paramsRight);

% Detect checkerboard corners in the calibration pair
[corners1, ~] = detectCheckerboardPoints(I1_cal_u);
[corners2, ~] = detectCheckerboardPoints(I2_cal_u);

% Build a minimal stereo params object with unit translation to triangulate
unitStereoParams = stereoParameters(paramsLeft, paramsRight, ...
    relativeOrientation, relativeLocation);

% Triangulate the first corner with unit translation
corner3d_unit = triangulate(corners1(1,:), corners2(1,:), unitStereoParams);

% Now build the Task-1 full stereo calibration to get the true 3D position
[imagePointsBoth, boardSizeBoth] = detectCheckerboardPoints( ...
    leftImages.Files, rightImages.Files);
worldPointsBoth = generateCheckerboardPoints(boardSizeBoth, squareSize);
paramsFull = estimateCameraParameters(imagePointsBoth, worldPointsBoth, ...
    'ImageSize', imageSize);

corner3d_true = triangulate(corners1(1,:), corners2(1,:), paramsFull);

% Scale factor: ratio of true distance to unit-translation distance
scaleFactor = norm(corner3d_true) / norm(corner3d_unit);
scaledLocation = relativeLocation * scaleFactor;

fprintf('Scale factor recovered: %.4f mm\n', scaleFactor);
fprintf('Scaled translation vector: [%.2f, %.2f, %.2f] mm\n', ...
    scaledLocation(1), scaledLocation(2), scaledLocation(3));

%% Step 6: Build Scaled Stereo Parameters
stereoParamsEstimated = stereoParameters(paramsLeft, paramsRight, ...
    relativeOrientation, scaledLocation);

%% Step 7: Face Detection and Distance Measurement (same as Task 1)
faceDetector = vision.CascadeObjectDetector( ...
    'MergeThreshold',  4,    ... % lower = more sensitive (default is 4, try 2)
    'MinSize',         [30 30], ... % allow smaller faces
    'MaxSize',         [400 400]); % allow larger faces too
face1_bbox = step(faceDetector, I1_undistorted);
face2_bbox = step(faceDetector, I2_undistorted);

if isempty(face1_bbox) || isempty(face2_bbox)
    error('No face detected in one or both images. Try a different image index.');
end

face1 = face1_bbox(1, :);
face2 = face2_bbox(1, :);

% Centre of each bounding box
center1 = [face1(1) + face1(3)/2,  face1(2) + face1(4)/2];
center2 = [face2(1) + face2(3)/2,  face2(2) + face2(4)/2];

%% Step 8: Triangulate and Compute Distance
point3d_estimated = triangulate(center1, center2, stereoParamsEstimated);
distanceInMeters_estimated = norm(point3d_estimated) / 1000;

fprintf('\n--- Distance Estimation Comparison ---\n');
fprintf('Task 2 (estimated extrinsics) : %.2f meters\n', distanceInMeters_estimated);

% Compare with Task 1 ground truth (full stereo calibration)
point3d_true = triangulate(center1, center2, paramsFull);
distanceInMeters_true = norm(point3d_true) / 1000;
fprintf('Task 1 (known extrinsics)      : %.2f meters\n', distanceInMeters_true);
fprintf('Absolute error                 : %.4f meters\n', ...
    abs(distanceInMeters_estimated - distanceInMeters_true));

%% Step 9: Annotate and Display Results
distanceStr_estimated = sprintf('Est: %0.2f m', distanceInMeters_estimated);
distanceStr_true      = sprintf('GT:  %0.2f m', distanceInMeters_true);

I1_annotated = insertObjectAnnotation(I1_undistorted, 'rectangle', face1, ...
    distanceStr_estimated, 'FontSize', 18);
I2_annotated = insertObjectAnnotation(I2_undistorted, 'rectangle', face2, ...
    distanceStr_estimated, 'FontSize', 18);


% Optionally fill the rectangle for stronger visual emphasis
I1_annotated = insertShape(I1_undistorted, 'filled-rectangle', face1);
I2_annotated = insertShape(I2_undistorted, 'filled-rectangle', face2);

figure;
imshowpair(I1_annotated, I2_annotated, 'montage');
title(sprintf('Task 2 — Estimated Extrinsics | %s  (Ground truth: %s)', ...
    distanceStr_estimated, distanceStr_true));