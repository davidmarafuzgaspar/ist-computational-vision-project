% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Instituto Superior Tecnico 
% Computational Vision - Lab 3 - Task 2
% 
% Authors:  
% David Marafuz Gaspar - 106541
% Pedro Gaspar Mónico - 106626
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

% 1. Load the Image
img_data = imread('./Data/cells.png');

% Check if the image is RGB and convert to grayscale if necessary
if size(img_data, 3) == 3
    img_uint8 = rgb2gray(img_data);
else
    img_uint8 = img_data;
end

% Convert to double [0, 1] as per instructions
img = im2double(img_uint8); 

% 2. Manual Thresholding
manual_thresh_value = 0.25; 
img_manual = img > manual_thresh_value;

% 3. Automatic Thresholding (Otsu's Method)
auto_level = graythresh(img); 
img_auto = imbinarize(img, auto_level);

% 4. Visualization
figure('Name', 'Task 2: Binarization Results', 'NumberTitle', 'off');

% Original Image
subplot(1, 3, 1);
imshow(img);
title('Original Grayscale');

% Manual Result
subplot(1, 3, 2);
imshow(img_manual);
title(['Manual Threshold: ' num2str(manual_thresh_value)]);

% Automatic Result
subplot(1, 3, 3);
imshow(img_auto);
title(['Auto Threshold (Otsu): ' num2str(auto_level, 3)]);

fprintf('--- Binarization Results ---\n');
fprintf('Selected Manual Threshold: %.2f\n', manual_thresh_value);
fprintf('Calculated Automatic Threshold (Otsu): %.4f\n', auto_level);