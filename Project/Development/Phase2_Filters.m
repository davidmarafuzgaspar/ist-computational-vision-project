%% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 2 - Spatial Filters
%
%% ============================================================
clear; clc; close all;
load('./Output/workspace_phase1.mat');
disp('Workspace from Phase 1 loaded');

%% ----------------------------------------------------------
%  CONFIGURATION
%  One clear and one obstructed image for all comparisons.
%  Change these indices to try different pairs.
%
%  Index | Image          | Type
%  ------+----------------+---------------------------
%    2   | Frame1253      | Clear - straight
%    4   | Frame1532      | Clear - curved
%   10   | image04925     | Clear - dark/tunnel
%    1   | cortada11      | Obstructed - rocks
%   12   | j30            | Obstructed - rocks
%   13   | l20            | Obstructed - vegetation
% -----------------------------------------------------------

idx_clear = 4;    % <-- change to try a different clear image
idx_obstr = 12;   % <-- change to try a different obstructed image

test_idx = [idx_clear, idx_obstr];

figNum = 6;   % continue from Phase 1 figure numbering

%% ----------------------------------------------------------
%  SECTION 1: AVERAGING FILTER — PARAMETER SWEEP
%  Varying kernel size: [3x3], [5x5], [7x7], [9x9]
% -----------------------------------------------------------

avg_sizes = {[3 3], [5 5], [7 7], [9 9]};
nVariants = length(avg_sizes);

for t = 1:length(test_idx)

    i  = test_idx(t);
    Ig = images_gray{i};
    [~, name, ext] = fileparts(filenames{i});

    if labels(i) == 0
        col = [0 0.5 0]; status = 'CLEAR';
    else
        col = [0.8 0 0]; status = 'OBSTRUCTED';
    end

    figure('Name', sprintf('Figure %d - Averaging sweep: %s [%s]', figNum, [name ext], status), ...
        'NumberTitle', 'off', 'Position', [0 0 1400 550]);

    % Col 1: original
    subplot(2, nVariants+1, 1);
    imshow(Ig);
    title(sprintf('Original\nMean: %.0f', mean(double(Ig(:)))), ...
        'FontSize', 8, 'Color', col);
    subplot(2, nVariants+1, nVariants+2);
    imhist(Ig); xlabel('Intensity', 'FontSize', 7); ylabel('Count', 'FontSize', 7);

    % Cols 2 to end: each kernel size
    for k = 1:nVariants
        sz  = avg_sizes{k};
        I_f = imfilter(Ig, fspecial('average', sz), 'replicate');

        subplot(2, nVariants+1, k+1);
        imshow(I_f);
        title(sprintf('Averaging [%dx%d]\nMean: %.0f', sz(1), sz(2), mean(double(I_f(:)))), ...
            'FontSize', 8);
        subplot(2, nVariants+1, k+nVariants+2);
        imhist(I_f); xlabel('Intensity', 'FontSize', 7); ylabel('Count', 'FontSize', 7);
    end

    sgtitle(sprintf('Figure %d — Averaging sweep: %s  [%s]', figNum, [name ext], status), ...
        'FontSize', 12, 'FontWeight', 'bold', 'Color', col);

    figNum = figNum + 1;

end

%% ----------------------------------------------------------
%  SECTION 2: GAUSSIAN FILTER — PARAMETER SWEEP
%  Varying sigma: 0.5, 1, 1.5, 2, 3  (kernel fixed at 11x11
%  to avoid cutting off the kernel at large sigma values)
% -----------------------------------------------------------

gaus_sigmas = [0.5, 1, 1.5, 2, 3];
gaus_size   = [11 11];
nVariants   = length(gaus_sigmas);

