%% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 3 - Image Enhancement
%
%% ============================================================
clear; clc; close all;
load('./Output/workspace_phase2.mat');
disp('Workspace from Phase 2 loaded');

%% ----------------------------------------------------------
%  CONFIGURATION
%  Same representative pair as Phase 2 plus tunnel image.
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

idx_outdoor = 4;    % clear outdoor image      (straight/curved)
idx_tunnel  = 10;   % clear tunnel image        (dark, uneven light)
idx_obstr   = 12;   % obstructed image          (rocks)

test_idx = [idx_outdoor, idx_tunnel, idx_obstr];

figNum = 20;   % <-- adjust to continue after your last Phase 2 figure

%% ----------------------------------------------------------
%  SECTION 1: CONTRAST STRETCHING — imadjust SWEEP
%  Varying the output range: how aggressively we stretch
%  [low_in high_in] → [0 1]
%  Narrow input range = more aggressive stretch
% -----------------------------------------------------------

adj_ranges = [
    0.10, 0.90;
    0.20, 0.80;
    0.30, 0.70;
    0.40, 0.60;
];
nVariants = size(adj_ranges, 1);

for t = 1:length(test_idx)

    i  = test_idx(t);
    Ig = images_gray{i};
    [~, name, ext] = fileparts(filenames{i});

    if labels(i) == 0
        col = [0 0.5 0]; status = 'CLEAR';
    else
        col = [0.8 0 0]; status = 'OBSTRUCTED';
    end

    figure('Name', sprintf('Figure %d - imadjust sweep: %s [%s]', figNum, [name ext], status), ...
        'NumberTitle', 'off', 'Position', [0 0 1400 550]);

    plot_col(Ig, 'Original', 1, nVariants+1, col);

    for k = 1:nVariants
        lo  = adj_ranges(k,1);
        hi  = adj_ranges(k,2);
        I_f = imadjust(Ig, [lo hi], []);
        lbl = sprintf('imadjust [%.2f %.2f]', lo, hi);
        plot_col(I_f, lbl, k+1, nVariants+1, []);
    end

    sgtitle(sprintf('Figure %d — Contrast stretch (imadjust) sweep: %s  [%s]', ...
        figNum, [name ext], status), ...
        'FontSize', 12, 'FontWeight', 'bold', 'Color', col);

    figNum = figNum + 1;

end

%% ----------------------------------------------------------
%  SECTION 2: HISTOGRAM EQUALISATION — histeq
%  No parameters to sweep — compare across all test images
% -----------------------------------------------------------

figure('Name', sprintf('Figure %d - histeq: all test images', figNum), ...
    'NumberTitle', 'off', 'Position', [0 0 1400 700]);

ncols = length(test_idx);

for t = 1:ncols

    i  = test_idx(t);
    Ig = images_gray{i};
    [~, name, ext] = fileparts(filenames{i});

    if labels(i) == 0
        col = [0 0.5 0]; status = 'CLEAR';
    else
        col = [0.8 0 0]; status = 'OBSTRUCTED';
    end

    I_heq = histeq(Ig);

    subplot(4, ncols, t);
    imshow(Ig);
    title(sprintf('[%d] %s\nOriginal — Mean: %.0f', i, [name ext], mean(double(Ig(:)))), ...
        'FontSize', 8, 'Color', col, 'Interpreter', 'none');

    subplot(4, ncols, t + ncols);
    imhist(Ig);
    xlabel('Intensity', 'FontSize', 7); ylabel('Count', 'FontSize', 7);

    subplot(4, ncols, t + 2*ncols);
    imshow(I_heq);
    title(sprintf('histeq — Mean: %.0f', mean(double(I_heq(:)))), 'FontSize', 8);

    subplot(4, ncols, t + 3*ncols);
    imhist(I_heq);
    xlabel('Intensity', 'FontSize', 7); ylabel('Count', 'FontSize', 7);

end

