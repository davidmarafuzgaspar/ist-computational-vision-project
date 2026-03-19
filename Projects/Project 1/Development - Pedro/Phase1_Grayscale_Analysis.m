%% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 1 - Dataset Analysis
%
%% ============================================================
clear; clc; close all;
load('./Output/workspace_phase0.mat');
disp('Workspace from Phase 0 loaded');

%% ----------------------------------------------------------
%  SECTION 1: GRAYSCALE CONVERSION
% -----------------------------------------------------------

images_gray = cell(N, 1);
for i = 1:N
    images_gray{i} = rgb2gray(images{i});
end

figure('Name', 'Figure 2 - Grayscale Images', ...
    'NumberTitle', 'off', ...
    'Position', [0, 0, 1500, 900]);

for i = 1:N
    subplot(3, 5, i);
    imshow(images_gray{i});

    if labels(i) == 0
        col = [0 0.5 0];
    else
        col = [0.8 0 0];
    end

    [~, name, ext] = fileparts(filenames{i});
    title(sprintf('[%d] %s\n%s', i, [name ext], descriptions{i}), ...
        'FontSize', 7, 'Color', col, 'Interpreter', 'none');
end

sgtitle('Figure 2 — Grayscale Images  (green = clear  |  red = obstructed)', ...
    'FontSize', 13, 'FontWeight', 'bold');

%% ----------------------------------------------------------
%  SECTION 2: IMAGES AND HISTOGRAMS 
% -----------------------------------------------------------

for f = 1:3
    figure('Name', sprintf('Figure %d - Images and Histograms (%d to %d)', ...
        f+2, (f-1)*5+1, f*5), ...
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

        subplot(5, 2, (k-1)*2 + 1);
        imshow(images_gray{i});
        title(sprintf('[%d] %s  —  %s', i, [name ext], status), ...
            'FontSize', 8, 'Color', col, 'Interpreter', 'none');

        subplot(5, 2, (k-1)*2 + 2);
        imhist(images_gray{i});
        title(sprintf('Mean: %.0f', mean(double(images_gray{i}(:)))), ...
    'FontSize', 8, 'Color', col);
        xlabel('Intensity', 'FontSize', 7);
        ylabel('Count',     'FontSize', 7);
    end

    sgtitle(sprintf('Figure %d — Images %d to %d  (green = clear  |  red = obstructed)', ...
        f+2, (f-1)*5+1, f*5), ...
        'FontSize', 12, 'FontWeight', 'bold');
end

%% ----------------------------------------------------------
%  SECTION 3: SAVE WORKSPACE
% -----------------------------------------------------------

save('./Output/workspace_phase1.mat', ...
    'images', 'images_gray', 'filenames', ...
    'labels', 'descriptions', 'N');

fprintf('\nWorkspace saved to ./Output/workspace_phase1.mat\n');