clear, clc, clf, close all,
%% Load initial image and obtain a distorted version
% Load image and convert to grayscale
RGB=imread('peppers.png');
imgGS = rgb2gray(RGB);

% Distort the image
TP=[ 1 0.5 1; 0 1 .8; 0 0 1];
TPm=projective2d(TP');

% Image Transform
imgDist=imwarp(imgGS,TPm);


%% Detect and match features for image recovery
% Features and points of the original image
pointsOriginal=detectSURFFeatures(imgGS);
[featsOriginal, points1]=extractFeatures(imgGS, pointsOriginal);

% Features and points of the distorted image
pointsDistorted=detectSURFFeatures(imgDist);
[featsDistorted, points2]=extractFeatures(imgDist, pointsDistorted);

% Match features
matchedPairs=matchFeatures(featsOriginal, featsDistorted, 'Metric','normxcorr');

% Points of matched features
matchedPtsOriginal=points1(matchedPairs(:,1));
matchedPtsDistorted=points2(matchedPairs(:,2));


%% Recover image using a Geometric Transform
% Using the matched points, estimates the geometric transform
[tform,inlierPtsDistorted,inlierPtsOriginal] =estimateGeometricTransform(matchedPtsDistorted,matchedPtsOriginal,'affine');

% Recovers image
outputView=imref2d(size(imgGS));
imgRecovered=imwarp(imgDist,tform,'OutputView',outputView);


%% Plots
sgtitle('Image Recovery from Keypoint Matching')
subplot(2,2,1), imshow(imgGS), title('Original grayscale image');
subplot(2,2,2), imshow(imgDist), title('Distorted grayscale image');
subplot(2,2,3), showMatchedFeatures(imgGS,imgDist,matchedPtsOriginal,matchedPtsDistorted),...
    title('Matched interest points')
subplot(2,2,4), imshow(imgRecovered), title('Recovered image')
