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
%  SECTION 1: APPLY AND VISUALIZE FILTERS
%  2 rows x 5 cols: image on top, histogram on bottom
%  Tested on one clear and one obstructed image
% -----------------------------------------------------------

test_idx = [4, 12];   % Frame1532 (clear), j30 (obstructed)

for t = 1:length(test_idx)

    i  = test_idx(t);
    Ig = images_gray{i};

    [~, name, ext] = fileparts(filenames{i});

    if labels(i) == 0
        col    = [0 0.5 0];
        status = 'CLEAR';
    else
        col    = [0.8 0 0];
        status = 'OBSTRUCTED';
    end

    % --- Compute filters ---
    h_avg  = fspecial('average',  [5 5]);
    h_gaus = fspecial('gaussian', [5 5], 1);
    h_hp   = fspecial('laplacian', 0);

    I_avg  = imfilter(Ig, h_avg);
    I_gaus = imfilter(Ig, h_gaus);
    I_med  = medfilt2(Ig, [5 5]);
    I_hp   = imsubtract(Ig, imfilter(Ig, h_hp));

    filter_images  = {Ig,        I_avg,      I_gaus,         I_med,      I_hp};
    filter_names   = {'Original', 'Averaging [5x5]', 'Gaussian [5x5 σ=1]', 'Median [5x5]', 'High Pass'};

    % --- Plot ---
    figure('Name', sprintf('Figure - Filters: %s [%s]', [name ext], status), ...
        'NumberTitle', 'off', ...
        'Position', [0, 0, 1400, 600]);

    for k = 1:5

        Ik = filter_images{k};

        % Image on top row
        subplot(2, 5, k);
        imshow(Ik);
        if k == 1
            title(sprintf('%s\nMean: %.0f', filter_names{k}, mean(double(Ik(:)))), ...
                'FontSize', 9, 'Color', col);
        else
            title(sprintf('%s\nMean: %.0f', filter_names{k}, mean(double(Ik(:)))), ...
                'FontSize', 9);
        end

        % Histogram on bottom row
        subplot(2, 5, k+5);
        imhist(Ik);
        xlabel('Intensity', 'FontSize', 7);
        ylabel('Count',     'FontSize', 7);

    end

    sgtitle(sprintf('Figure — Spatial Filters: %s  [%s]', [name ext], status), ...
        'FontSize', 12, 'FontWeight', 'bold', 'Color', col);

end

%% ----------------------------------------------------------
%  SECTION 3: HIGH-PASS → SMOOTH PIPELINE
%  Hypothesis: HP accentuates obstacle texture, smoothing
%  consolidates it into detectable regions
% -----------------------------------------------------------
test_idx = [4, 12];   % Frame1532 (clear), j30 (obstructed)

smooth_filters = {
    'HP → Gaussian 5x5',  @(I) imgaussfilt(I, 1);
    'HP → Gaussian 11x11', @(I) imgaussfilt(I, 2);
    'HP → Median 5x5',    @(I) medfilt2(I, [5 5]);
    'HP → Averaging 5x5', @(I) imfilter(I, fspecial('average', [5 5]));
};

h_lap = fspecial('laplacian', 0);

for t = 1:length(test_idx)
    i  = test_idx(t);
    Ig = images_gray{i};
    [~, name, ext] = fileparts(filenames{i});

    if labels(i) == 0
        col = [0 0.5 0]; status = 'CLEAR';
    else
        col = [0.8 0 0]; status = 'OBSTRUCTED';
    end

    % Step 1: high-pass
    I_hp = imsubtract(Ig, imfilter(Ig, h_lap));

    figure('Name', sprintf('HP→Smooth: %s [%s]', [name ext], status), ...
        'NumberTitle', 'off', 'Position', [0 0 1400 700]);

    % Col 1: original
    subplot(2, 5, 1);  imshow(Ig);
    title(sprintf('Original\nMean: %.0f', mean(double(Ig(:)))), ...
        'FontSize', 8, 'Color', col);
    subplot(2, 5, 6);  imhist(Ig);
    ylabel('Count', 'FontSize', 7);

    % Col 2: high-pass alone
    subplot(2, 5, 2);  imshow(I_hp);
    title(sprintf('High-pass\nMean: %.0f', mean(double(I_hp(:)))), ...
        'FontSize', 8, 'Color', [0.5 0 0.5]);
    subplot(2, 5, 7);  imhist(I_hp);
    ylabel('Count', 'FontSize', 7);

    % Cols 3-5: HP → each smoother
    for k = 1:3
        fn   = smooth_filters{k, 1};
        sfun = smooth_filters{k, 2};
        I_out = sfun(I_hp);

        subplot(2, 5, k+2);
        imshow(I_out);
        title(sprintf('%s\nMean: %.0f', fn, mean(double(I_out(:)))), ...
            'FontSize', 8);
        subplot(2, 5, k+7);
        imhist(I_out);
        ylabel('Count', 'FontSize', 7);
    end

    sgtitle(sprintf('HP → Smooth pipeline: %s  [%s]', [name ext], status), ...
        'FontSize', 12, 'FontWeight', 'bold', 'Color', col);
end

%% --- Quantitative comparison: std of HP response inside ROI ---
% A clear track should have LOW std (uniform ballast texture)
% An obstructed track should have HIGH std (irregular rocks)
fprintf('\n%-30s | %-10s | %-10s | %-10s\n', ...
    'Image', 'Mean(HP)', 'Std(HP)', 'Label');
fprintf('%s\n', repmat('-', 1, 65));
for i = 1:N
    Ig   = images_gray{i};
    I_hp = imsubtract(Ig, imfilter(Ig, h_lap));
    [~, name, ext] = fileparts(filenames{i});
    lbl  = {'CLEAR','OBSTRUCTED'};
    fprintf('%-30s | %-10.1f | %-10.1f | %s\n', ...
        [name ext], mean(double(I_hp(:))), std(double(I_hp(:))), lbl{labels(i)+1});
end