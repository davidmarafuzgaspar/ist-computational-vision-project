%% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 3 - Pre-filtering Comparison
%
%% ============================================================
clear; clc; close all;
load('./Output/workspace_phase2.mat');
disp('Workspace from Phase 2 loaded');

%% ----------------------------------------------------------
%  SECTION 1: PRE-FILTERS
% -----------------------------------------------------------
sigma     = 4;
mean_size = 10;

images_gauss      = cell(N, 1);
images_mean       = cell(N, 1);
images_sharp      = cell(N, 1);   % img - gaussian
images_sharp_mean = cell(N, 1);   % img - mean

for i = 1:N
    img  = images_final{i};
    mask = roi_masks{i};

    % --- Gaussian ---
    gauss           = imgaussfilt(img, sigma);
    gauss(~mask)    = 0;
    images_gauss{i} = gauss;

    % --- Mean ---
    % Local average — represents background level per neighbourhood.
    mean_kernel    = ones(mean_size) / mean_size^2;
    men            = imfilter(img, mean_kernel, 'replicate');
    men(~mask)     = 0;
    images_mean{i} = men;

    % --- Unsharp Gaussian (img - gaussian) ---
    % Removes low frequencies — only strong transitions survive.
    sharp           = imsubtract(img, gauss);
    sharp(~mask)    = 0;
    images_sharp{i} = sharp;

    % --- Unsharp Mean (img - mean) ---
    % Subtracts local background average — pixels that deviate
    % from their neighbourhood (rail edges) are preserved.
    sharp_mean           = imsubtract(img, men);
    sharp_mean(~mask)    = 0;
    images_sharp_mean{i} = sharp_mean;
end

%% ----------------------------------------------------------
%  SECTION 2: PER-IMAGE COMPARISON GRID
%  One figure per image — 5 columns:
%  Enhanced | Unsharp Gauss | Unsharp Mean | Gaussian | Mean
% -----------------------------------------------------------
for i = 1:N
    [~, name, ext] = fileparts(filenames{i});
    if labels(i) == 0
        col = [0 0.5 0]; status = 'CLEAR';
    else
        col = [0.8 0 0]; status = 'OBSTRUCTED';
    end

    figure('Name', sprintf('Image %d - Pre-filters', i), ...
        'NumberTitle', 'off', ...
        'Position', [0, 0, 1600, 380]);

    imgs_row = {
        images_final{i}, ...
        images_sharp{i}, ...
        images_sharp_mean{i}, ...
        images_gauss{i}, ...
        images_mean{i}
    };

    titles_row = {
        'Enhanced (input)', ...
        sprintf('Unsharp gauss  \\sigma=%.1f', sigma), ...
        sprintf('Unsharp mean  %dx%d', mean_size, mean_size), ...
        sprintf('Gaussian  \\sigma=%.1f', sigma), ...
        sprintf('Mean  %dx%d', mean_size, mean_size)
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
%  SECTION 3: SAVE WORKSPACE
% -----------------------------------------------------------
save('./Output/workspace_phase3.mat', ...
    'images', 'images_gray', ...
    'images_roi', 'roi_masks', ...
    'images_final', ...
    'images_gauss', ...
    'images_mean', ...
    'images_sharp', ...
    'images_sharp_mean', ...
    'sigma', 'mean_size', ...
    'filenames', 'labels', 'descriptions', 'N');
fprintf('\nWorkspace saved to ./Output/workspace_phase3.mat\n');