%% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 1b - Binarization Analysis
%  For each image — 3 rows x 3 cols:
%    Row 1 — Grayscale:  image | histogram | Otsu binary
%    Row 2 — histeq:     image | histogram | Otsu binary
%    Row 3 — CLAHE:      image | histogram | Otsu binary
%
%% ============================================================
clear; clc; close all;
load('./Output/workspace_phase1.mat');
disp('Workspace from Phase 1 loaded');

figNum = 6;   % continue from Phase 1 figure numbering

% --- CLAHE parameters ---
clahe_tiles = [8 8];   % (try [4 4], [16 16])
clahe_clip  = 0.01;    % (try 0.005, 0.02)

for i = 1:N

    Ig = images_gray{i};
    [~, name, ext] = fileparts(filenames{i});

    if labels(i) == 0
        col    = [0 0.5 0];
        status = 'CLEAR';
    else
        col    = [0.8 0 0];
        status = 'OBSTRUCTED';
    end

    % --- Compute ---
    thresh_gray  = graythresh(Ig);
    I_gray_bin   = imbinarize(Ig, thresh_gray);

    I_heq        = histeq(Ig);
    thresh_heq   = graythresh(I_heq);
    I_heq_bin    = imbinarize(I_heq, thresh_heq);

    I_clahe      = adapthisteq(Ig, 'NumTiles', clahe_tiles, 'ClipLimit', clahe_clip);
    thresh_clahe = graythresh(I_clahe);
    I_clahe_bin  = imbinarize(I_clahe, thresh_clahe);

    % --- Figure ---
    figure('Name', sprintf('Figure %d - Binarization: %s [%s]', figNum, [name ext], status), ...
        'NumberTitle', 'off', 'Position', [0 0 1200 800]);

    % --- Row 1: Grayscale ---
    subplot(3, 3, 1);
    imshow(Ig);
    title(sprintf('Grayscale\nMean: %.0f', mean(double(Ig(:)))), ...
        'FontSize', 8, 'Color', col);

    subplot(3, 3, 2);
    imhist(Ig);
    xline(thresh_gray * 255, 'r--', 'LineWidth', 1.5);
    title(sprintf('Grayscale histogram\nOtsu thr = %.0f', thresh_gray * 255), ...
        'FontSize', 8);
    xlabel('Intensity', 'FontSize', 7); ylabel('Count', 'FontSize', 7);

    subplot(3, 3, 3);
    imshow(I_gray_bin);
    title(sprintf('Otsu binary\nthr = %.3f', thresh_gray), 'FontSize', 8);

    % --- Row 2: histeq ---
    subplot(3, 3, 4);
    imshow(I_heq);
    title(sprintf('histeq\nMean: %.0f', mean(double(I_heq(:)))), ...
        'FontSize', 8);

    subplot(3, 3, 5);
    imhist(I_heq);
    xline(thresh_heq * 255, 'r--', 'LineWidth', 1.5);
    title(sprintf('histeq histogram\nOtsu thr = %.0f', thresh_heq * 255), ...
        'FontSize', 8);
    xlabel('Intensity', 'FontSize', 7); ylabel('Count', 'FontSize', 7);

    subplot(3, 3, 6);
    imshow(I_heq_bin);
    title(sprintf('histeq → binary\nthr = %.3f', thresh_heq), 'FontSize', 8);

    % --- Row 3: CLAHE ---
    subplot(3, 3, 7);
    imshow(I_clahe);
    title(sprintf('CLAHE [%dx%d]\nMean: %.0f', clahe_tiles(1), clahe_tiles(2), ...
        mean(double(I_clahe(:)))), 'FontSize', 8);

    subplot(3, 3, 8);
    imhist(I_clahe);
    xline(thresh_clahe * 255, 'r--', 'LineWidth', 1.5);
    title(sprintf('CLAHE histogram\nOtsu thr = %.0f', thresh_clahe * 255), ...
        'FontSize', 8);
    xlabel('Intensity', 'FontSize', 7); ylabel('Count', 'FontSize', 7);

    subplot(3, 3, 9);
    imshow(I_clahe_bin);
    title(sprintf('CLAHE → binary\nthr = %.3f', thresh_clahe), 'FontSize', 8);

    sgtitle(sprintf('Figure %d — Binarization: %s  [%s]', figNum, [name ext], status), ...
        'FontSize', 12, 'FontWeight', 'bold', 'Color', col);

    figNum = figNum + 1;

end