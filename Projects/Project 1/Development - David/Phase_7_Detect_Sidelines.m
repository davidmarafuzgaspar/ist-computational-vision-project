% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 7 - Indirect Obstacle Detection
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

num_targets  = length(target_names);
img_indices  = zeros(num_targets, 1);
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

    img_indices(t)    = img_idx;
    pts_left_all{t}   = gt(gt_idx).left;
    pts_right_all{t}  = gt(gt_idx).right;
    imgs{t}           = images{img_idx};
    [h, w, ~]         = size(images{img_idx});
    img_sizes(t, :)   = [h, w];

    fprintf('[%d] %s | img_idx=%d | L=%d pts | R=%d pts\n', ...
        t, target_name, img_idx, ...
        size(pts_left_all{t},  1), ...
        size(pts_right_all{t}, 1));
end

%% ----------------------------------------------------------
%  SECTION 2: POLYNOMIAL FIT + REGION SPLIT + SLIC + EULER
% -----------------------------------------------------------

poly_degree    = 2;
num_superpixels = 100;
k_clusters     = 3;
se_region      = strel('square', 30);

euler_results    = zeros(num_targets, 3);
indirect_flags   = false(num_targets, 1);
surrounding_all  = cell(num_targets, 1);
regions_all      = cell(num_targets, 3);  % {t, 1/2/3} = left/mid/right refined

for t = 1:num_targets

    if img_indices(t) == 0[sp_labels, num_sp] = superpixels(img_lab, num_superpixels, ...
        'Compactness', 20, 'IsInputLab', true);
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

    % --- Polynomial fit to curved rails ---
    p_left  = polyfit(pts_left(:,2),  pts_left(:,1),  poly_degree);
    p_right = polyfit(pts_right(:,2), pts_right(:,1), poly_degree);

    y_range     = (1:h)';
    x_left_fit  = polyval(p_left,  y_range);
    x_right_fit = polyval(p_right, y_range);

    % --- Region split using polynomial boundaries ---
    [X, Y]        = meshgrid(1:w, 1:h);
    x_left_map    = polyval(p_left,  Y);
    x_right_map   = polyval(p_right, Y);

    left_region   = (X < x_left_map)  & roi_mask;
    right_region  = (X > x_right_map) & roi_mask;
    middle_region = (X >= x_left_map) & (X <= x_right_map) & roi_mask;

    % --- SLIC + k-means ---
    img_roi = img;
    img_roi(repmat(~roi_mask, [1 1 3])) = 0;
    img_lab = rgb2lab(img_roi);

    [sp_labels, num_sp] = superpixels(img_lab, num_superpixels, ...
        'Compactness', 10, 'IsInputLab', true);

    sp_features = zeros(num_sp, 3);
    for c = 1:3
        channel = img_lab(:,:,c);
        for s = 1:num_sp
            px = channel(sp_labels == s);
            sp_features(s, c) = mean(px);
        end
    end

    cluster_idx = kmeans(sp_features, k_clusters, 'Replicates', 5);

    cluster_img = zeros(h, w);
    for s = 1:num_sp
        cluster_img(sp_labels == s) = cluster_idx(s);
    end

    cluster_counts = zeros(k_clusters, 1);
    for c = 1:k_clusters
        cluster_counts(c) = sum(cluster_img(roi_mask) == c);
    end

    [~, sorted_idx]    = sort(cluster_counts, 'descend');
    surrounding_binary = (cluster_img == sorted_idx(2)) & roi_mask;
    surrounding_all{t} = surrounding_binary;

    % --- Apply region masks to surrounding binary ---
    surr_left   = surrounding_binary & left_region;
    surr_middle = surrounding_binary & middle_region;
    surr_right  = surrounding_binary & right_region;

    % --- Closing + opening per region ---
    surr_left_ref   = imopen(imclose(surr_left,   se_region), se_region);
    surr_middle_ref = imopen(imclose(surr_middle, se_region), se_region);
    surr_right_ref  = imopen(imclose(surr_right,  se_region), se_region);

    regions_all{t, 1} = surr_left_ref;
    regions_all{t, 2} = surr_middle_ref;
    regions_all{t, 3} = surr_right_ref;

    % --- Euler number + decision ---
    e_left   = bweuler(surr_left_ref);
    e_mid    = bweuler(surr_middle_ref);
    e_right  = bweuler(surr_right_ref);

    euler_results(t, :)  = [e_left, e_mid, e_right];
    indirect_flags(t)    = (e_left ~= 1) || (e_mid ~= 1) || (e_right ~= 1);

    fprintf('  Euler: L=%d  M=%d  R=%d  →  %s\n', ...
        e_left, e_mid, e_right, ...
        decision_str(indirect_flags(t)));
end

