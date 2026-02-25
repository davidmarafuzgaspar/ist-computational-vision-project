% % % % % % % % % % % % % % % % 
% Instituto Superior Tecnico 
% Computational Vision - Lab 1
% 
% Authors:
% David Marafuz Gaspar - 106541
% Pedro Gaspar Mónico - 106626
%
% % % % % % % % % % % % % % % % 

%% Task 3
% Load the bottlecaps image and convert to grayscale
img = imread('./Data/bottlecaps.jpg');
img_gray = rgb2gray(img);

% Create a figure for comparison
figure('Name', 'Task 3: Histogram Analysis');

% Subplot 1: The Grayscale Image
subplot(1,2,1);
imshow(img_gray);
title('Grayscale Image (Bottlecaps)');

% Subplot 2: The Histogram
subplot(1,2,2);
imhist(img_gray);
title('Intensity Histogram');
xlabel('Pixel Intensity (0-255)');
ylabel('Pixel Count');