sgtitle(sprintf('Figure %d — Histogram equalisation (histeq)', figNum), ...
    'FontSize', 12, 'FontWeight', 'bold');

figNum = figNum + 1;

%% ----------------------------------------------------------
%  SECTION 3: CLAHE — adapthisteq SWEEP
%  Varying NumTiles: larger tiles = more global correction
%  Particularly effective on tunnel/mixed-light images
% -----------------------------------------------------------

clahe_tiles = {[2 2], [4 4], [8 8], [16 16]};
clahe_clip  = 0.01;   % ClipLimit (try 0.005, 0.02, 0.05)
nVariants   = length(clahe_tiles);

for t = 1:length(test_idx)

    i  = test_idx(t);
    Ig = images_gray{i};
    [~, name, ext] = fileparts(filenames{i});

    if labels(i) == 0
        col = [0 0.5 0]; status = 'CLEAR';
    else
        col = [0.8 0 0]; status = 'OBSTRUCTED';
    end

    figure('Name', sprintf('Figure %d - CLAHE sweep: %s [%s]', figNum, [name ext], status), ...
        'NumberTitle', 'off', 'Position', [0 0 1400 550]);

    plot_col(Ig, 'Original', 1, nVariants+1, col);

    for k = 1:nVariants
        tiles = clahe_tiles{k};
        I_f   = adapthisteq(Ig, 'NumTiles', tiles, 'ClipLimit', clahe_clip);
        lbl   = sprintf('CLAHE [%dx%d tiles]', tiles(1), tiles(2));
        plot_col(I_f, lbl, k+1, nVariants+1, []);
    end

    sgtitle(sprintf('Figure %d — CLAHE sweep (ClipLimit=%.3f): %s  [%s]', ...
        figNum, clahe_clip, [name ext], status), ...
        'FontSize', 12, 'FontWeight', 'bold', 'Color', col);

    figNum = figNum + 1;

end

%% ----------------------------------------------------------
%  SECTION 4: GAMMA CORRECTION — imadjust with gamma SWEEP
%  gamma < 1 → brightens (useful for tunnels)
%  gamma > 1 → darkens
%  gamma = 1 → no change (linear)
% -----------------------------------------------------------

gamma_vals = [0.3, 0.5, 0.7, 1.0, 1.5, 2.0];
nVariants  = length(gamma_vals);

for t = 1:length(test_idx)

    i  = test_idx(t);
    Ig = images_gray{i};
    [~, name, ext] = fileparts(filenames{i});

    if labels(i) == 0
        col = [0 0.5 0]; status = 'CLEAR';
    else
        col = [0.8 0 0]; status = 'OBSTRUCTED';
    end

    figure('Name', sprintf('Figure %d - Gamma sweep: %s [%s]', figNum, [name ext], status), ...
        'NumberTitle', 'off', 'Position', [0 0 1600 550]);

    plot_col(Ig, 'Original', 1, nVariants+1, col);

    for k = 1:nVariants
        g   = gamma_vals(k);
        I_f = imadjust(Ig, [], [], g);
        if g == 1.0
            lbl = sprintf('Gamma=%.1f (linear)', g);
        elseif g < 1
            lbl = sprintf('Gamma=%.1f (brighter)', g);
        else
            lbl = sprintf('Gamma=%.1f (darker)', g);
        end
        plot_col(I_f, lbl, k+1, nVariants+1, []);
    end

    sgtitle(sprintf('Figure %d — Gamma correction sweep: %s  [%s]', ...
        figNum, [name ext], status), ...
        'FontSize', 12, 'FontWeight', 'bold', 'Color', col);

    figNum = figNum + 1;

end

%% ----------------------------------------------------------
%  SECTION 5: TOP-HAT FILTER — imtophat SWEEP
%  Extracts bright structures smaller than the SE.
%  A wide linear SE isolates rail-like elongated features.
% -----------------------------------------------------------

