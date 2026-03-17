% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 7 - Indirect Obstacle Detection (p8.jpg test)
%
%  Authors:
%   - David Marafuz Gaspar - 106541
%   - Pedro Gaspar Mónico - 106626
%
% ============================================================
clear; clc; close all;
load('./Output/workspace_phase6.mat');
load('./Output/ground_truth.mat');

%% ----------------------------------------------------------
%  SECTION 1: LOAD p8.jpg AND EXTRACT GROUND TRUTH
% -----------------------------------------------------------

% Find p8.jpg index in filenames
target_name = 'p8.jpg';
img_idx = [];
for i = 1:N
    [~, name, ext] = fileparts(filenames{i});
    if strcmp([name ext], target_name)
        img_idx = i;
        break;
    end
end
fprintf('p8.jpg found at index %d\n', img_idx);

% Find ground truth entry for p8.jpg
gt_idx = [];
for j = 1:length(gt)
    if strcmp(gt(j).filename, target_name)
        gt_idx = j;
        break;
    end
end

% Extract ground truth rail points
pts_left  = gt(gt_idx).left;   % Nx2: [x, y]
pts_right = gt(gt_idx).right;  % Nx2: [x, y]

fprintf('Left rail:  %d points\n', size(pts_left,  1));
fprintf('Right rail: %d points\n', size(pts_right, 1));

img     = images{img_idx};
[h, w, ~] = size(img);

%% ----------------------------------------------------------
%  SECTION 2: FIT POLYNOMIAL TO CURVED RAIL GROUND TRUTH
% -----------------------------------------------------------

% Since the rails are curved, a 2nd degree polynomial is fitted
% (y as a function of x) to better capture the curvature
poly_degree = 2;

% Left rail: fit x = f(y) since rails run mostly vertically
p_left  = polyfit(pts_left(:,2),  pts_left(:,1),  poly_degree);
p_right = polyfit(pts_right(:,2), pts_right(:,1), poly_degree);

% Evaluate fitted curves over full image height
y_range   = (1:h)';
x_left    = polyval(p_left,  y_range);
x_right   = polyval(p_right, y_range);

% --- Figure: Rail fit verification ---
figure('Name', 'Figure 21 - Rail Polynomial Fit on p8.jpg', ...
    'NumberTitle', 'off', 'Position', [0, 0, 800, 600]);

imshow(img); hold on;
plot(pts_left(:,1),  pts_left(:,2),  'r.', 'MarkerSize', 15);
plot(pts_right(:,1), pts_right(:,2), 'g.', 'MarkerSize', 15);
plot(x_left,  y_range, 'r-', 'LineWidth', 2);
plot(x_right, y_range, 'g-', 'LineWidth', 2);
legend('GT Left pts', 'GT Right pts', 'Fitted Left', 'Fitted Right', ...
    'Location', 'northwest');
title('Figure 21 — Polynomial Rail Fit on p8.jpg', 'FontSize', 11);
hold off;

%% ----------------------------------------------------------
%  SECTION 3: SPLIT SURROUNDING BINARY INTO 3 REGIONS
% -----------------------------------------------------------

% Build pixel coordinate grids
[X, Y] = meshgrid(1:w, 1:h);

% For each pixel, evaluate the fitted polynomial at that row (y)
% to get the x-boundary of each rail line
x_left_map  = polyval(p_left,  Y);
x_right_map = polyval(p_right, Y);

% Left region:   pixel x < left rail boundary
% Right region:  pixel x > right rail boundary
% Middle region: between both rail lines
roi_mask = masks{img_idx};

left_region   = (X < x_left_map)  & roi_mask;
right_region  = (X > x_right_map) & roi_mask;
middle_region = (X >= x_left_map) & (X <= x_right_map) & roi_mask;

% --- Figure: Region Split ---
figure('Name', 'Figure 22 - Region Split on p8.jpg', ...
    'NumberTitle', 'off', 'Position', [0, 0, 800, 600]);

region_overlay = zeros(h, w, 3);
region_overlay(:,:,1) = double(left_region);    % red
region_overlay(:,:,2) = double(middle_region);  % green
region_overlay(:,:,3) = double(right_region);   % blue

imshow(region_overlay);
title('Figure 22 — Region Split: Left=red  Middle=green  Right=blue', ...
    'FontSize', 11);

%% ----------------------------------------------------------
%  SECTION 4: SLIC + K-MEANS ON ROI
% -----------------------------------------------------------

% Apply ROI mask to original RGB image
img_roi = img;
img_roi(repmat(~roi_mask, [1 1 3])) = 0;

% Convert to L*a*b* for perceptually uniform clustering
img_lab = rgb2lab(img_roi);

% SLIC superpixel oversegmentation
num_superpixels = 400;
[sp_labels, num_sp] = superpixels(img_lab, num_superpixels, ...
    'Compactness', 20, 'IsInputLab', true);

% Compute mean L*a*b* per superpixel
sp_features = zeros(num_sp, 3);
for c = 1:3
    channel = img_lab(:,:,c);
    for s = 1:num_sp
        px = channel(sp_labels == s);
        sp_features(s, c) = mean(px);
    end