for t = 1:length(test_idx)

    i  = test_idx(t);
    Ig = images_gray{i};
    [~, name, ext] = fileparts(filenames{i});

    if labels(i) == 0
        col = [0 0.5 0]; status = 'CLEAR';
    else
        col = [0.8 0 0]; status = 'OBSTRUCTED';
    end

    figure('Name', sprintf('Figure %d - Gaussian sweep: %s [%s]', figNum, [name ext], status), ...
        'NumberTitle', 'off', 'Position', [0 0 1600 550]);

    % Col 1: original
    subplot(2, nVariants+1, 1);
    imshow(Ig);
    title(sprintf('Original\nMean: %.0f', mean(double(Ig(:)))), ...
        'FontSize', 8, 'Color', col);
    subplot(2, nVariants+1, nVariants+2);
    imhist(Ig); xlabel('Intensity', 'FontSize', 7); ylabel('Count', 'FontSize', 7);

    % Cols 2 to end: each sigma
    for k = 1:nVariants
        sg  = gaus_sigmas(k);
        I_f = imfilter(Ig, fspecial('gaussian', gaus_size, sg), 'replicate');

        subplot(2, nVariants+1, k+1);
        imshow(I_f);
        title(sprintf('Gaussian σ=%.1f\nMean: %.0f', sg, mean(double(I_f(:)))), ...
            'FontSize', 8);
        subplot(2, nVariants+1, k+nVariants+2);
        imhist(I_f); xlabel('Intensity', 'FontSize', 7); ylabel('Count', 'FontSize', 7);
    end

    sgtitle(sprintf('Figure %d — Gaussian sweep [%dx%d]: %s  [%s]', ...
        figNum, gaus_size(1), gaus_size(2), [name ext], status), ...
        'FontSize', 12, 'FontWeight', 'bold', 'Color', col);

    figNum = figNum + 1;

end

%% ----------------------------------------------------------
%  SECTION 3: MEDIAN FILTER — PARAMETER SWEEP
%  Varying kernel size: [3x3], [5x5], [7x7]
% -----------------------------------------------------------

med_sizes = {[3 3], [5 5], [7 7]};
nVariants = length(med_sizes);

for t = 1:length(test_idx)

    i  = test_idx(t);
    Ig = images_gray{i};
    [~, name, ext] = fileparts(filenames{i});

    if labels(i) == 0
        col = [0 0.5 0]; status = 'CLEAR';
    else
        col = [0.8 0 0]; status = 'OBSTRUCTED';
    end

    figure('Name', sprintf('Figure %d - Median sweep: %s [%s]', figNum, [name ext], status), ...
        'NumberTitle', 'off', 'Position', [0 0 1200 550]);

    % Col 1: original
    subplot(2, nVariants+1, 1);
    imshow(Ig);
    title(sprintf('Original\nMean: %.0f', mean(double(Ig(:)))), ...
        'FontSize', 8, 'Color', col);
    subplot(2, nVariants+1, nVariants+2);
    imhist(Ig); xlabel('Intensity', 'FontSize', 7); ylabel('Count', 'FontSize', 7);

    % Cols 2 to end: each kernel size
    for k = 1:nVariants
        sz  = med_sizes{k};
        I_f = medfilt2(Ig, sz);

        subplot(2, nVariants+1, k+1);
        imshow(I_f);
        title(sprintf('Median [%dx%d]\nMean: %.0f', sz(1), sz(2), mean(double(I_f(:)))), ...
            'FontSize', 8);
        subplot(2, nVariants+1, k+nVariants+2);
        imhist(I_f); xlabel('Intensity', 'FontSize', 7); ylabel('Count', 'FontSize', 7);
    end

    sgtitle(sprintf('Figure %d — Median sweep: %s  [%s]', figNum, [name ext], status), ...
        'FontSize', 12, 'FontWeight', 'bold', 'Color', col);

    figNum = figNum + 1;

end

%% ----------------------------------------------------------
%  SECTION 4: BILATERAL FILTER — PARAMETER SWEEP
%  Varying sigmaR (range): 0.05, 0.1, 0.2
%  Varying sigmaS (spatial): 2, 4  → grid of combinations
% -----------------------------------------------------------

bil_sigmaS_vals = [2, 4];
bil_sigmaR_vals = [0.05, 0.1, 0.2];
nCols = length(bil_sigmaR_vals);
nRows = length(bil_sigmaS_vals);

