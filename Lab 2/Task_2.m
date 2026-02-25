% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Instituto Superior Tecnico 
% Computational Vision - Lab 1
% 
% Authors:
% David Marafuz Gaspar - 106541
% Pedro Gaspar Mónico - 106626
%
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

%% Task 2

% Load images
img_gn = imread('./Data/car_gaussian.jpg');
img_sp = imread('./Data/car_sp.jpg');
img_sk = imread('./Data/car_speckle.jpg');

% Define Filter Parameters
mask_size = [5 5];  
gauss_sigma = 1.0;

% Apply Filters to Gaussian Noise
denoise_gn_avg  = imfilter(img_gn, fspecial('average', mask_size));
denoise_gn_gaus = imgaussfilt(img_gn, gauss_sigma);
denoise_gn_med  = medfilt2(img_gn, mask_size);

% Apply Filters to Salt & Pepper Noise
denoise_sp_avg  = imfilter(img_sp, fspecial('average', mask_size));
denoise_sp_gaus = imgaussfilt(img_sp, gauss_sigma);
denoise_sp_med  = medfilt2(img_sp, mask_size);

% Apply Filters to Speckle Noise
denoise_sk_avg  = imfilter(img_sk, fspecial('average', mask_size));
denoise_sk_gaus = imgaussfilt(img_sk, gauss_sigma);
denoise_sk_med  = medfilt2(img_sk, mask_size);

% Visualization: The Gaussian Case
figure('Name', 'Filter Comparison: Gaussian Noise');
subplot(2,2,1); imshow(img_gn); title('Noisy (Gaussian)');
subplot(2,2,2); imshow(denoise_gn_avg); title('Averaging Filter');
subplot(2,2,3); imshow(denoise_gn_gaus); title('Gaussian Filter');
subplot(2,2,4); imshow(denoise_gn_med); title('Median Filter');

% Visualization: The Salt & Pepper Case 
figure('Name', 'Filter Comparison: Salt & Pepper Noise');
subplot(2,2,1); imshow(img_sp); title('Noisy (S&P)');
subplot(2,2,2); imshow(denoise_sp_avg); title('Averaging Filter');
subplot(2,2,3); imshow(denoise_sp_gaus); title('Gaussian Filter');
subplot(2,2,4); imshow(denoise_sp_med); title('Median Filter');

% Visualization: The Speckel Noise 
figure('Name', 'Filter Comparison: Salt & Pepper Noise');
subplot(2,2,1); imshow(img_sk); title('Noisy (Speckel)');
subplot(2,2,2); imshow(denoise_sk_avg); title('Averaging Filter');
subplot(2,2,3); imshow(denoise_sk_gaus); title('Gaussian Filter');
subplot(2,2,4); imshow(denoise_sk_med); title('Median Filter');