end

% K-means clustering k=3
k_clusters  = 3;
cluster_idx = kmeans(sp_features, k_clusters, 'Replicates', 5);

% Build pixel-level cluster image
cluster_img = zeros(h, w);
for s = 1:num_sp
    cluster_img(sp_labels == s) = cluster_idx(s);
end

% Count pixels per cluster within ROI only
cluster_counts = zeros(k_clusters, 1);
for c = 1:k_clusters
    cluster_counts(c) = sum(cluster_img(roi_mask) == c);
end

% Background = highest count, surrounding = second highest count
[~, sorted_idx]     = sort(cluster_counts, 'descend');
surrounding_cluster = sorted_idx(2);
surrounding_binary  = (cluster_img == surrounding_cluster) & roi_mask;

% --- Figure: SLIC + k-means result ---
figure('Name', 'Figure 23 - SLIC K-means Surrounding Region', ...
    'NumberTitle', 'off', 'Position', [0, 0, 1200, 500]);

subplot(1, 3, 1);
imshow(img_roi);
title('ROI Image', 'FontSize', 10);

subplot(1, 3, 2);
% Show superpixel boundaries
sp_boundary = boundarymask(sp_labels);
imshow(imoverlay(img_roi, sp_boundary, 'cyan'));
title(sprintf('SLIC Superpixels (N=%d)', num_superpixels), 'FontSize', 10);

subplot(1, 3, 3);
imshow(surrounding_binary);
title('Surrounding Binary (2nd highest cluster)', 'FontSize', 10);

sgtitle('Figure 23 — SLIC + K-means on p8.jpg', 'FontSize', 12, ...
    'FontWeight', 'bold');

%% ----------------------------------------------------------
%  SECTION 5: APPLY REGIONS MASK TO SURROUNDING BINARY
% -----------------------------------------------------------

surr_left   = surrounding_binary & left_region;
surr_middle = surrounding_binary & middle_region;
surr_right  = surrounding_binary & right_region;

%% ----------------------------------------------------------
%  SECTION 6: CLOSING + OPENING PER REGION
% -----------------------------------------------------------

se_region = strel('square', 10);

surr_left_ref   = imopen(imclose(surr_left,   se_region), se_region);
surr_middle_ref = imopen(imclose(surr_middle, se_region), se_region);
surr_right_ref  = imopen(imclose(surr_right,  se_region), se_region);

% --- Figure: Refined regions ---
figure('Name', 'Figure 24 - Refined Regions p8.jpg', ...
    'NumberTitle', 'off', 'Position', [0, 0, 1200, 400]);

subplot(1, 3, 1);
imshow(surr_left_ref);
title('Left Region (refined)', 'FontSize', 10);

subplot(1, 3, 2);
imshow(surr_middle_ref);
title('Middle Region (refined)', 'FontSize', 10);

subplot(1, 3, 3);
imshow(surr_right_ref);
title('Right Region (refined)', 'FontSize', 10);

sgtitle('Figure 24 — Refined Surrounding Regions on p8.jpg', ...
    'FontSize', 12, 'FontWeight', 'bold');

%% ----------------------------------------------------------
%  SECTION 7: EULER NUMBER + DECISION
% -----------------------------------------------------------

e_left   = bweuler(surr_left_ref);
e_middle = bweuler(surr_middle_ref);
e_right  = bweuler(surr_right_ref);

indirect_detected = (e_left ~= 1) || (e_middle ~= 1) || (e_right ~= 1);

fprintf('\n--- Indirect Obstacle Detection: p8.jpg ---\n');
fprintf('Euler Left:   %d\n', e_left);
fprintf('Euler Middle: %d\n', e_middle);
fprintf('Euler Right:  %d\n', e_right);
fprintf('Decision:     %s\n\n', ...
    string(indirect_detected) + " — " + ...
    ternary_str(indirect_detected, 'INDIRECT OBSTACLE DETECTED', 'CLEAR'));

% --- Figure: Final annotated result ---
figure('Name', 'Figure 25 - Final Detection Result p8.jpg', ...
    'NumberTitle', 'off', 'Position', [0, 0, 900, 600]);

imshow(img); hold on;

% Draw fitted rail lines
plot(x_left,  y_range, 'y-',  'LineWidth', 2);
plot(x_right, y_range, 'y-',  'LineWidth', 2);

if indirect_detected
    dec_str = 'INDIRECT OBSTACLE DETECTED';
    dec_col = 'red';
else
    dec_str = 'CLEAR';
    dec_col = 'green';
end

title(sprintf('Figure 25 — p8.jpg | E=[%d,%d,%d] | %s', ...
    e_left, e_middle, e_right, dec_str), ...
    'FontSize', 11, 'Color', dec_col);
hold off;

%% ----------------------------------------------------------
%  HELPER FUNCTION
% -----------------------------------------------------------
function s = ternary_str(cond, a, b)
    if cond; s = a; else; s = b; end
end