tophat_SEs = {
    strel('line', 20,  0),  '20px horiz.';
    strel('line', 40,  0),  '40px horiz.';
    strel('line', 20, 45),  '20px diag.';
    strel('disk',  5,  0),  'disk r=5';
};
nVariants = size(tophat_SEs, 1);

for t = 1:length(test_idx)

    i  = test_idx(t);
    Ig = images_gray{i};
    [~, name, ext] = fileparts(filenames{i});

    if labels(i) == 0
        col = [0 0.5 0]; status = 'CLEAR';
    else
        col = [0.8 0 0]; status = 'OBSTRUCTED';
    end

    figure('Name', sprintf('Figure %d - Top-hat sweep: %s [%s]', figNum, [name ext], status), ...
        'NumberTitle', 'off', 'Position', [0 0 1400 550]);

    plot_col(Ig, 'Original', 1, nVariants+1, col);

    for k = 1:nVariants
        se  = tophat_SEs{k, 1};
        lbl = sprintf('Top-hat [%s]', tophat_SEs{k, 2});
        I_f = imtophat(Ig, se);
        plot_col(I_f, lbl, k+1, nVariants+1, []);
    end

    sgtitle(sprintf('Figure %d — Top-hat filter sweep: %s  [%s]', ...
        figNum, [name ext], status), ...
        'FontSize', 12, 'FontWeight', 'bold', 'Color', col);

    figNum = figNum + 1;

end

%% ----------------------------------------------------------
%  SECTION 6: SHARPENING — imsharpen SWEEP
%  Amount: strength of sharpening
%  Radius: size of the unsharp mask region
%  Threshold: ignores low-contrast edges (noise robust)
% -----------------------------------------------------------

% [Amount, Radius, Threshold]
sharp_params = [
    0.5, 1, 0.0;
    1.0, 1, 0.0;
    2.0, 1, 0.0;
    1.0, 2, 0.0;
    1.0, 1, 0.1;
];
nVariants = size(sharp_params, 1);

for t = 1:length(test_idx)

    i  = test_idx(t);
    Ig = images_gray{i};
    [~, name, ext] = fileparts(filenames{i});

    if labels(i) == 0
        col = [0 0.5 0]; status = 'CLEAR';
    else
        col = [0.8 0 0]; status = 'OBSTRUCTED';
    end

    figure('Name', sprintf('Figure %d - Sharpening sweep: %s [%s]', figNum, [name ext], status), ...
        'NumberTitle', 'off', 'Position', [0 0 1600 550]);

    plot_col(Ig, 'Original', 1, nVariants+1, col);

    for k = 1:nVariants
        am  = sharp_params(k,1);
        ra  = sharp_params(k,2);
        th  = sharp_params(k,3);
        I_f = imsharpen(Ig, 'Amount', am, 'Radius', ra, 'Threshold', th);
        lbl = sprintf('A=%.1f R=%.0f T=%.1f', am, ra, th);
        plot_col(I_f, lbl, k+1, nVariants+1, []);
    end

    sgtitle(sprintf('Figure %d — Sharpening (imsharpen) sweep: %s  [%s]', ...
        figNum, [name ext], status), ...
        'FontSize', 12, 'FontWeight', 'bold', 'Color', col);

    figNum = figNum + 1;

end

%% ----------------------------------------------------------
%  SECTION 7: QUANTITATIVE SUMMARY TABLE
%
%  Update best_* variables after visual inspection of
%  sections 1-6, then re-run this section alone.
% -----------------------------------------------------------

best_adj_range   = [0.20, 0.80];
best_clahe_tiles = [8 8];
best_clahe_clip  = 0.01;
best_gamma       = 0.5;
best_tophat_se   = strel('line', 40, 0);
best_sharp_am    = 1.0;
best_sharp_ra    = 1;
best_sharp_th    = 0;

