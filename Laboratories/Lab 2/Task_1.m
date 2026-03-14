% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Instituto Superior Tecnico 
% Computational Vision - Lab 2
% 
% Authors:
% David Marafuz Gaspar - 106541
% Pedro Gaspar Mónico - 106626
%
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

%% Task 1

% Load the car image
img_rgb = imread('./Data/car.jpg');
img_gray = rgb2gray(img_rgb);

% Define Noise Intensity
intensity = 0.1; 

% Apply Gaussian Noise
img_gaussian = imnoise(img_gray, 'gaussian', 0, intensity);

% Apply Salt & Pepper Noise
img_sp = imnoise(img_gray, 'salt & pepper', intensity);

% Apply Speckle Noise
img_speckle = imnoise(img_gray, 'speckle', intensity);

% Plot results for comparison
figure('Name', 'Task 2.1: Noise Types Comparison');

subplot(2,2,1); imshow(img_gray);
title('Original Grayscale');

subplot(2,2,2); imshow(img_gaussian);
title(['Gaussian Noise (var=', num2str(intensity), ')']);

subplot(2,2,3); imshow(img_sp);
title(['Salt & Pepper (dens=', num2str(intensity), ')']);

subplot(2,2,4); imshow(img_speckle);
title(['Speckle Noise (var=', num2str(intensity), ')']);

% Save output
imwrite(img_gray, './Data/car_gray.jpg');
imwrite(img_gaussian, './Data/car_gaussian.jpg');
imwrite(img_sp, './Data/car_sp.jpg');
imwrite(img_speckle, './Data/car_speckle.jpg');