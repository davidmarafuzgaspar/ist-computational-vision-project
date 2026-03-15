%% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 1b - Binarization Analysis
%  Pipeline: Grayscale → CLAHE → Gaussian → Otsu binary
%  For each image — 1 row x 3 cols:
%    Col 1 — CLAHE + Gaussian image
%    Col 2 — Histogram with Otsu threshold line
%    Col 3 — Otsu binary
%
%% ============================================================
clear; clc; close all;
load('./Output/workspace_phase1.mat');
disp('Workspace from Phase 1 loaded');

figNum = 6;   % continue from Phase 1 figure numbering

% --- CLAHE parameters ---
clahe_tiles = [8 8];
clahe_clip  = 0.01;

% --- Gaussian parameters ---
gaus_sigma = 1;
gaus_size  = [5 5];
h_gaus     = fspecial('gaussian', gaus_size, gaus_sigma);

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

    % --- Pipeline: CLAHE → Gaussian → Otsu ---
    I_clahe = adapthisteq(Ig, 'NumTiles', clahe_tiles, 'ClipLimit', clahe_clip);
    I_filt  = imfilter(I_clahe, h_gaus, 'replicate');
    thresh  = graythresh(I_filt);
    I_bin   = imbinarize(I_filt, thresh);

    % --- Figure ---
    figure('Name', sprintf('Figure %d - Binarization: %s [%s]', figNum, [name ext], status), ...
        'NumberTitle', 'off', 'Position', [0 0 1100 380]);

    subplot(1, 3, 1);
    imshow(I_filt);
    title(sprintf('CLAHE + Gaussian σ=%.1f\nMean: %.0f', gaus_sigma, mean(double(I_filt(:)))), ...
        'FontSize', 9, 'Color', col);

    subplot(1, 3, 2);
    imhist(I_filt);
    xline(thresh * 255, 'r--', 'LineWidth', 1.5);
    title(sprintf('Histogram\nOtsu thr = %.0f', thresh * 255), 'FontSize', 9);
    xlabel('Intensity', 'FontSize', 7); ylabel('Count', 'FontSize', 7);

    subplot(1, 3, 3);
    imshow(I_bin);
    title(sprintf('Otsu binary\nthr = %.3f', thresh), 'FontSize', 9);

    sgtitle(sprintf('Figure %d — Binarization: %s  [%s]', figNum, [name ext], status), ...
        'FontSize', 12, 'FontWeight', 'bold', 'Color', col);

    figNum = figNum + 1;

end