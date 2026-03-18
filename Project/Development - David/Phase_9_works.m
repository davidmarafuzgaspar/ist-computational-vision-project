% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 7C - Anomaly Detection using Baseline Comparison
%
%  Authors:
%   - David Marafuz Gaspar - 106541
%   - Pedro Gaspar Mónico - 106626
%
% ============================================================
clear; clc; close all;
load('./Output/workspace_phase6.mat');
load('./Output/ground_truth.mat');
load('./Output/baseline_regions.mat');

%% ----------------------------------------------------------
%  SECTION 1: SELECT TARGET IMAGES
% -----------------------------------------------------------

target_names = {'Frame1253.jpg', 'Frame1291.jpg', 'Frame1532.jpg', ...
                'Frame1603.jpg', 'image00756.jpg', 'image02293.jpg', ...
                'image06026.jpg', 'p8.jpg'};

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
        warning('Skipping %s — not found.', target_name);
        continue;
    end

    img_indices(t)   = img_idx;
    pts_left_all{t}  = gt(gt_idx).left;
    pts_right_all{t} = gt(gt_idx).right;
    imgs{t}          = images{img_idx};
    [h, w, ~]        = size(images{img_idx});
    img_sizes(t, :)  = [h, w];

    fprintf('[%d] %s loaded\n', t, target_name);
end

%% ----------------------------------------------------------
%  SECTION 2: COMPUTE BASELINE STATISTICS PER REGION
% -----------------------------------------------------------

% For each region, pool all baseline pixels and compute
% mean and std in grayscale — this defines the expected
% appearance of a clear track in that region
num_baseline    = size(baseline_regions, 1);
baseline_stats  = struct();

for r = 1:3
    all_pixels = [];
    for b = 1:num_baseline
        reg_img    = baseline_regions{b, r};
        reg_gray   = double(rgb2gray(reg_img));

        % Only collect non-zero pixels (inside the masked region)
        nonzero_px = reg_gray(reg_gray > 0);
        all_pixels = [all_pixels; nonzero_px]; %#ok<AGROW>
    end

    baseline_stats(r).mean = mean(all_pixels);
    baseline_stats(r).std  = std(all_pixels);

    fprintf('[%s] baseline: mean=%.1f  std=%.1f  (%d pixels)\n', ...
        region_names{r}, baseline_stats(r).mean, ...
        baseline_stats(r).std, length(all_pixels));
end

%% ----------------------------------------------------------
%  SECTION 3: PARAMETERS
% -----------------------------------------------------------

poly_degree    = 2;
se_close       = strel('square', 10);
se_open        = strel('square', 10);

% Sigma threshold: pixels deviating more than this many
% standard deviations from the baseline mean are flagged
sigma_thresh   = 2.5;

% Anomaly ratio threshold: fraction of region pixels that
% must be anomalous to trigger an indirect obstacle flag
anomaly_thresh = 0.05;

%% ----------------------------------------------------------
%  SECTION 4: ANOMALY DETECTION LOOP
% -----------------------------------------------------------

anomaly_maps   = cell(num_targets, 3);
anomaly_ratios = zeros(num_targets, 3);
indirect_flags = false(num_targets, 1);
region_masks_all = cell(num_targets, 3);

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

    % --- Polynomial fit ---
    p_left  = polyfit(pts_left(:,2),  pts_left(:,1),  poly_degree);
    p_right = polyfit(pts_right(:,2), pts_right(:,1), poly_degree);

    % --- Region split ---
    [X, Y]      = meshgrid(1:w, 1:h);
    x_left_map  = polyval(p_left,  Y);
    x_right_map = polyval(p_right, Y);

    left_region   = (X < x_left_map)  & roi_mask;
    right_region  = (X > x_right_map) & roi_mask;
    middle_region = (X >= x_left_map) & (X <= x_right_map) & roi_mask;

    region_masks = {left_region, middle_region, right_region};

    % Store for display
    region_masks_all{t, 1} = left_region;
    region_masks_all{t, 2} = middle_region;
    region_masks_all{t, 3} = right_region;

    % Convert image to grayscale
    img_gray = double(rgb2gray(img));

    for r = 1:3
        reg_mask   = region_masks{r};
        num_pixels = sum(reg_mask(:));

        if num_pixels == 0
            anomaly_maps{t, r}   = false(h, w);
            anomaly_ratios(t, r) = 0;
            continue;
        end

        % --- Anomaly detection ---
        % Flag pixels whose intensity deviates from the baseline
        % mean by more than sigma_thresh standard deviations.
        % Both darker (rocks in shadow) and brighter (light rocks,
        % vegetation) anomalies are captured by using abs deviation.
        deviation    = abs(img_gray - baseline_stats(r).mean);
        anomaly_raw  = deviation > (sigma_thresh * baseline_stats(r).std);

        % Restrict to current region
        anomaly_raw  = anomaly_raw & reg_mask;

        % Closing fills small gaps within anomaly regions —
        % large objects produce large connected anomaly blobs
        anomaly_closed = imclose(anomaly_raw, se_close);

        % Opening removes small isolated noise responses
        anomaly_ref    = imopen(anomaly_closed, se_open);

        anomaly_maps{t, r}   = anomaly_ref;
        anomaly_ratios(t, r) = sum(anomaly_ref(:)) / num_pixels;

        fprintf('  [%s] anomaly ratio = %.3f\n', ...
            region_names{r}, anomaly_ratios(t, r));
    end

    % Flag image if any region exceeds anomaly threshold
    indirect_flags(t) = any(anomaly_ratios(t, :) > anomaly_thresh);

    fprintf('  Decision: %s\n', decision_str(indirect_flags(t)));
