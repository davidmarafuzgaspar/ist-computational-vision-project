% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 2 - Preprocessing: Histogram Equalisation and
%            Gaussian Smoothing
%
%  Authors:
%   - David Marafuz Gaspar - 106541
%   - Pedro Gaspar Mónico - 106626
%
% ============================================================
clear; clc; close all;
load('./Output/workspace_phase1.mat');
disp('Workspace from Phase 1 loaded');

%% Live Script Comment
% Prior to edge detection, two preprocessing steps are applied to each
% grayscale image. First, histogram equalisation redistributes the pixel
% intensity distribution to span the full dynamic range, improving
% contrast uniformity across the dataset — particularly beneficial for
% low-illumination images such as tunnel scenes. Second, a Gaussian filter
% is applied to attenuate high-frequency details that would otherwise
% produce spurious responses during the edge detection phase. Together,
% these steps condition the image to yield cleaner, more representative
% edge maps in the subsequent stage.

%% ----------------------------------------------------------
%  SECTION 1: HISTOGRAM EQUALISATION
% -----------------------------------------------------------

images_eq = cell(N, 1);
for i = 1:N
    images_eq{i} = histeq(images_gray{i});
end

% --- Figure: Grayscale vs Equalised + Histograms ---
for f = 1:3
    figure('Name', sprintf('Figure %d - Histogram Equalisation (%d to %d)', ...
        f+5, (f-1)*5+1, f*5), ...
        'NumberTitle', 'off', ...
        'Position', [0, 0, 1400, 900]);

    for k = 1:5
        i = (f-1)*5 + k;
        [~, name, ext] = fileparts(filenames{i});

        if labels(i) == 0
            col    = [0 0.5 0];
            status = 'CLEAR';
        else
            col    = [0.8 0 0];
            status = 'OBSTRUCTED';
        end

        % Original grayscale
        subplot(5, 4, (k-1)*4 + 1);
        imshow(images_gray{i});
        title(sprintf('[%d] %s — %s', i, [name ext], status), ...
            'FontSize', 7, 'Color', col, 'Interpreter', 'none');

        % Original histogram
        subplot(5, 4, (k-1)*4 + 2);
        imhist(images_gray{i});
        title(sprintf('Original  |  Mean: %.0f', ...
            mean(double(images_gray{i}(:)))), ...
            'FontSize', 7, 'Color', col);
        xlabel('Intensity', 'FontSize', 6);
        ylabel('Count',     'FontSize', 6);

        % Equalised image
        subplot(5, 4, (k-1)*4 + 3);
        imshow(images_eq{i});
        title('Equalised', 'FontSize', 7, 'Color', col);

        % Equalised histogram
        subplot(5, 4, (k-1)*4 + 4);
        imhist(images_eq{i});
        title(sprintf('Equalised  |  Mean: %.0f', ...
            mean(double(images_eq{i}(:)))), ...
            'FontSize', 7, 'Color', col);
        xlabel('Intensity', 'FontSize', 6);
        ylabel('Count',     'FontSize', 6);
    end

    sgtitle(sprintf('Figure %d — Histogram Equalisation: Images %d to %d  (green = clear  |  red = obstructed)', ...
        f+5, (f-1)*5+1, f*5), ...
        'FontSize', 12, 'FontWeight', 'bold');
end

%% Live Script Comment
% Following histogram equalisation, a Gaussian filter is applied to each
% image. The standard deviation sigma controls the trade-off between noise
% suppression and edge preservation — a value of 1.5 was selected as it
% attenuates high-frequency texture noise while retaining the dominant
% structural boundaries corresponding to the rails and sleepers.

%% ----------------------------------------------------------
%  SECTION 2: GAUSSIAN SMOOTHING
% -----------------------------------------------------------

% Standard deviation of the Gaussian kernel.
% Higher values suppress more noise but risk blurring genuine rail edges.
gauss_sigma = 1.25;

images_smooth = cell(N, 1);
for i = 1:N
    images_smooth{i} = imgaussfilt(images_eq{i}, gauss_sigma);
end

% --- Figure: Equalised vs Smoothed Grid ---
figure('Name', 'Figure 9 - Gaussian Smoothing', ...
    'NumberTitle', 'off', ...
    'Position', [0, 0, 1500, 900]);

for i = 1:N
    subplot(3, 5, i);
    imshow(images_smooth{i});

    if labels(i) == 0
        col = [0 0.5 0];
    else
        col = [0.8 0 0];
    end

    [~, name, ext] = fileparts(filenames{i});
    title(sprintf('[%d] %s\n%s', i, [name ext], descriptions{i}), ...
        'FontSize', 7, 'Color', col, 'Interpreter', 'none');
end

sgtitle('Figure 9 — Gaussian Smoothed Images  (green = clear  |  red = obstructed)', ...
    'FontSize', 13, 'FontWeight', 'bold');

%% ----------------------------------------------------------
%  SECTION 3: SAVE WORKSPACE
% -----------------------------------------------------------
save('./Output/workspace_phase2.mat', ...
    'images', 'images_gray', 'images_eq', 'images_smooth', ...
    'filenames', 'labels', 'descriptions', 'N');
fprintf('\nWorkspace saved to ./Output/workspace_phase2.mat\n');