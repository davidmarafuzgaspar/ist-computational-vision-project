% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Instituto Superior Tecnico 
% Computational Vision - Lab 3
% 
% Authors:
% David Marafuz Gaspar - 106541
% Pedro Gaspar Mónico - 106626
%
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

%% Task 1

% 1. Load the image and convert to Double (as required by the task)
img_uint8 = imread('./Data/cells.png');
img = im2double(img_uint8); % Converts range [0, 255] to [0.0, 1.0]

% A. Brightness Adjustment (Adding a constant)
brightness_offset = 0.2; 
img_brightness = img + brightness_offset;
img_brightness = min(max(img_brightness, 0), 1); % Clipping to [0, 1] range

% B. Contrast Adjustment (Multiplying by a gain)
contrast_gain = 1.5;
img_contrast = img * contrast_gain;
img_contrast = min(max(img_contrast, 0), 1); % Clipping

% C. Gamma Correction (Power Law)
gamma_val = 0.5; % Values < 1 brighten shadows, > 1 darken them
img_gamma = img .^ gamma_val;

% D. Histogram Equalization
% Equivalent to the Simulink "Histogram Equalization" block
img_eq = histeq(img);

figure('Name', 'Point Processing Comparison', 'NumberTitle', 'off');

% Original
subplot(2,5,1); imshow(img); title('Original');
subplot(2,5,6); imhist(img); title('Original Hist');

% Brightness
subplot(2,5,2); imshow(img_brightness); title('Brightness (+0.2)');
subplot(2,5,7); imhist(img_brightness); title('Shifted Hist');

% Contrast
subplot(2,5,3); imshow(img_contrast); title('Contrast (x1.5)');
subplot(2,5,8); imhist(img_contrast); title('Stretched Hist');

% Gamma
subplot(2,5,4); imshow(img_gamma); title(['Gamma (\gamma=' num2str(gamma_val) ')']);
subplot(2,5,9); imhist(img_gamma); title('Non-linear Shift');

% Equalization
subplot(2,5,5); imshow(img_eq); title('Equalized');
subplot(2,5,10); imhist(img_eq); title('Flat/Uniform Hist');