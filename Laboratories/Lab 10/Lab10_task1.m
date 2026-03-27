clear, clc, close all

%% TASK 1: Measure Distance to Objects

%% Image Loading and Stereo Camera Calibration
% Load images from location
leftImages = imageDatastore('./Data/real_left');
rightImages = imageDatastore('./Data/real_right');

% Square size (in mm)
squareSize = 17;

% Image size
I = readimage(leftImages, 1);
imageSize = [size(I,1), size(I,2)];

% Stereo calibration
[imagePoints, boardSize] = detectCheckerboardPoints(leftImages.Files, rightImages.Files);

% Specify world coordinates
worldPoints = generateCheckerboardPoints(boardSize, squareSize);

% Estimate stereo camera parameters
params = estimateCameraParameters(imagePoints, worldPoints, ...
    "ImageSize", imageSize);

% Visualize calibration errors
figure;
showReprojectionErrors(params);
title('Reprojection Errors');

% Visualize extrinsic parameters
figure;
showExtrinsics(params);
title('Extrinsic Parameters');

%% Load a Specific Pair of Images for Measuring
% Index (to choose from several images)
index = 10;
I1 = readimage(leftImages, index);
I2 = readimage(rightImages, index);

% Show original image pair
figure;
imshowpair(I1, I2, 'montage');
title('Original Image Pair');

%% Step 1: Undistort Images
% Remove lens distortion using the estimated stereo parameters
I1_undistorted = undistortImage(I1, params.CameraParameters1);
I2_undistorted = undistortImage(I2, params.CameraParameters2);

%% Step 2: Face Detection
% Create a cascade object detector for frontal faces
faceDetector = vision.CascadeObjectDetector();

% Detect faces in each undistorted image
face1_bbox = step(faceDetector, I1_undistorted); % [x, y, width, height]
face2_bbox = step(faceDetector, I2_undistorted);

% Check that exactly one face was detected in each image
if isempty(face1_bbox) || isempty(face2_bbox)
    error('No face detected in one or both images. Try a different image pair.');
end

% If multiple faces detected, keep only the first (largest area or first result)
face1 = face1_bbox(1, :);
face2 = face2_bbox(1, :);

%% Step 3: Compute Center of Each Detected Face
% The center point is [x + width/2, y + height/2]
center1 = [face1(1) + face1(3)/2, face1(2) + face1(4)/2];
center2 = [face2(1) + face2(3)/2, face2(2) + face2(4)/2];

%% Step 4: Triangulate to Find 3D Location
% Use the stereo parameters and the two 2D points to estimate the 3D point
% point3d is in the same units as squareSize (mm)
point3d = triangulate(center1, center2, params);

% Compute the Euclidean distance from the left (reference) camera in meters
distanceInMillimeters = norm(point3d);
distanceInMeters = distanceInMillimeters / 1000;

fprintf('Estimated distance to face: %.2f meters\n', distanceInMeters);

%% Step 5: Display Results
% Format the distance string for annotation
distanceAsString = sprintf('%0.2f meters', distanceInMeters);

% Annotate both images with the bounding box and distance label
I1_annotated = insertObjectAnnotation(I1_undistorted, 'rectangle', face1, ...
    distanceAsString, 'FontSize', 18);
I2_annotated = insertObjectAnnotation(I2_undistorted, 'rectangle', face2, ...
    distanceAsString, 'FontSize', 18);

% Optionally fill the rectangle for stronger visual emphasis
I1_annotated = insertShape(I1_undistorted, 'filled-rectangle', face1);
I2_annotated = insertShape(I2_undistorted, 'filled-rectangle', face2);

% Display the annotated image pair side by side
figure;
imshowpair(I1_annotated, I2_annotated, 'montage');
title(sprintf('Detected Face — Distance: %s', distanceAsString));