for t = 1:length(test_idx)

    i  = test_idx(t);
    Ig = images_gray{i};
    [~, name, ext] = fileparts(filenames{i});

    if labels(i) == 0
        col = [0 0.5 0]; status = 'CLEAR';
    else
        col = [0.8 0 0]; status = 'OBSTRUCTED';
    end

    figure('Name', sprintf('Figure %d - Bilateral sweep: %s [%s]', figNum, [name ext], status), ...
        'NumberTitle', 'off', 'Position', [0 0 1200 700]);

    for r = 1:nRows
        for c = 1:nCols
            sS  = bil_sigmaS_vals(r);
            sR  = bil_sigmaR_vals(c);
            I_f = uint8(imbilatfilt(double(Ig)./255, sR, sS) .* 255);

            subplot(nRows, nCols, (r-1)*nCols + c);
            imshow(I_f);
            title(sprintf('σS=%.0f  σR=%.2f\nMean: %.0f', sS, sR, mean(double(I_f(:)))), ...
                'FontSize', 8);
        end
    end

    sgtitle(sprintf('Figure %d — Bilateral sweep: %s  [%s]', figNum, [name ext], status), ...
        'FontSize', 12, 'FontWeight', 'bold', 'Color', col);

    figNum = figNum + 1;

end

%% ----------------------------------------------------------
%  SECTION 5: HIGH-PASS → SMOOTH PIPELINE
%  Hypothesis: HP accentuates obstacle texture, smoothing
%  consolidates it into detectable regions
% -----------------------------------------------------------

h_hp = fspecial('laplacian', 0);

smooth_filters = {
    'HP → Gaussian [5x5]',   @(I) imgaussfilt(I, 1);
    'HP → Gaussian [11x11]', @(I) imgaussfilt(I, 2);
    'HP → Median [5x5]',     @(I) medfilt2(I, [5 5]);
    'HP → Averaging [5x5]',  @(I) imfilter(I, fspecial('average', [5 5]), 'replicate');
};
nVariants = size(smooth_filters, 1);

for t = 1:length(test_idx)

    i  = test_idx(t);
    Ig = images_gray{i};
    [~, name, ext] = fileparts(filenames{i});

    if labels(i) == 0
        col = [0 0.5 0]; status = 'CLEAR';
    else
        col = [0.8 0 0]; status = 'OBSTRUCTED';
    end

    I_hp = imsubtract(Ig, imfilter(Ig, h_hp));

    figure('Name', sprintf('Figure %d - HP→Smooth: %s [%s]', figNum, [name ext], status), ...
        'NumberTitle', 'off', 'Position', [0 0 1400 550]);

    % Col 1: original
    subplot(2, nVariants+2, 1);
    imshow(Ig);
    title(sprintf('Original\nMean: %.0f', mean(double(Ig(:)))), ...
        'FontSize', 8, 'Color', col);
    subplot(2, nVariants+2, nVariants+3);
    imhist(Ig); xlabel('Intensity', 'FontSize', 7); ylabel('Count', 'FontSize', 7);

    % Col 2: high-pass alone
    subplot(2, nVariants+2, 2);
    imshow(I_hp);
    title(sprintf('High-pass\nMean: %.0f', mean(double(I_hp(:)))), ...
        'FontSize', 8, 'Color', [0.5 0 0.5]);
    subplot(2, nVariants+2, nVariants+4);
    imhist(I_hp); xlabel('Intensity', 'FontSize', 7); ylabel('Count', 'FontSize', 7);

    % Cols 3 to end: HP → each smoother
    for k = 1:nVariants
        fn    = smooth_filters{k, 1};
        sfun  = smooth_filters{k, 2};
        I_out = sfun(I_hp);

        subplot(2, nVariants+2, k+2);
        imshow(I_out);
        title(sprintf('%s\nMean: %.0f', fn, mean(double(I_out(:)))), ...
            'FontSize', 8);
        subplot(2, nVariants+2, k+nVariants+4);
        imhist(I_out); xlabel('Intensity', 'FontSize', 7); ylabel('Count', 'FontSize', 7);
    end

    sgtitle(sprintf('Figure %d — HP → Smooth pipeline: %s  [%s]', figNum, [name ext], status), ...
        'FontSize', 12, 'FontWeight', 'bold', 'Color', col);

    figNum = figNum + 1;

