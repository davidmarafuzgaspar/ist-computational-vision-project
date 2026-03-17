%% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  FILTER SWEEP — Find best filter before binarization
%  Pipeline: Grayscale → CLAHE → filter → Otsu binary
%
%  4 test images x 10 filter variants + original CLAHE
%  Filters tested:
%    Gaussian  x3 — σ=0.5, σ=1, σ=2
%    Mean      x2 — 3x3, 7x7
%    Median    x2 — 3x3, 7x7
%    High-pass x3 — strength 0.3, 0.6, 1.0
%
%% ============================================================
clear; clc; close all;
load('./Output/workspace_phase1.mat');
disp('Workspace from Phase 1 loaded');

%% ----------------------------------------------------------
%  CONFIGURATION
% -----------------------------------------------------------

test_idx = [4, 10, 1, 12];   % clear curved | tunnel | obstr rocks | obstr rocks

% --- CLAHE (applied before every filter) ---
clahe_tiles = [8 8];
clahe_clip  = 0.01;

%% ----------------------------------------------------------
%  FILTER DEFINITIONS
% -----------------------------------------------------------

filters = {
    'Gaussian σ=0.5',  @(I) imfilter(I, fspecial('gaussian',  5, 0.5), 'replicate');
    'Gaussian σ=1.0',  @(I) imfilter(I, fspecial('gaussian',  7, 1.0), 'replicate');
    'Gaussian σ=2.0',  @(I) imfilter(I, fspecial('gaussian', 11, 2.0), 'replicate');
    'Mean 3x3',        @(I) imfilter(I, fspecial('average', [3 3]), 'replicate');
    'Mean 7x7',        @(I) imfilter(I, fspecial('average', [7 7]), 'replicate');
    'Median 3x3',      @(I) medfilt2(I, [3 3]);
    'Median 7x7',      @(I) medfilt2(I, [7 7]);
    'High-pass 0.3',   @(I) imsharpen(I, 'Amount', 0.3, 'Radius', 1);
    'High-pass 0.6',   @(I) imsharpen(I, 'Amount', 0.6, 'Radius', 1);
    'High-pass 1.0',   @(I) imsharpen(I, 'Amount', 1.0, 'Radius', 1);
};

nFilters = size(filters, 1);

%% ----------------------------------------------------------
%  SWEEP — one figure per test image
%  2 rows x (nFilters+1) cols
%  Col 1: CLAHE only (no extra filter)
%  Cols 2-end: CLAHE → each filter
%  Row 1: image after filter   Row 2: Otsu binary
% -----------------------------------------------------------

for t = 1:length(test_idx)

    i  = test_idx(t);
    Ig = images_gray{i};
    [~, name, ext] = fileparts(filenames{i});

    if labels(i) == 0
        col = [0 0.5 0]; status = 'CLEAR';
    else
        col = [0.8 0 0]; status = 'OBSTRUCTED';
    end

    % Apply CLAHE first — common to all variants
    I_clahe = adapthisteq(Ig, 'NumTiles', clahe_tiles, 'ClipLimit', clahe_clip);

    nCols = nFilters + 1;

    figure('Name', sprintf('Filter sweep: %s [%s]', [name ext], status), ...
        'NumberTitle', 'off', 'Position', [0 0 2200 500]);

    % --- Col 1: CLAHE only (no filter) ---
    subplot(2, nCols, 1);
    imshow(I_clahe);
    title(sprintf('CLAHE only\nMean: %.0f', mean(double(I_clahe(:)))), ...
        'FontSize', 8, 'Color', col);

    subplot(2, nCols, nCols+1);
    thr_clahe = graythresh(I_clahe);
    imshow(imbinarize(I_clahe, thr_clahe));
    title(sprintf('Otsu binary\nthr=%.0f', thr_clahe*255), 'FontSize', 8);

    % --- Cols 2 to end: CLAHE → each filter ---
    for k = 1:nFilters

        lbl    = filters{k, 1};
        ffun   = filters{k, 2};
        I_filt = ffun(I_clahe);   % filter applied ON TOP of CLAHE
        thr    = graythresh(I_filt);
        I_bin  = imbinarize(I_filt, thr);

        subplot(2, nCols, k+1);
        imshow(I_filt);
        title(lbl, 'FontSize', 8);

        subplot(2, nCols, nCols+k+1);
        imshow(I_bin);
        title(sprintf('thr=%.0f', thr*255), 'FontSize', 8);

    end

    sgtitle(sprintf('Filter sweep (CLAHE → filter → Otsu): %s  [%s]   |   Gaussian(3)  Mean(2)  Median(2)  High-pass(3)', ...
        [name ext], status), ...
        'FontSize', 11, 'FontWeight', 'bold', 'Color', col);

end