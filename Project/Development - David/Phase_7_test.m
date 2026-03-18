% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 7 - Indirect Obstacle Detection (Per-Region)
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
%  SECTION 1: SELECT IMAGES AND EXTRACT GROUND TRUTH
% -----------------------------------------------------------

target_names = {'Frame1253.jpg', 'Frame1291.jpg', 'Frame1532.jpg', 'Frame1603.jpg', 'image00756.jpg', 'image02293.jpg', 'image06026.jpg', 'p8.jpg'};  % <-- update as needed

num_targets   = length(target_names);
img_indices   = zeros(num_targets, 1);
pts_left_all  = cell(num_targets, 1);
pts_right_all = cell(num_targets, 1);
imgs          = cell(num_targets, 1);
img_sizes     = zeros(num_targets, 2);

for t = 1:num_targets
    target_name = target_names{t};

    img_idx = [];
    for i = 1:N
        [~, name, ext] = fileparts(filenames{i});
        if strcmp([name ext], target_name)
            img_idx = i;
            break;
        end
    end

    gt_idx = [];
    for j = 1:length(gt)
        if strcmp(gt(j).filename, target_name)
            gt_idx = j;
            break;
        end
    end

    if isempty(img_idx) || isempty(gt_idx)
        warning('Skipping %s — image or ground truth not found.', target_name);
        continue;
    end

    img_indices(t)   = img_idx;
    pts_left_all{t}  = gt(gt_idx).left;
    pts_right_all{t} = gt(gt_idx).right;
    imgs{t}          = images{img_idx};
    [h, w, ~]        = size(images{img_idx});
    img_sizes(t, :)  = [h, w];

    fprintf('[%d] %s | img_idx=%d | L=%d pts | R=%d pts\n', ...
        t, target_name, img_idx, ...
        size(pts_left_all{t},  1), ...
        size(pts_right_all{t}, 1));
end

%% ----------------------------------------------------------
%  SECTION 2: PARAMETERS
% -----------------------------------------------------------

poly_degree     = 2;
num_superpixels = 50;
k_clusters      = 3;
se_region       = strel('square', 20);

% Minimum number of ROI pixels required in a region to attempt
% SLIC + k-means — regions smaller than this fall back to Otsu
min_pixels_for_slic = 500;

%% ----------------------------------------------------------
%  SECTION 3: MAIN PROCESSING LOOP
% -----------------------------------------------------------

euler_results   = zeros(num_targets, 3);
indirect_flags  = false(num_targets, 1);
regions_all     = cell(num_targets, 3);
surr_all        = cell(num_targets, 3);

% Gaussian filter sigma for smoothing before SLIC
gauss_sigma = 1;

