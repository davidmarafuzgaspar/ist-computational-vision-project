%% Task 1 - Extraction of Region Properties
% Load, binarize, and extract region properties from geometrical shape images

%% Step 1: Load an image from the dataset
img = imread('./Data/datasetImages/rho_build(1).jpg');  % Replace with your actual image filename

%% Step 2: Convert to grayscale if the image is RGB
if size(img, 3) == 3
    img_gray = rgb2gray(img);
else
    img_gray = img;
end

%% Step 3: Binarize the image using thresholding
% Ensures a true binary image
threshold = graythresh(img_gray);          % Otsu's method to compute threshold
img_binary = imbinarize(img_gray, threshold);

%% Step 4: Complement the binary image
% Convention: white pixels = shape of interest (foreground)
img_comp = imcomplement(img_binary);

figure;
subplot(1,3,1); imshow(img_gray);  title('Grayscale Image');
subplot(1,3,2); imshow(img_binary); title('Binarized Image');
subplot(1,3,3); imshow(img_comp);   title('Complemented Image');

%% Step 5: Extract region properties using regionprops
% Extract key geometric descriptors
stats = regionprops(img_comp, ...
    'Area', ...          % Number of pixels in the region
    'Centroid', ...      % [x, y] coordinates of the centroid
    'BoundingBox', ...   % Smallest rectangle enclosing the region [x y w h]
    'Solidity');        % Area / ConvexArea (compactness measure)

%% Step 6: Select the largest region (the shape itself)
if numel(stats) > 1
    areas = [stats.Area];
    [~, idx] = max(areas);
    stats = stats(idx);
end

%% Step 7: Display results 
figure;
imshow(img_comp); hold on;
title('Region Properties: Shape Analysis');

% Draw bounding box
bb = stats.BoundingBox;
rectangle('Position', bb, 'EdgeColor', 'r', 'LineWidth', 2);

% Mark centroid
cx = stats.Centroid(1);
cy = stats.Centroid(2);
plot(cx, cy, 'g+', 'MarkerSize', 15, 'LineWidth', 2);

% Annotate with area
text(bb(1), bb(2) - 10, ...
    sprintf('Area: %.0f px', stats.Area), ...
    'Color', 'yellow', 'FontSize', 12, 'FontWeight', 'bold');

text(bb(1), bb(2) - 25, ...
    sprintf('Centroid: (%.1f, %.1f)', cx, cy), ...
    'Color', 'cyan', 'FontSize', 10);

hold off;

%% Step 8: Print all extracted properties to the console
fprintf('Region Properties\n');
fprintf('Area            : %.0f pixels\n',    stats.Area);
fprintf('Centroid        : (%.2f, %.2f)\n',   stats.Centroid(1), stats.Centroid(2));
fprintf('Solidity        : %.4f\n',           stats.Solidity);

%% Step 9: Loop over multiple images in the dataset (optional)
% Useful to batch-process all shapes in your dataset folder

image_files = dir('*.png');  % Adjust extension as needed

for i = 1:length(image_files)
    img_i = imread(image_files(i).name);
    
    if size(img_i, 3) == 3
        img_i = rgb2gray(img_i);
    end
    
    thr   = graythresh(img_i);
    bin_i = imbinarize(img_i, thr);
    cmp_i = imcomplement(bin_i);
    
    s = regionprops(cmp_i, 'Area', 'Centroid', 'BoundingBox', 'Solidity');
    
    if isempty(s), continue; end
    
    % Keep largest region
    [~, idx] = max([s.Area]);
    s = s(idx);
    
    fprintf('\nImage: %s\n', image_files(i).name);
    fprintf('  Area         = %.0f px\n', s.Area);
    fprintf('  Centroid     = (%.1f, %.1f)\n', s.Centroid(1), s.Centroid(2));
    fprintf('  Eccentricity = %.4f\n', s.Eccentricity);
    fprintf('  Solidity     = %.4f\n', s.Solidity);
end