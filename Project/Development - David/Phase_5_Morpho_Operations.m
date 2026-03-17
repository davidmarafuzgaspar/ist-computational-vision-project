% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 5 - Morphological Closing with Canny
%
%  Authors:
%   - David Marafuz Gaspar - 106541
%   - Pedro Gaspar Mónico - 106626
%
% ============================================================
clear; clc; close all;
load('./Output/workspace_phase4.mat');
disp('Workspace from Phase 4 loaded');

%% Live Script Comment
% The Sobel operator was discarded following the parameter exploration in
% Phase 4, as it produced poor edge maps for this dataset. Canny edge
% detection is therefore adopted as the sole edge extraction method.
% This phase evaluates three structuring element sizes for the morphological
% closing operation — 5×5, 7×7, and 10×10 — applied to the Canny edge
% maps of the representative subset. The 7×7 SE was found to best
% reconstruct continuous rail BLOBs without excessively merging unrelated
% structures, and is subsequently applied to the full dataset.

%% ----------------------------------------------------------
%  SECTION 1: CANNY EDGE DETECTION (FULL DATASET)
% -----------------------------------------------------------

best_canny_sensitivity = 0.5;

images_canny = cell(N, 1);
for i = 1:N
    images_canny{i} = edge(images_roi{i}, 'Canny', best_canny_sensitivity);
end

%% ----------------------------------------------------------
%  SECTION 2: DEFINE STRUCTURING ELEMENTS
% -----------------------------------------------------------

se_5  = strel('square', 5);
se_7  = strel('square', 7);
se_10 = strel('square', 10);

%% ----------------------------------------------------------
%  SECTION 3: SE SIZE EXPLORATION ON REPRESENTATIVE SUBSET
% -----------------------------------------------------------

canny_close_5_sub  = cell(length(subset_idx), 1);
canny_close_7_sub  = cell(length(subset_idx), 1);
canny_close_10_sub = cell(length(subset_idx), 1);

for k = 1:length(subset_idx)
    i = subset_idx(k);
    canny_close_5_sub{k}  = imclose(images_canny{i}, se_5);
    canny_close_7_sub{k}  = imclose(images_canny{i}, se_7);
    canny_close_10_sub{k} = imclose(images_canny{i}, se_10);
end

%% Live Script Comment
% Figure 14 shows the SE size comparison on the four representative images.
% The 5×5 SE performs a conservative reconstruction, bridging only very
% close edge fragments. The 7×7 SE offers the best balance between
% connectivity and specificity. The 10×10 SE produces the most aggressive
% reconstruction, risking the merging of rail BLOBs with unrelated
% background structures.

%% ----------------------------------------------------------
%  SECTION 4: DISPLAY SE SIZE COMPARISON (SUBSET)
% -----------------------------------------------------------

figure('Name', 'Figure 14 - Canny Closing SE Size Comparison', ...
    'NumberTitle', 'off', ...
    'Position', [0, 0, 1400, 900]);

for k = 1:length(subset_idx)
    i = subset_idx(k);

    if labels(i) == 0
        col = [0 0.5 0];
    else
        col = [0.8 0 0];
    end

    subplot(length(subset_idx), 4, (k-1)*4 + 1);
    imshow(images_canny{i});
    title(sprintf('%s\nCanny Raw', subset_names{k}), ...
        'FontSize', 7, 'Color', col);

    subplot(length(subset_idx), 4, (k-1)*4 + 2);
    imshow(canny_close_5_sub{k});
    title(sprintf('%s\nClose 5×5', subset_names{k}), ...
        'FontSize', 7, 'Color', col);

    subplot(length(subset_idx), 4, (k-1)*4 + 3);
    imshow(canny_close_7_sub{k});
    title(sprintf('%s\nClose 7×7', subset_names{k}), ...
        'FontSize', 7, 'Color', col);

    subplot(length(subset_idx), 4, (k-1)*4 + 4);
    imshow(canny_close_10_sub{k});
    title(sprintf('%s\nClose 10×10', subset_names{k}), ...
        'FontSize', 7, 'Color', col);
end

sgtitle('Figure 14 — Canny Closing: 5×5 vs 7×7 vs 10×10  (green = clear  |  red = obstructed)', ...
    'FontSize', 12, 'FontWeight', 'bold');

%% Live Script Comment
% Having selected the 7×7 SE as the optimal closing configuration,
% Figure 15 shows the final closed edge maps for all 15 images in the
% dataset. This constitutes the output of the morphological reconstruction
% stage and will serve as input for the subsequent BLOB orientation
% filtering phase.

%% ----------------------------------------------------------
%  SECTION 5: APPLY 7x7 CLOSING TO FULL DATASET
% -----------------------------------------------------------

images_closed = cell(N, 1);
for i = 1:N
    images_closed{i} = imclose(images_canny{i}, se_7);
end

% --- Figure 15: Full Dataset Closing Grid ---
figure('Name', 'Figure 15 - Canny + Closing 7x7 (Full Dataset)', ...
    'NumberTitle', 'off', ...
    'Position', [0, 0, 1500, 900]);

for i = 1:N
    subplot(3, 5, i);
    imshow(images_closed{i});

    if labels(i) == 0
        col = [0 0.5 0];
    else
        col = [0.8 0 0];
    end

    [~, name, ext] = fileparts(filenames{i});
    title(sprintf('[%d] %s\n%s', i, [name ext], descriptions{i}), ...
        'FontSize', 7, 'Color', col, 'Interpreter', 'none');
end

sgtitle('Figure 15 — Canny + Closing 7×7: Full Dataset  (green = clear  |  red = obstructed)', ...
    'FontSize', 13, 'FontWeight', 'bold');

%% ----------------------------------------------------------
%  SECTION 6: SAVE WORKSPACE
% -----------------------------------------------------------
save('./Output/workspace_phase5.mat', ...
    'images', 'images_gray', 'images_eq', 'images_smooth', ...
    'images_roi', 'masks', 'images_canny', 'images_closed', ...
    'filenames', 'labels', 'descriptions', 'N', ...
    'subset_idx', 'subset_names', 'best_canny_sensitivity');
fprintf('\nWorkspace saved to ./Output/workspace_phase5.mat\n');