end

%% ----------------------------------------------------------
%  SECTION 6: QUANTITATIVE SUMMARY TABLE
%
%  Best single variant per filter (chosen after visual inspection)
%  vs original — Mean, Std, Edge density, SSIM
%
%  Update the parameters below after running sections 1-5
%  and deciding which variants look best on your images.
% -----------------------------------------------------------

% --- Set your chosen best parameters here ---
best_avg_size   = [5 5];
best_gaus_sigma = 1;
best_gaus_size  = [11 11];
best_med_size   = [5 5];
best_bil_sigmaS = 2;
best_bil_sigmaR = 0.05;

filter_names_q = {
    'Original', ...
    sprintf('Averaging [%dx%d]',           best_avg_size(1),   best_avg_size(2)), ...
    sprintf('Gaussian [%dx%d σ=%.1f]',     best_gaus_size(1),  best_gaus_size(2), best_gaus_sigma), ...
    sprintf('Median [%dx%d]',              best_med_size(1),   best_med_size(2)), ...
    sprintf('Bilateral [σS=%.0f σR=%.2f]', best_bil_sigmaS,    best_bil_sigmaR), ...
    'High-pass (sharpen)' ...
};

fprintf('\n%s\n', repmat('=', 1, 90));
fprintf('PHASE 2 — QUANTITATIVE COMPARISON (best variants)\n');
fprintf('%s\n', repmat('=', 1, 90));

for t = 1:length(test_idx)

    i  = test_idx(t);
    Ig = images_gray{i};
    [~, name, ext] = fileparts(filenames{i});

    if labels(i) == 0; status = 'CLEAR'; else; status = 'OBSTRUCTED'; end

    I_avg = imfilter(Ig, fspecial('average',  best_avg_size), 'replicate');
    I_gau = imfilter(Ig, fspecial('gaussian', best_gaus_size, best_gaus_sigma), 'replicate');
    I_med = medfilt2(Ig, best_med_size);
    I_bil = uint8(imbilatfilt(double(Ig)./255, best_bil_sigmaR, best_bil_sigmaS) .* 255);
    I_hp  = imsubtract(Ig, imfilter(Ig, fspecial('laplacian', 0)));

    filter_imgs_q = {Ig, I_avg, I_gau, I_med, I_bil, I_hp};

    fprintf('\n[%d] %s  [%s]\n', i, [name ext], status);
    fprintf('  %-38s | %6s | %6s | %10s | %6s\n', ...
        'Filter', 'Mean', 'Std', 'Edge dens.', 'SSIM');
    fprintf('  %s\n', repmat('-', 1, 74));

    for k = 1:6
        Ik    = filter_imgs_q{k};
        mn    = mean(double(Ik(:)));
        sd    = std(double(Ik(:)));
        edens = sum(sum(edge(Ik, 'Canny'))) / numel(Ik) * 100;
        sv    = 1.0;
        if k > 1; sv = ssim(Ik, Ig); end
        fprintf('  %-38s | %6.1f | %6.1f | %9.2f%% | %6.4f\n', ...
            filter_names_q{k}, mn, sd, edens, sv);
    end

end

fprintf('\n%s\n', repmat('=', 1, 90));

%% ----------------------------------------------------------
%  SECTION 7: SAVE WORKSPACE
% -----------------------------------------------------------

save('./Output/workspace_phase2.mat', ...
    'images', 'images_gray', 'filenames', ...
    'labels', 'descriptions', 'N', ...
    'best_avg_size', 'best_gaus_sigma', 'best_gaus_size', ...
    'best_med_size', 'best_bil_sigmaS', 'best_bil_sigmaR');

fprintf('\nWorkspace saved to ./Output/workspace_phase2.mat\n');