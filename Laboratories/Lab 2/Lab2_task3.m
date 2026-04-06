% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Instituto Superior Tecnico 
% Computational Vision - Lab 2 - Task 3
% 
% Authors:
% David Marafuz Gaspar - 106541
% Pedro Gaspar Mónico - 106626
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

% 1. Load the Noisy Images
img_gn = imread('./Data/car_gaussian.jpg');
img_sp = imread('./Data/car_sp.jpg');

% 2. Advanced Filtering for GAUSSIAN NOISE
% Wiener Filter: Adaptive filter that works best for Gaussian noise
% It looks at local variance to determine how much to filter.
denoise_gn_wiener = wiener2(img_gn, [5 5]);

% Bilateral Filter: Smooths noise while preserving sharp edges by 
% considering both spatial distance and color difference.
denoise_gn_bilat = imbilatfilt(img_gn);

% Non-Local Means (NLM): Searches for similar patches in the image 
% to average out noise. Very powerful for Gaussian grain.
denoise_gn_nlm = imnlmfilt(img_gn);

% 3. Advanced Filtering for SALT & PEPPER
% Mode Filter: Similar to median but picks the most frequent value.
% Note: Using medfilt2 with a larger mask is often the baseline here.
denoise_sp_med5 = medfilt2(img_sp, [5 5]); 

% Visualizatio of Advanced Gaussian Denoising
figure('Name', 'Advanced Filters: Gaussian Noise');
subplot(2,2,1); imshow(img_gn); title('Noisy (Gaussian)');
subplot(2,2,2); imshow(denoise_gn_wiener); title('Wiener Filter');
subplot(2,2,3); imshow(denoise_gn_bilat); title('Bilateral Filter');
subplot(2,2,4); imshow(denoise_gn_nlm); title('Non-Local Means');

%  Visualization of S&P Stress Test
figure('Name', 'Advanced Filters: Salt & Pepper');
subplot(1,2,1); imshow(img_sp); title('Noisy (S&P)');
subplot(1,2,2); imshow(denoise_sp_med5); title('Median [5x5] (Baseline)');
