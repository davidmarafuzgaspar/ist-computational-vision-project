%% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 2 - Gaussian Filter Parameter Comparison (after CLAHE)
%
%  Tests sigma = 0.5, 1, 2, 3 on 5 selected images.
%
%% ============================================================
clear; clc; close all;
load('./Output/workspace_phase2.mat');
disp('Workspace from Phase 2 loaded');

%% ----------------------------------------------------------
%  PARAMETERS
% -----------------------------------------------------------

SIGMAS   = [0.5, 1, 2, 3];
SELECTED = [2, 10, 1, 13, 4];

%% ----------------------------------------------------------
%  SECTION 1: GAUSSIAN SIGMA COMPARISON
%
%  Grid: 5 rows (one per image) x 10 columns
%    col 1-2  — CLAHE input + histogram
%    col 3-4  — sigma=0.5  + histogram
%    col 5-6  — sigma=1    + histogram
%    col 7-8  — sigma=2    + histogram
%    col 9-10 — sigma=3    + histogram
% -----------------------------------------------------------

figure('Name', 'Figure - Gaussian Sigma Comparison', ...
    'NumberTitle', 'off', ...
    'Position', [0, 0, 2000, 1100]);

for row = 1:length(SELECTED)
    i   = SELECTED(row);
    img = images_clahe{i};

    if labels(i) == 0, col = [0 0.5 0]; status = 'CLEAR';
    else,               col = [0.8 0 0]; status = 'OBSTRUCTED'; end
    [~, name, ext] = fileparts(filenames{i});
    base_title = sprintf('[%d] %s — %s', i, [name ext], status);

    % ── Col 1-2: CLAHE input ──────────────────────────────────────────
    subplot(5, 10, (row-1)*10 + 1);
    imshow(img);
    title(sprintf('%s\nCLAHE', base_title), ...
        'FontSize', 6, 'Color', col, 'Interpreter', 'none');

    subplot(5, 10, (row-1)*10 + 2);
    imhist(img); set(gca, 'FontSize', 6);
    title(sprintf('mean=%.0f', mean(double(img(:)))), 'FontSize', 6);

    % ── Col 3-10: Gaussian sigmas ─────────────────────────────────────
    for s = 1:length(SIGMAS)
        sigma   = SIGMAS(s);
        img_g   = imgaussfilt(img, sigma);

        subplot(5, 10, (row-1)*10 + (s-1)*2 + 3);
        imshow(img_g);
        title(sprintf('\\sigma = %.1f', sigma), 'FontSize', 6);

        subplot(5, 10, (row-1)*10 + (s-1)*2 + 4);
        imhist(img_g); set(gca, 'FontSize', 6);
        title(sprintf('mean=%.0f', mean(double(img_g(:)))), 'FontSize', 6);
    end
end

sgtitle('Figure — Gaussian \sigma Comparison  (CLAHE | \sigma=0.5 | \sigma=1 | \sigma=2 | \sigma=3)', ...
    'FontSize', 12, 'FontWeight', 'bold');

%% ----------------------------------------------------------
%  SECTION 2: SAVE WORKSPACE
% -----------------------------------------------------------

save('./Output/workspace_phase2.mat', ...
    'images', 'images_gray', 'images_clahe', ...
    'filenames', 'labels', 'descriptions', 'N', 'SELECTED', ...
    'CLAHE_TILES', 'CLAHE_CLIPLIMIT');

fprintf('\nWorkspace saved to ./Output/workspace_phase2.mat\n');