end

%% ----------------------------------------------------------
%  SECTION 5: DISPLAY RESULTS
% -----------------------------------------------------------

cols = min(num_targets, 5);
rows = ceil(num_targets / cols);

% --- Figure: Anomaly maps per region ---
figure('Name', 'Figure 23 - Anomaly Maps per Region', ...
    'NumberTitle', 'off', 'Position', [0, 0, 1500, rows*300]);

for t = 1:num_targets
    if img_indices(t) == 0; continue; end

    h = img_sizes(t, 1);
    w = img_sizes(t, 2);

    overlay = zeros(h, w, 3);
    overlay(:,:,1) = double(anomaly_maps{t, 1});  % left   — red
    overlay(:,:,2) = double(anomaly_maps{t, 2});  % middle — green
    overlay(:,:,3) = double(anomaly_maps{t, 3});  % right  — blue

    subplot(rows, cols, t);
    imshow(overlay);

    if indirect_flags(t)
        dec_col = [1 0.3 0.3];
    else
        dec_col = [0.3 1 0.3];
    end

    title(sprintf('[%d] %s\n%s', t, target_names{t}, ...
        decision_str(indirect_flags(t))), ...
        'FontSize', 7, 'Color', dec_col, 'Interpreter', 'none');
end
sgtitle('Figure 23 — Anomaly Maps: Left=red  Middle=green  Right=blue', ...
    'FontSize', 12, 'FontWeight', 'bold');

% --- Figure: Anomaly overlay on original ---
figure('Name', 'Figure 24 - Anomaly Overlay on Original', ...
    'NumberTitle', 'off', 'Position', [0, 0, 1500, rows*300]);

for t = 1:num_targets
    if img_indices(t) == 0; continue; end

    h       = img_sizes(t, 1);
    w       = img_sizes(t, 2);
    y_range = (1:h)';
    p_left  = polyfit(pts_left_all{t}(:,2),  pts_left_all{t}(:,1),  poly_degree);
    p_right = polyfit(pts_right_all{t}(:,2), pts_right_all{t}(:,1), poly_degree);

    % Build anomaly RGB overlay
    anomaly_overlay = zeros(h, w, 3);
    anomaly_overlay(:,:,1) = double(anomaly_maps{t, 1});
    anomaly_overlay(:,:,2) = double(anomaly_maps{t, 2});
    anomaly_overlay(:,:,3) = double(anomaly_maps{t, 3});
    anomaly_mask = any(anomaly_overlay > 0, 3);

    subplot(rows, cols, t);
    imshow(imgs{t}); hold on;
    plot(polyval(p_left,  y_range), y_range, 'y-', 'LineWidth', 1.5);
    plot(polyval(p_right, y_range), y_range, 'y-', 'LineWidth', 1.5);
    h_ov = imshow(anomaly_overlay);
    set(h_ov, 'AlphaData', 0.5 * double(anomaly_mask));

    if indirect_flags(t)
        dec_col = [1 0.3 0.3];
    else
        dec_col = [0.3 1 0.3];
    end

    title(sprintf('[%d] %s\n%s', t, target_names{t}, ...
        decision_str(indirect_flags(t))), ...
        'FontSize', 7, 'Color', dec_col, 'Interpreter', 'none');
    hold off;
end
sgtitle('Figure 24 — Anomaly Overlay on Original Image', ...
    'FontSize', 12, 'FontWeight', 'bold');

% --- Figure: Anomaly ratio bar chart ---
figure('Name', 'Figure 25 - Anomaly Ratios', ...
    'NumberTitle', 'off', 'Position', [0, 0, 1200, 400]);

bar_data = anomaly_ratios;
b = bar(bar_data, 'grouped');
b(1).FaceColor = [0.8 0.2 0.2];
b(2).FaceColor = [0.2 0.7 0.2];
b(3).FaceColor = [0.2 0.2 0.8];
yline(anomaly_thresh, 'k--', 'LineWidth', 2);
xticks(1:num_targets);
xticklabels(target_names);
xtickangle(30);
ylabel('Anomaly Ratio');
legend({'Left', 'Middle', 'Right', 'Threshold'}, 'Location', 'northeast');
title('Figure 25 — Anomaly Ratio per Region  (dashed = detection threshold)', ...
    'FontSize', 11);
grid on;

%% ----------------------------------------------------------
%  SECTION 6: SUMMARY TABLE
% -----------------------------------------------------------

fprintf('\n%-25s | L_ratio | M_ratio | R_ratio | Decision\n', 'Image');
fprintf('%s\n', repmat('-', 1, 80));
for t = 1:num_targets
    if img_indices(t) == 0; continue; end
    fprintf('%-25s | %7.3f | %7.3f | %7.3f | %s\n', ...
        target_names{t}, ...
        anomaly_ratios(t,1), anomaly_ratios(t,2), anomaly_ratios(t,3), ...
        decision_str(indirect_flags(t)));
end

%% ----------------------------------------------------------
%  SECTION 7: SAVE WORKSPACE
% -----------------------------------------------------------
save('./Output/workspace_phase7.mat', ...
    'images', 'images_gray', 'images_eq', 'images_smooth', ...
    'images_roi', 'masks', 'images_canny', 'images_closed', ...
    'images_filtered', 'images_final', ...
    'anomaly_maps', 'anomaly_ratios', 'indirect_flags', ...
    'baseline_stats', 'target_names', 'img_indices', 'img_sizes', ...
    'filenames', 'labels', 'descriptions', 'N', ...
    'subset_idx', 'subset_names', 'best_canny_sensitivity');
fprintf('\nWorkspace saved to ./Output/workspace_phase7.mat\n');

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