% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Instituto Superior Tecnico
% Computational Vision - Lab 4
%
% Authors:
% David Marafuz Gaspar - 106541
% Pedro Gaspar Mónico - 106626
%
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

%% Task 2
img2 = imread('./Data/pillsetc.png');
img2_gray = rgb2gray(img2);

%% Direct Harris Corner Detection (noisy result)
corners = detectHarrisFeatures(img2_gray);

figure;
imshow(img2);
hold on;
plot(corners.selectStrongest(200));
title('Harris Corners - Direct (noisy)');

%% Preprocessing to reduce background noise

% Gaussian smoothing
img2_smooth = imfilter(img2_gray, fspecial('gaussian', 5, 0.1));

% Binarize to isolate objects from background
img2_bin = imbinarize(img2_smooth);

% Apply binary mask to grayscale image
img2_masked = img2_gray;
img2_masked(~img2_bin) = 0;

%% Harris Corner Detection on preprocessed image
corners_clean = detectHarrisFeatures(img2_masked);

% Extract corner locations from the object
pts = corners_clean.Location;

figure;
imshow(img2);
hold on;
plot(pts(:,1), pts(:,2), 'r+', 'MarkerSize', 10, 'LineWidth', 1.5);
title('Harris Corners - After Preprocessing');