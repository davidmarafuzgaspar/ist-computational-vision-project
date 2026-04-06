% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Instituto Superior Tecnico
% Computational Vision - Lab 4 - Task 3
%
% Authors:
% David Marafuz Gaspar - 106541
% Pedro Gaspar Mónico - 106626
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

% 1. Load the image (Ensure it is in your working directory)
img_original = imread('./Data/pillsetc.png');

% 2. Convert to grayscale as required for circle detection 
img_gray = rgb2gray(img_original);

% 3. Detect circles using the Hough Transform
% Radius range: 10 to 200 pixels 
[centers, radii] = imfindcircles(img_gray, [10 200]);

% 4. Visualize the results
figure('Name', 'Task 3: Circle Detection');
imshow(img_original);
hold on;

% Plot detected circles
% 'viscircles' is the recommended function for this 
viscircles(centers, radii, 'EdgeColor', 'r');
title('Circles detected in pillsetc.png');
hold off;

% Display numerical results
fprintf('Number of circles detected: %d\n', length(radii));