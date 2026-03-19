% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 4 - Edge Detection Parameter Exploration
%
%  Authors:
%   - David Marafuz Gaspar - 106541
%   - Pedro Gaspar Mónico - 106626
%
% ============================================================
clear; clc; close all;
load('./Output/workspace_phase3.mat');
disp('Workspace from Phase 3 loaded');

%% Live Script Comment
% Before committing to a single edge detection configuration, a parameter
% exploration is conducted on a representative subset of four images
% covering the main scene categories present in the dataset: clear
% straight track, obstructed track, tunnel, and curved track. Canny
% with automatic sensitivity control and Sobel with a variable threshold
% are tested. For each approach, three parameter values are evaluated
% side by side, allowing an informed selection of the configuration
% to be carried forward into the morphological reconstruction phase.

%% ----------------------------------------------------------
%  SECTION 1: DEFINE REPRESENTATIVE SUBSET
% -----------------------------------------------------------

% Indices selected to cover the four main scene categories:
%   2  - Clear straight track
%   9  - Obstructed (rocks)
%   10 - Dark tunnel
%   4  - Clear curved track
subset_idx   = [2, 9, 10, 4];
subset_names = {'Clear - Straight', 'Obstructed - Rocks', ...
                'Clear - Tunnel',   'Clear - Curved'};
S = length(subset_idx);

%% Live Script Comment
% Figure 11 tests Canny edge detection using the automatic sensitivity
% parameter, which internally determines the low and high thresholds
% as fractions of the maximum gradient magnitude. Three sensitivity
% values are tested: 0.3 (conservative), 0.5 (moderate), and 0.7
% (aggressive). Lower sensitivity values produce sparser but cleaner
% edge maps, while higher values recover more edges at the cost of
% increased noise responses.

%% ----------------------------------------------------------
%  SECTION 2: CANNY - SENSITIVITY VARIATION
% -----------------------------------------------------------

canny_sensitivities = [0.3, 0.5, 0.7];

figure('Name', 'Figure 11 - Canny Sensitivity', ...
    'NumberTitle', 'off', ...
    'Position', [0, 0, 1400, 900]);

for k = 1:S
    i = subset_idx(k);

    for p = 1:length(canny_sensitivities)
        edge_map = edge(images_roi{i}, 'Canny', canny_sensitivities(p));

        subplot(S, length(canny_sensitivities), ...
            (k-1)*length(canny_sensitivities) + p);
        imshow(edge_map);

        if labels(i) == 0
            col = [0 0.5 0];
        else
            col = [0.8 0 0];
        end

        title(sprintf('%s\nSensitivity: %.1f', ...
            subset_names{k}, canny_sensitivities(p)), ...
            'FontSize', 7, 'Color', col);
    end
end

sgtitle('Figure 11 — Canny: Sensitivity Variation  (green = clear  |  red = obstructed)', ...
    'FontSize', 12, 'FontWeight', 'bold');

%% Live Script Comment
% Figure 12 tests the Sobel operator with three threshold values. Unlike
% Canny, Sobel does not apply non-maximum suppression, producing thicker
% edges. Three threshold values are tested: 0.05 (permissive), 0.10
% (moderate), and 0.20 (strict). Higher thresholds suppress weaker
% gradient responses, retaining only the most prominent edges.

%% ----------------------------------------------------------
%  SECTION 3: SOBEL - THRESHOLD VARIATION
% -----------------------------------------------------------

sobel_thresholds = [0.05, 0.10, 0.20];

figure('Name', 'Figure 12 - Sobel Threshold', ...
    'NumberTitle', 'off', ...
    'Position', [0, 0, 1400, 900]);

for k = 1:S
    i = subset_idx(k);

    for p = 1:length(sobel_thresholds)
        edge_map = edge(images_roi{i}, 'Sobel', sobel_thresholds(p));

        subplot(S, length(sobel_thresholds), ...
            (k-1)*length(sobel_thresholds) + p);
        imshow(edge_map);

        if labels(i) == 0
            col = [0 0.5 0];
        else
            col = [0.8 0 0];
        end

        title(sprintf('%s\nThreshold: %.2f', ...
            subset_names{k}, sobel_thresholds(p)), ...
            'FontSize', 7, 'Color', col);
    end
end

sgtitle('Figure 12 — Sobel: Threshold Variation  (green = clear  |  red = obstructed)', ...
    'FontSize', 12, 'FontWeight', 'bold');

%% Live Script Comment
% Figure 13 consolidates the best configuration from each method into a
% direct side-by-side comparison across the four representative images,
% with the ROI included as reference. Update the best configuration
% variables below after reviewing Figures 11 and 12.

%% ----------------------------------------------------------
%  SECTION 4: BEST CONFIGURATION COMPARISON
% -----------------------------------------------------------

% --- Update these after reviewing Figures 11 and 12 ---
best_canny_sensitivity = 0.5;
best_sobel_threshold   = 0.10;

figure('Name', 'Figure 13 - Best Configuration Comparison', ...
    'NumberTitle', 'off', ...
    'Position', [0, 0, 1400, 900]);

for k = 1:S
    i = subset_idx(k);

    if labels(i) == 0
        col = [0 0.5 0];
    else
        col = [0.8 0 0];
    end

    % ROI reference
    subplot(S, 3, (k-1)*3 + 1);
    imshow(images_roi{i});
    title(sprintf('%s\nROI Reference', subset_names{k}), ...
        'FontSize', 7, 'Color', col);

    % Best Canny
    subplot(S, 3, (k-1)*3 + 2);
    imshow(edge(images_roi{i}, 'Canny', best_canny_sensitivity));
    title(sprintf('%s\nCanny (%.1f)', ...
        subset_names{k}, best_canny_sensitivity), ...
        'FontSize', 7, 'Color', col);

    % Best Sobel
    subplot(S, 3, (k-1)*3 + 3);
    imshow(edge(images_roi{i}, 'Sobel', best_sobel_threshold));
    title(sprintf('%s\nSobel (%.2f)', ...
        subset_names{k}, best_sobel_threshold), ...
        'FontSize', 7, 'Color', col);
end

sgtitle('Figure 13 — Best Configuration: ROI vs Canny vs Sobel  (green = clear  |  red = obstructed)', ...
    'FontSize', 12, 'FontWeight', 'bold');

%% ----------------------------------------------------------
%  SECTION 5: SAVE WORKSPACE
% -----------------------------------------------------------
save('./Output/workspace_phase4.mat', ...
    'images', 'images_gray', 'images_eq', 'images_smooth', ...
    'images_roi', 'masks', 'filenames', 'labels', 'descriptions', 'N', ...
    'subset_idx', 'subset_names', ...
    'best_canny_sensitivity', 'best_sobel_threshold');
fprintf('\nWorkspace saved to ./Output/workspace_phase4.mat\n');