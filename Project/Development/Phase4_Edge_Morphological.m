%% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 4 - Binarization & Morphological Cleanup
%
%% ============================================================
clear; clc; close all;
load('./Output/workspace_phase3.mat');
disp('Workspace from Phase 3 loaded');

%% ----------------------------------------------------------
%  SECTION 1: OTSU BINARIZATION
%  Two inputs: unsharp gaussian and unsharp mean
%  Otsu threshold computed only from ROI pixels
% -----------------------------------------------------------
images_binary_gauss = cell(N, 1);
images_binary_mean  = cell(N, 1);
thresh_gauss        = zeros(N, 1);
thresh_mean         = zeros(N, 1);

for i = 1:N
    mask = roi_masks{i};

    % --- Unsharp Gaussian → Otsu ---
    img_g          = images_sharp{i};
    level_g        = max(graythresh(img_g(mask)), 0.10);
    thresh_gauss(i) = level_g;
    bin_g          = imbinarize(img_g, level_g);
    bin_g(~mask)   = 0;
    images_binary_gauss{i} = bin_g;

    % --- Unsharp Mean → Otsu ---
    img_m          = images_sharp_mean{i};
    level_m        = max(graythresh(img_m(mask)), 0.10);
    thresh_mean(i)  = level_m;
    bin_m          = imbinarize(img_m, level_m);
    bin_m(~mask)   = 0;
    images_binary_mean{i} = bin_m;
end

% Report thresholds
fprintf('\n%-4s  %-26s  %-11s  %12s  %12s\n', ...
    'ID', 'File', 'Class', 'Thresh gauss', 'Thresh mean');
fprintf('%s\n', repmat('-', 1, 68));
for i = 1:N
    [~, name, ext] = fileparts(filenames{i});
    if labels(i) == 0, cls = 'CLEAR'; else, cls = 'OBSTRUCTED'; end
    fprintf('%-4d  %-26s  %-11s  %12.4f  %12.4f\n', ...
        i, [name ext], cls, thresh_gauss(i), thresh_mean(i));
end

%% ----------------------------------------------------------
%  SECTION 2: MORPHOLOGICAL CLEANUP
% -----------------------------------------------------------
se_length = 3;
min_area  = 200;
se_close  = strel('line', se_length, 90);

images_clean_gauss = cell(N, 1);
images_clean_mean  = cell(N, 1);

for i = 1:N
    mask = roi_masks{i};

    % Unsharp gauss binary
    bg = imclose(images_binary_gauss{i}, se_close);
    bg = bwareaopen(bg, min_area);
    bg(~mask)              = 0;
    images_clean_gauss{i}  = bg;

    % Unsharp mean binary
    bm = imclose(images_binary_mean{i}, se_close);
    bm = bwareaopen(bm, min_area);
    bm(~mask)             = 0;
    images_clean_mean{i}  = bm;
end

%% ----------------------------------------------------------
%  SECTION 3: PER-IMAGE COMPARISON GRID
%  One figure per image — 5 columns:
%  Enhanced | Unsharp gauss | Unsharp mean | Clean gauss | Clean mean
% -----------------------------------------------------------
for i = 1:N
    [~, name, ext] = fileparts(filenames{i});
    if labels(i) == 0
        col = [0 0.5 0]; status = 'CLEAR';
    else
        col = [0.8 0 0]; status = 'OBSTRUCTED';
    end

    figure('Name', sprintf('Image %d - Binarization', i), ...
        'NumberTitle', 'off', ...
        'Position', [0, 0, 1600, 380]);

    imgs_row = {
        images_final{i}, ...
        images_sharp{i}, ...
        images_sharp_mean{i}, ...
        images_clean_gauss{i}, ...
        images_clean_mean{i}
    };

    titles_row = {
        'Enhanced (input)', ...
        sprintf('Unsharp gauss \\sigma=%.1f', sigma), ...
        sprintf('Unsharp mean  %dx%d', mean_size, mean_size), ...
        sprintf('Binary gauss  Otsu=%.3f', thresh_gauss(i)), ...
        sprintf('Binary mean   Otsu=%.3f', thresh_mean(i))
    };

    for m = 1:5
        subplot(1, 5, m);
        imshow(imgs_row{m});
        title(titles_row{m}, 'FontSize', 9);
    end

    sgtitle(sprintf('[%d] %s  —  %s', i, [name ext], status), ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'Color', col, 'Interpreter', 'none');
end

%% ----------------------------------------------------------
%  SECTION 4: FULL DATASET OVERVIEW — BEST METHOD
% -----------------------------------------------------------
% Display clean mean binary as the primary candidate for Hough

figure('Name', 'Figure - Binary Overview (unsharp mean)', ...
    'NumberTitle', 'off', ...
    'Position', [0, 0, 1500, 900]);

for i = 1:N
    subplot(3, 5, i);
    imshow(images_clean_mean{i});
    if labels(i) == 0, col = [0 0.5 0]; else, col = [0.8 0 0]; end
    [~, name, ext] = fileparts(filenames{i});
    title(sprintf('[%d] %s', i, [name ext]), ...
        'FontSize', 6, 'Color', col, 'Interpreter', 'none');
end
sgtitle('Binary images — unsharp mean + Otsu + morphological cleanup', ...
    'FontSize', 12, 'FontWeight', 'bold');

%% ----------------------------------------------------------
%  SECTION 5: SAVE WORKSPACE
% -----------------------------------------------------------
save('./Output/workspace_phase4.mat', ...
    'images', 'images_gray', ...
    'images_roi', 'roi_masks', ...
    'images_final', ...
    'images_sharp', 'images_sharp_mean', ...
    'images_binary_gauss', 'images_binary_mean', ...
    'images_clean_gauss',  'images_clean_mean', ...
    'thresh_gauss', 'thresh_mean', ...
    'se_length', 'min_area', ...
    'mean_size', 'sigma', ...
    'filenames', 'labels', 'descriptions', 'N');
fprintf('\nWorkspace saved to ./Output/workspace_phase4.mat\n');