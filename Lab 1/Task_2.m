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
img_rgb = imread('./Data/bottlecaps.jpg');

% Perform conversions
img_hsv = rgb2hsv(img_rgb);
img_ycbcr = rgb2ycbcr(img_rgb);
img_gray = rgb2gray(img_rgb);

% Save the new images
imwrite(img_hsv, './Data/bottlecaps_hsv.jpg');
imwrite(img_ycbcr, './Data/bottlecaps_ycbcr.jpg');
imwrite(img_gray, './Data/bottlecaps_gray.jpg');
