%% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 2 - Point Processing Comparison
%
%  Process all images, display only selected 5.
%% ============================================================

clear; clc; close all;
load('./Output/workspace_phase1.mat');
disp('Workspace from Phase 1 loaded');

%% ----------------------------------------------------------
%  PARAMETERS
% -----------------------------------------------------------
SELECTED = [2, 10, 1, 13, 4]; % images to display only
N_all    = N;                 % total images

CLAHE_TILES     = [8 8];
CLAHE_CLIPLIMIT = 0.02;

% Preallocate storage for all processed images
images_norm  = cell(N_all,1);
images_eq    = cell(N_all,1);
images_clahe = cell(N_all,1);

%% ----------------------------------------------------------
%  PROCESS ALL IMAGES
% ----------------------------------------------------------
for i = 1:N_all
    img = images_gray{i};

    % Histogram Normalisation
    img_d = double(img);
    img_norm{i} = uint8(255*(img_d - min(img_d(:))) / (max(img_d(:)) - min(img_d(:))));

    % Histogram Equalisation
    images_eq{i} = histeq(img);

    % CLAHE
    images_clahe{i} = adapthisteq(img, ...
                                  'NumTiles', CLAHE_TILES, ...
                                  'ClipLimit', CLAHE_CLIPLIMIT, ...
                                  'Distribution', 'uniform');
end

%% ----------------------------------------------------------
%  DISPLAY ONLY SELECTED IMAGES
% ----------------------------------------------------------
figure('Name', 'Point Processing Comparison', ...
       'NumberTitle', 'off', 'Position', [0,0,1800,1100]);

for row_disp = 1:length(SELECTED)
    i = SELECTED(row_disp); % original index
    img = images_gray{i};

    % Title color by label
    if labels(i) == 0, col = [0 0.5 0]; status = 'CLEAR';
    else,               col = [0.8 0 0]; status = 'OBSTRUCTED'; end
    [~, name, ext] = fileparts(filenames{i});
    base_title = sprintf('[%d] %s — %s', i, [name ext], status);

    % ── Column 1-2: Original ─────────────────────────────
    subplot(length(SELECTED),8,(row_disp-1)*8 + 1);
    imshow(img);
    title(sprintf('%s\nOriginal', base_title), 'FontSize', 6, 'Color', col, 'Interpreter','none');

    subplot(length(SELECTED),8,(row_disp-1)*8 + 2);
    imhist(img); set(gca,'FontSize',6);
    title(sprintf('mean=%.0f', mean(double(img(:)))), 'FontSize',6);

    % ── Column 3-4: Normalised ───────────────────────────
    subplot(length(SELECTED),8,(row_disp-1)*8 + 3);
    imshow(images_norm{i});
    title('Normalised','FontSize',6);

    subplot(length(SELECTED),8,(row_disp-1)*8 + 4);
    imhist(images_norm{i}); set(gca,'FontSize',6);
    title(sprintf('mean=%.0f', mean(double(images_norm{i}(:)))), 'FontSize',6);

    % ── Column 5-6: Equalised ────────────────────────────
    subplot(length(SELECTED),8,(row_disp-1)*8 + 5);
    imshow(images_eq{i});
    title('Equalisation','FontSize',6);

    subplot(length(SELECTED),8,(row_disp-1)*8 + 6);
    imhist(images_eq{i}); set(gca,'FontSize',6);
    title(sprintf('mean=%.0f', mean(double(images_eq{i}(:)))), 'FontSize',6);

    % ── Column 7-8: CLAHE ───────────────────────────────
    subplot(length(SELECTED),8,(row_disp-1)*8 + 7);
    imshow(images_clahe{i});
    title('CLAHE','FontSize',6);

    subplot(length(SELECTED),8,(row_disp-1)*8 + 8);
    imhist(images_clahe{i}); set(gca,'FontSize',6);
    title(sprintf('mean=%.0f', mean(double(images_clahe{i}(:)))), 'FontSize',6);
end

sgtitle('Point Processing Comparison (Original | Normalised | Equalisation | CLAHE)', ...
        'FontSize',12,'FontWeight','bold');

%% ----------------------------------------------------------
%  SAVE WORKSPACE
% -----------------------------------------------------------
save('./Output/workspace_phase2.mat', ...
     'images', 'images_gray', 'filenames', 'labels', 'descriptions', 'N', ...
     'images_norm', 'images_eq', 'images_clahe', 'SELECTED', ...
     'CLAHE_TILES', 'CLAHE_CLIPLIMIT');

fprintf('\nWorkspace saved to ./Output/workspace_phase2.mat\n');