for t = 1:num_targets

    if img_indices(t) == 0
        continue;
    end

    img      = imgs{t};
    h        = img_sizes(t, 1);
    w        = img_sizes(t, 2);
    i        = img_indices(t);
    roi_mask = masks{i};

    pts_left  = pts_left_all{t};
    pts_right = pts_right_all{t};

    fprintf('\nProcessing [%d/%d]: %s\n', t, num_targets, target_names{t});

    % --- Polynomial fit to curved rails (x as function of y) ---
    p_left  = polyfit(pts_left(:,2),  pts_left(:,1),  poly_degree);
    p_right = polyfit(pts_right(:,2), pts_right(:,1), poly_degree);

    % --- Build pixel-wise region masks ---
    [X, Y]      = meshgrid(1:w, 1:h);
    x_left_map  = polyval(p_left,  Y);
    x_right_map = polyval(p_right, Y);

    left_region   = (X < x_left_map)  & roi_mask;
    right_region  = (X > x_right_map) & roi_mask;
    middle_region = (X >= x_left_map) & (X <= x_right_map) & roi_mask;

    region_masks = {left_region, middle_region, right_region};
    region_names = {'Left', 'Middle', 'Right'};

    % --- Per-region SLIC + k-means binarization ---
    for r = 1:3
        reg_mask = region_masks{r};

        % Isolate the RGB image to this region only
        img_region = img;
        img_region(repmat(~reg_mask, [1 1 3])) = 0;

        % Apply Gaussian filter per channel to suppress high-frequency
        % texture noise before superpixel clustering — prevents fine
        % surface detail (ballast gravel, rock texture) from creating
        % spurious superpixel boundaries
        img_region_smooth = zeros(size(img_region), 'like', img_region);
        for c = 1:3
            img_region_smooth(:,:,c) = imgaussfilt( ...
                double(img_region(:,:,c)), gauss_sigma);
        end
        img_region_smooth = uint8(img_region_smooth);

        % Check if region has enough pixels for SLIC
        num_pixels = sum(reg_mask(:));

        if num_pixels >= min_pixels_for_slic
            % --- SLIC + k-means path ---
            img_lab = rgb2lab(img_region_smooth);

            % Scale superpixel count proportionally to region size
            n_sp = max(10, round(num_superpixels * num_pixels / (h * w)));

            [sp_labels, num_sp] = superpixels(img_lab, n_sp, ...
                'Compactness', 20, 'IsInputLab', true);

            % Compute mean L*a*b* per superpixel (only within region)
            sp_features = zeros(num_sp, 3);
            for c = 1:3
                channel = img_lab(:,:,c);
                for s = 1:num_sp
                    px = channel(sp_labels == s & reg_mask);
                    if isempty(px)
                        sp_features(s, c) = 0;
                    else
                        sp_features(s, c) = mean(px);
                    end
                end
            end

            % K-means clustering within this region
            cluster_idx = kmeans(sp_features, k_clusters, 'Replicates', 5);

            % Build pixel-level cluster image
            cluster_img = zeros(h, w);
            for s = 1:num_sp
                cluster_img(sp_labels == s) = cluster_idx(s);
            end

            % Count pixels per cluster within this region only
            cluster_counts = zeros(k_clusters, 1);
            for c = 1:k_clusters
                cluster_counts(c) = sum(cluster_img(reg_mask) == c);
            end

            % Background = highest count, surrounding = second highest
            [~, sorted_idx] = sort(cluster_counts, 'descend');
            surrounding_bin = (cluster_img == sorted_idx(2)) & reg_mask;

        else
            % --- Fallback: Otsu thresholding on smoothed grayscale ---
            fprintf('  [%s] too small for SLIC (%d px) — using Otsu\n', ...
                region_names{r}, num_pixels);

            gray_region     = rgb2gray(img_region_smooth);
            thresh          = graythresh(gray_region);
            surrounding_bin = imbinarize(gray_region, thresh) & reg_mask;
        end

        surr_all{t, r} = surrounding_bin;

        % Closing then opening to refine the binary region
        regions_all{t, r} = imopen(imclose(surrounding_bin, se_region), se_region);
    end

    % --- Euler number per region ---
    e_left   = bweuler(regions_all{t, 1});
    e_mid    = bweuler(regions_all{t, 2});
    e_right  = bweuler(regions_all{t, 3});

    euler_results(t, :) = [e_left, e_mid, e_right];
    indirect_flags(t)   = (e_left ~= 1) || (e_mid ~= 1) || (e_right ~= 1);

    fprintf('  Euler: L=%d  M=%d  R=%d  →  %s\n', ...
        e_left, e_mid, e_right, decision_str(indirect_flags(t)));
end

%% ----------------------------------------------------------
%  SECTION 4: DISPLAY RESULTS
% -----------------------------------------------------------

cols = min(num_targets, 5);
rows = ceil(num_targets / cols);

% --- Figure: Rail polynomial fit verification ---
figure('Name', 'Figure 21 - Rail Polynomial Fits', ...
    'NumberTitle', 'off', 'Position', [0, 0, 1500, rows*300]);

for t = 1:num_targets
    if img_indices(t) == 0; continue; end

    h       = img_sizes(t, 1);
    y_range = (1:h)';
    p_left  = polyfit(pts_left_all{t}(:,2),  pts_left_all{t}(:,1),  poly_degree);
    p_right = polyfit(pts_right_all{t}(:,2), pts_right_all{t}(:,1), poly_degree);

    subplot(rows, cols, t);
    imshow(imgs{t}); hold on;
    plot(pts_left_all{t}(:,1),  pts_left_all{t}(:,2),  'r.', 'MarkerSize', 12);
    plot(pts_right_all{t}(:,1), pts_right_all{t}(:,2), 'g.', 'MarkerSize', 12);
    plot(polyval(p_left,  y_range), y_range, 'r-', 'LineWidth', 2);
    plot(polyval(p_right, y_range), y_range, 'g-', 'LineWidth', 2);
    title(sprintf('[%d] %s', t, target_names{t}), ...
        'FontSize', 7, 'Interpreter', 'none');
    hold off;
