%% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 2 - Spatial Filter Comparison (after CLAHE)
%
%  Tests 3 low-pass filters on 5 selected images:
%    1. Averaging filter
%    2. Gaussian filter
%    3. Median filter
%
%% ============================================================
clear; clc; close all;
load('./Output/workspace_phase1.mat');
disp('Workspace from Phase 1 loaded');

%% ----------------------------------------------------------
%  PARAMETERS
% -----------------------------------------------------------

SELECTED = [2, 10, 1, 13, 4];

% CLAHE (fixed from Phase 2 analysis)
CLAHE_TILES     = [8 8];
CLAHE_CLIPLIMIT = 0.02;

% Filter kernel size (same for all 3 for fair comparison)
KERNEL_SIZE = 5;   % 5x5

%% ----------------------------------------------------------
%  SECTION 1: APPLY CLAHE TO SELECTED IMAGES
% -----------------------------------------------------------

images_clahe = cell(N, 1);
for i = 1:N
    images_clahe{i} = adapthisteq(images_gray{i}, ...
        'NumTiles',     CLAHE_TILES, ...
        'ClipLimit',    CLAHE_CLIPLIMIT, ...
        'Distribution', 'uniform');
end

%% ----------------------------------------------------------
%  SECTION 2: SPATIAL FILTER COMPARISON
%
%  Grid: 5 rows (one per image) x 8 columns
%    col 1 — CLAHE (input to filters)
%    col 2 — histogram of CLAHE
%    col 3 — Averaging
%    col 4 — histogram of Averaging
%    col 5 — Gaussian
%    col 6 — histogram of Gaussian
%    col 7 — Median
%    col 8 — histogram of Median
% -----------------------------------------------------------

figure('Name', 'Figure - Spatial Filter Comparison', ...
    'NumberTitle', 'off', ...
    'Position', [0, 0, 1800, 1100]);

for row = 1:length(SELECTED)
    i   = SELECTED(row);
    img = images_clahe{i};

    % ── Averaging filter ──────────────────────────────────────────────
    % Uniform low-pass: replaces each pixel with the mean of its
    % neighbourhood. Simple but blurs edges significantly.
    h_avg   = fspecial('average', KERNEL_SIZE);
    img_avg = imfilter(img, h_avg, 'replicate');

    % ── Gaussian filter ───────────────────────────────────────────────
    % Weighted low-pass: centre pixels contribute more than periphery.
    % Softer blur than averaging, better edge preservation.
    img_gauss = imgaussfilt(img, 1.0);   % sigma=1, ~5x5 effective kernel

    % ── Median filter ─────────────────────────────────────────────────
    % Non-linear: replaces each pixel with the median of its neighbourhood.
    % Excellent at removing salt-and-pepper noise while preserving edges.
    img_med = medfilt2(img, [KERNEL_SIZE KERNEL_SIZE]);

    % ── Title colour ──────────────────────────────────────────────────
    if labels(i) == 0, col = [0 0.5 0]; status = 'CLEAR';
    else,               col = [0.8 0 0]; status = 'OBSTRUCTED'; end
    [~, name, ext] = fileparts(filenames{i});
    base_title = sprintf('[%d] %s — %s', i, [name ext], status);

    % ── Col 1-2: CLAHE input ──────────────────────────────────────────
    subplot(5, 8, (row-1)*8 + 1);
    imshow(img);
    title(sprintf('%s\nCLAHE', base_title), ...
        'FontSize', 6, 'Color', col, 'Interpreter', 'none');

    subplot(5, 8, (row-1)*8 + 2);
    imhist(img); set(gca, 'FontSize', 6);
    title(sprintf('mean=%.0f', mean(double(img(:)))), 'FontSize', 6);

    % ── Col 3-4: Averaging ────────────────────────────────────────────
    subplot(5, 8, (row-1)*8 + 3);
    imshow(img_avg);
    title(sprintf('Averaging %dx%d', KERNEL_SIZE, KERNEL_SIZE), 'FontSize', 6);

    subplot(5, 8, (row-1)*8 + 4);
    imhist(img_avg); set(gca, 'FontSize', 6);
    title(sprintf('mean=%.0f', mean(double(img_avg(:)))), 'FontSize', 6);

    % ── Col 5-6: Gaussian ─────────────────────────────────────────────
    subplot(5, 8, (row-1)*8 + 5);
    imshow(img_gauss);
    title('Gaussian (\sigma=1)', 'FontSize', 6);

    subplot(5, 8, (row-1)*8 + 6);
    imhist(img_gauss); set(gca, 'FontSize', 6);
    title(sprintf('mean=%.0f', mean(double(img_gauss(:)))), 'FontSize', 6);

    % ── Col 7-8: Median ───────────────────────────────────────────────
    subplot(5, 8, (row-1)*8 + 7);
    imshow(img_med);
    title(sprintf('Median %dx%d', KERNEL_SIZE, KERNEL_SIZE), 'FontSize', 6);

    subplot(5, 8, (row-1)*8 + 8);
    imhist(img_med); set(gca, 'FontSize', 6);
    title(sprintf('mean=%.0f', mean(double(img_med(:)))), 'FontSize', 6);
end

sgtitle('Figure — Spatial Filter Comparison  (CLAHE | Averaging | Gaussian | Median)  kernel=5x5', ...
    'FontSize', 12, 'FontWeight', 'bold');

%% ----------------------------------------------------------
%  SECTION 3: SAVE WORKSPACE
% -----------------------------------------------------------

save('./Output/workspace_phase2.mat', ...
    'images', 'images_gray', 'images_clahe', ...
    'filenames', 'labels', 'descriptions', 'N', 'SELECTED', ...
    'CLAHE_TILES', 'CLAHE_CLIPLIMIT');

fprintf('\nWorkspace saved to ./Output/workspace_phase2.mat\n');