enh_names = {
    'Original', ...
    sprintf('imadjust [%.2f %.2f]',    best_adj_range(1), best_adj_range(2)), ...
    'histeq', ...
    sprintf('CLAHE [%dx%d tiles]',     best_clahe_tiles(1), best_clahe_tiles(2)), ...
    sprintf('Gamma=%.1f',              best_gamma), ...
    'Top-hat [40px horiz.]', ...
    sprintf('imsharpen A=%.1f R=%.0f', best_sharp_am, best_sharp_ra) ...
};

fprintf('\n%s\n', repmat('=', 1, 90));
fprintf('PHASE 3 — QUANTITATIVE ENHANCEMENT COMPARISON (best variants)\n');
fprintf('%s\n', repmat('=', 1, 90));

for t = 1:length(test_idx)

    i  = test_idx(t);
    Ig = images_gray{i};
    [~, name, ext] = fileparts(filenames{i});

    if labels(i) == 0; status = 'CLEAR'; else; status = 'OBSTRUCTED'; end

    I_adj   = imadjust(Ig, best_adj_range, []);
    I_heq   = histeq(Ig);
    I_clahe = adapthisteq(Ig, 'NumTiles', best_clahe_tiles, 'ClipLimit', best_clahe_clip);
    I_gam   = imadjust(Ig, [], [], best_gamma);
    I_top   = imtophat(Ig, best_tophat_se);
    I_sharp = imsharpen(Ig, 'Amount', best_sharp_am, 'Radius', best_sharp_ra, 'Threshold', best_sharp_th);

    enh_imgs = {Ig, I_adj, I_heq, I_clahe, I_gam, I_top, I_sharp};

    fprintf('\n[%d] %s  [%s]\n', i, [name ext], status);
    fprintf('  %-38s | %6s | %6s | %10s | %6s\n', ...
        'Technique', 'Mean', 'Std', 'Edge dens.', 'SSIM');
    fprintf('  %s\n', repmat('-', 1, 74));

    for k = 1:length(enh_imgs)
        Ik    = enh_imgs{k};
        mn    = mean(double(Ik(:)));
        sd    = std(double(Ik(:)));
        edens = sum(sum(edge(Ik, 'Canny'))) / numel(Ik) * 100;
        sv    = 1.0;
        if k > 1; sv = ssim(Ik, Ig); end
        fprintf('  %-38s | %6.1f | %6.1f | %9.2f%% | %6.4f\n', ...
            enh_names{k}, mn, sd, edens, sv);
    end

end

fprintf('\n%s\n', repmat('=', 1, 90));

%% ----------------------------------------------------------
%  SECTION 8: SAVE WORKSPACE
% -----------------------------------------------------------

save('./Output/workspace_phase3.mat', ...
    'images', 'images_gray', 'filenames', ...
    'labels', 'descriptions', 'N', ...
    'best_adj_range', 'best_clahe_tiles', 'best_clahe_clip', ...
    'best_gamma', 'best_tophat_se', 'best_sharp_am', ...
    'best_sharp_ra', 'best_sharp_th');

fprintf('\nWorkspace saved to ./Output/workspace_phase3.mat\n');

%% ----------------------------------------------------------
%  LOCAL FUNCTIONS
% -----------------------------------------------------------

function plot_col(Ik, col_title, col_idx, ncols, title_col)
    subplot(2, ncols, col_idx);
    imshow(Ik);
    if isempty(title_col)
        title(sprintf('%s\nMean: %.0f  Std: %.0f', ...
            col_title, mean(double(Ik(:))), std(double(Ik(:)))), ...
            'FontSize', 8);
    else
        title(sprintf('%s\nMean: %.0f  Std: %.0f', ...
            col_title, mean(double(Ik(:))), std(double(Ik(:)))), ...
            'FontSize', 8, 'Color', title_col);
    end
    subplot(2, ncols, col_idx + ncols);
    imhist(Ik);
    xlabel('Intensity', 'FontSize', 7);
    ylabel('Count',     'FontSize', 7);
    set(gca, 'FontSize', 7);
end