end
sgtitle('Figure 21 — Rail Polynomial Fit Verification', ...
    'FontSize', 12, 'FontWeight', 'bold');

% --- Figure: Per-region surrounding binary ---
figure('Name', 'Figure 22 - Per-Region Surrounding Binary', ...
    'NumberTitle', 'off', 'Position', [0, 0, 1500, rows*300]);

region_colors = {'Left (red)', 'Middle (green)', 'Right (blue)'};
for t = 1:num_targets
    if img_indices(t) == 0; continue; end

    h = img_sizes(t, 1);
    w = img_sizes(t, 2);

    overlay = zeros(h, w, 3);
    overlay(:,:,1) = double(surr_all{t, 1});
    overlay(:,:,2) = double(surr_all{t, 2});
    overlay(:,:,3) = double(surr_all{t, 3});

    subplot(rows, cols, t);
    imshow(overlay);
    title(sprintf('[%d] %s', t, target_names{t}), ...
        'FontSize', 7, 'Interpreter', 'none');
end
sgtitle('Figure 22 — Per-Region Surrounding Binary: Left=red  Middle=green  Right=blue', ...
    'FontSize', 12, 'FontWeight', 'bold');

% --- Figure: Refined regions overlay ---
figure('Name', 'Figure 23 - Refined Regions', ...
    'NumberTitle', 'off', 'Position', [0, 0, 1500, rows*300]);

for t = 1:num_targets
    if img_indices(t) == 0; continue; end

    h = img_sizes(t, 1);
    w = img_sizes(t, 2);

    overlay = zeros(h, w, 3);
    overlay(:,:,1) = double(regions_all{t, 1});
    overlay(:,:,2) = double(regions_all{t, 2});
    overlay(:,:,3) = double(regions_all{t, 3});

    subplot(rows, cols, t);
    imshow(overlay);
    title(sprintf('[%d] %s', t, target_names{t}), ...
        'FontSize', 7, 'Interpreter', 'none');
end
sgtitle('Figure 23 — Refined Regions (after closing+opening): Left=red  Middle=green  Right=blue', ...
    'FontSize', 12, 'FontWeight', 'bold');

% --- Figure: Final detection decision ---
figure('Name', 'Figure 24 - Indirect Obstacle Detection Results', ...
    'NumberTitle', 'off', 'Position', [0, 0, 1500, rows*300]);

for t = 1:num_targets
    if img_indices(t) == 0; continue; end

    h       = img_sizes(t, 1);
    y_range = (1:h)';
    p_left  = polyfit(pts_left_all{t}(:,2),  pts_left_all{t}(:,1),  poly_degree);
    p_right = polyfit(pts_right_all{t}(:,2), pts_right_all{t}(:,1), poly_degree);

    subplot(rows, cols, t);
    imshow(imgs{t}); hold on;
    plot(polyval(p_left,  y_range), y_range, 'y-', 'LineWidth', 2);
    plot(polyval(p_right, y_range), y_range, 'y-', 'LineWidth', 2);

    if indirect_flags(t)
        dec_col = [1 0 0];
    else
        dec_col = [0 0.8 0];
    end

    title(sprintf('[%d] E=[%d,%d,%d] | %s', t, ...
        euler_results(t,1), euler_results(t,2), euler_results(t,3), ...
        decision_str(indirect_flags(t))), ...
        'FontSize', 7, 'Color', dec_col);
    hold off;
end
sgtitle('Figure 24 — Indirect Obstacle Detection Results', ...
    'FontSize', 12, 'FontWeight', 'bold');

%% ----------------------------------------------------------
%  SECTION 5: SUMMARY TABLE
% -----------------------------------------------------------

fprintf('\n%-25s | E_left | E_mid | E_right | Decision\n', 'Image');
fprintf('%s\n', repmat('-', 1, 70));
for t = 1:num_targets
    if img_indices(t) == 0; continue; end
    fprintf('%-25s | %6d | %5d | %7d | %s\n', ...
        target_names{t}, ...
        euler_results(t,1), euler_results(t,2), euler_results(t,3), ...
        decision_str(indirect_flags(t)));
end

%% ----------------------------------------------------------
%  HELPER FUNCTION
% -----------------------------------------------------------
function s = decision_str(flag)
    if flag
        s = 'INDIRECT OBSTACLE DETECTED';
    else
        s = 'CLEAR';
    end
end