%% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 2 - Gaussian / DoG / Unsharp Mask Comparison (after CLAHE)
%
%  Process all images, display only selected 5.
%% ============================================================

clear; clc; close all;

% Load previous workspace
load('./Output/workspace_phase2.mat');
disp('Workspace from Phase 2 loaded');

%% ----------------------------------------------------------
%  PARAMETERS
% -----------------------------------------------------------
SIGMAS   = [1];           % sigma for Gaussian/DoG/Unsharp
SELECTED = [2, 10, 1, 13, 4]; % images to display only
N_all    = N;             % total number of images

% Preallocate storage for processed images
images_gauss = cell(N_all, length(SIGMAS));
images_dog   = cell(N_all, length(SIGMAS));
images_us    = cell(N_all, length(SIGMAS));

%% ----------------------------------------------------------
%  PROCESS ALL IMAGES
% ----------------------------------------------------------
for i = 1:N_all
    img = images_clahe{i};

    for s = 1:length(SIGMAS)
        sigma = SIGMAS(s);

        % Gaussian
        img_g = imgaussfilt(img, sigma);
        images_gauss{i,s} = img_g;

        % DoG (input is Gaussian-smoothed img_g)
        img_g2 = imgaussfilt(img, sigma*1.6);
        img_dog = imsubtract(img_g2, img_g);
        images_dog{i,s} = mat2gray(img_dog);

        % Unsharp Mask (input is Gaussian-smoothed img_g)
        img_us = imsharpen(img_g, 'Radius', sigma, 'Amount', 1);
        images_us{i,s} = img_us;
    end
end

%% ----------------------------------------------------------
%  DISPLAY ONLY SELECTED IMAGES
% ----------------------------------------------------------
TOTAL_COLS = 1 + length(SIGMAS)*3;  % CLAHE + (Gaussian + DoG + Unsharp)

figure('Name', 'Phase 2 - CLAHE / Gaussian / DoG / Unsharp', ...
       'NumberTitle', 'off', 'Position', [0,0,TOTAL_COLS*200,length(SELECTED)*200]);

for row_disp = 1:length(SELECTED)
    i = SELECTED(row_disp);  % original index
    img = images_clahe{i};

    % Title color
    if labels(i) == 0
        col = [0 0.5 0]; status = 'CLEAR';
    else
        col = [0.8 0 0]; status = 'OBSTRUCTED';
    end

    [~, name, ext] = fileparts(filenames{i});
    base_title = sprintf('[%d] %s — %s', i, [name ext], status);

    col_idx = 1;

    % CLAHE input
    subplot(length(SELECTED), TOTAL_COLS, (row_disp-1)*TOTAL_COLS + col_idx);
    imshow(img);
    title(sprintf('%s\nCLAHE', base_title), 'FontSize', 8, 'Color', col, 'Interpreter', 'none');
    col_idx = col_idx + 1;

    % Gaussian / DoG / Unsharp
    for s = 1:length(SIGMAS)
        % Gaussian
        subplot(length(SELECTED), TOTAL_COLS, (row_disp-1)*TOTAL_COLS + col_idx);
        imshow(images_gauss{i,s});
        title(sprintf('G \\sigma=%.1f', SIGMAS(s)), 'FontSize', 8);
        col_idx = col_idx + 1;

        % DoG
        subplot(length(SELECTED), TOTAL_COLS, (row_disp-1)*TOTAL_COLS + col_idx);
        imshow(images_dog{i,s});
        title(sprintf('DoG \\sigma=%.1f', SIGMAS(s)), 'FontSize', 8);
        col_idx = col_idx + 1;

        % Unsharp
        subplot(length(SELECTED), TOTAL_COLS, (row_disp-1)*TOTAL_COLS + col_idx);
        imshow(images_us{i,s});
        title(sprintf('US \\sigma=%.1f', SIGMAS(s)), 'FontSize', 8);
        col_idx = col_idx + 1;
    end
end

sgtitle('Phase 2 — CLAHE | Gaussian | DoG | Unsharp Mask', 'FontSize', 12, 'FontWeight', 'bold');

%% ----------------------------------------------------------
%  SAVE WORKSPACE
% ----------------------------------------------------------
save('./Output/workspace_phase2.mat', ...
     'images', 'images_gray', 'images_clahe', ...
     'images_gauss', 'images_dog', 'images_us', ...
     'filenames', 'labels', 'descriptions', 'N', 'SELECTED', ...
     'CLAHE_TILES', 'CLAHE_CLIPLIMIT');

fprintf('\nWorkspace saved to ./Output/workspace_phase2.mat\n');