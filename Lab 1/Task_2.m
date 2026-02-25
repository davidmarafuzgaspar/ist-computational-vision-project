% % % % % % % % % % % % % % % % 
% Instituto Superior Tecnico 
% Computational Vision - Lab 1
% 
% Authors:
% David Marafuz Gaspar - 106541
% Pedro Gaspar Mónico - 106626
%
% % % % % % % % % % % % % % % % 

%% Task 2
% Load the original image
img = imread('./Data/bottlecaps.jpg');

% Perform conversions
img_hsv = rgb2hsv(img);
img_ycbcr = rgb2ycbcr(img);
img_gray = rgb2gray(img);

% Save the new images
imwrite(img_hsv, './Data/bottlecaps_hsv.jpg');
imwrite(img_ycbcr, './Data/bottlecaps_ycbcr.jpg');
imwrite(img_gray, './Data/bottlecaps_gray.jpg');