%% ----------------------------------------------------------
%  SECTION 3: DISPLAY RESULTS
% -----------------------------------------------------------

cols = 5;
rows = ceil(num_targets / cols);

% --- Figure: Rail polynomial fit verification ---
figure('Name', 'Figure 21 - Rail Polynomial Fits', ...
    'NumberTitle', 'off', 'Position', [0, 0, 1500, rows*250]);

for t = 1:num_targets
    if img_indices(t) == 0; continue; end

    h = img_sizes(t, 1);
    p_left  = polyfit(pts_left_all{t}(:,2),  pts_left_all{t}(:,1),  poly_degree);
    p_right = polyfit(pts_right_all{t}(:,2), pts_right_all{t}(:,1), poly_degree);
    y_range = (1:h)';

    subplot(rows, cols, t);
    imshow(imgs{t}); hold on;
    plot(pts_left_all{t}(:,1),  pts_left_all{t}(:,2),  'r.', 'MarkerSize', 12);
    plot(pts_right_all{t}(:,1), pts_right_all{t}(:,2), 'g.', 'MarkerSize', 12);
    plot(polyval(p_left,  y_range), y_range, 'r-', 'LineWidth', 1.5);
    plot(polyval(p_right, y_range), y_range, 'g-', 'LineWidth', 1.5);
    title(sprintf('[%d] %s', t, target_names{t}), ...
        'FontSize', 7, 'Interpreter', 'none');
    hold off;
end
sgtitle('Figure 21 — Rail Polynomial Fit Verification', ...
    'FontSize', 12, 'FontWeight', 'bold');

% --- Figure: Surrounding binary (SLIC + k-means) ---
figure('Name', 'Figure 22 - Surrounding Binary', ...
    'NumberTitle', 'off', 'Position', [0, 0, 1500, rows*250]);

for t = 1:num_targets
    if img_indices(t) == 0; continue; end
    subplot(rows, cols, t);
    imshow(surrounding_all{t});
    title(sprintf('[%d] %s', t, target_names{t}), ...
        'FontSize', 7, 'Interpreter', 'none');
end
sgtitle('Figure 22 — Surrounding Binary (SLIC + k-means)', ...
    'FontSize', 12, 'FontWeight', 'bold');

% --- Figure: Refined regions overlay ---
figure('Name', 'Figure 23 - Refined Regions', ...
    'NumberTitle', 'off', 'Position', [0, 0, 1500, rows*250]);

for t = 1:num_targets
    if img_indices(t) == 0; continue; end
    h = img_sizes(t, 1);
    w = img_sizes(t, 2);

    overlay = zeros(h, w, 3);
    overlay(:,:,1) = double(regions_all{t, 1});  % left  — red
    overlay(:,:,2) = double(regions_all{t, 2});  % middle — green
    overlay(:,:,3) = double(regions_all{t, 3});  % right  — blue

    subplot(rows, cols, t);
    imshow(overlay);
    title(sprintf('[%d] %s', t, target_names{t}), ...
        'FontSize', 7, 'Interpreter', 'none');
end
sgtitle('Figure 23 — Refined Regions: Left=red  Middle=green  Right=blue', ...
    'FontSize', 12, 'FontWeight', 'bold');

% --- Figure: Final detection decision ---
figure('Name', 'Figure 24 - Indirect Obstacle Detection Results', ...
    'NumberTitle', 'off', 'Position', [0, 0, 1500, rows*250]);

for t = 1:num_targets
    if img_indices(t) == 0; continue; end

    subplot(rows, cols, t);
    imshow(imgs{t}); hold on;

    h = img_sizes(t, 1);
    p_left  = polyfit(pts_left_all{t}(:,2),  pts_left_all{t}(:,1),  poly_degree);
    p_right = polyfit(pts_right_all{t}(:,2), pts_right_all{t}(:,1), poly_degree);
    y_range = (1:h)';
    plot(polyval(p_left,  y_range), y_range, 'y-', 'LineWidth', 1.5);
    plot(polyval(p_right, y_range), y_range, 'y-', 'LineWidth', 1.5);

    if indirect_flags(t)
        dec_col = [1 0 0];
        dec_str = 'INDIRECT OBSTACLE';
    else
        dec_col = [0 0.8 0];
        dec_str = 'CLEAR';
    end

    title(sprintf('[%d] E=[%d,%d,%d]\n%s', t, ...
        euler_results(t,1), euler_results(t,2), euler_results(t,3), dec_str), ...
        'FontSize', 7, 'Color', dec_col);
    hold off;
end
sgtitle('Figure 24 — Indirect Obstacle Detection Results', ...
    'FontSize', 12, 'FontWeight', 'bold');

%% ----------------------------------------------------------
%  SECTION 4: SUMMARY TABLE
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