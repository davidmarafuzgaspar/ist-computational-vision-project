%% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 4 - ROI Definition and Visualisation
%
%% ============================================================
clear; clc; close all;
load('./Output/workspace_phase2.mat');
disp('Workspace from Phase 2 loaded');

%% ----------------------------------------------------------
%  PARAMETERS
% -----------------------------------------------------------

% CLAHE (fixed)
CLAHE_TILES     = [8 8];
CLAHE_CLIPLIMIT = 0.02;

% Gaussian (fixed, sigma=1)
GAUSS_SIGMA = 1.0;

% ROI trapezoid vertices (fractions of image size)
ROI_BL_X = 0.05;   % bottom-left  x
ROI_BR_X = 0.95;   % bottom-right x
ROI_TL_X = 0.30;   % top-left     x
ROI_TR_X = 0.70;   % top-right    x
ROI_TOP_Y = 0.4;  % top y (fraction of height)

%% ----------------------------------------------------------
%  SECTION 1: APPLY PIPELINE UP TO ROI
% -----------------------------------------------------------

images_clahe    = cell(N, 1);
images_blur     = cell(N, 1);
images_roi      = cell(N, 1);
roi_masks       = cell(N, 1);

for i = 1:N
    imgH = size(images_gray{i}, 1);
    imgW = size(images_gray{i}, 2);

    % CLAHE
    eq = adapthisteq(images_gray{i}, ...
        'NumTiles',     CLAHE_TILES, ...
        'ClipLimit',    CLAHE_CLIPLIMIT, ...
        'Distribution', 'uniform');
    images_clahe{i} = eq;

    % Gaussian blur
    blurred = imgaussfilt(eq, GAUSS_SIGMA);
    images_blur{i} = blurred;

    % ROI trapezoid
    bottomLeft  = [round(ROI_BL_X * imgW),  imgH                   ];
    bottomRight = [round(ROI_BR_X * imgW),  imgH                   ];
    topLeft     = [round(ROI_TL_X * imgW),  round(ROI_TOP_Y * imgH)];
    topRight    = [round(ROI_TR_X * imgW),  round(ROI_TOP_Y * imgH)];

    polyX = [bottomLeft(1), topLeft(1), topRight(1), bottomRight(1)];
    polyY = [bottomLeft(2), topLeft(2), topRight(2), bottomRight(2)];

    mask            = poly2mask(polyX, polyY, imgH, imgW);
    roi_masks{i}    = mask;

    masked          = blurred;
    masked(~mask)   = 0;
    images_roi{i}   = masked;
end

%% ----------------------------------------------------------
%  SECTION 2: GRID — all images with ROI overlay + cropped
%
%  2 rows per image: top = original with ROI polygon drawn
%                    bottom = cropped/masked result
% -----------------------------------------------------------

% ── Figure A: ROI overlay on original colour image ───────────────────────
figure('Name', 'Figure 4a - ROI Overlay', ...
    'NumberTitle', 'off', ...
    'Position', [0, 0, 1500, 900]);

for i = 1:N
    imgH = size(images{i}, 1);
    imgW = size(images{i}, 2);

    bottomLeft  = [round(ROI_BL_X * imgW),  imgH                   ];
    bottomRight = [round(ROI_BR_X * imgW),  imgH                   ];
    topLeft     = [round(ROI_TL_X * imgW),  round(ROI_TOP_Y * imgH)];
    topRight    = [round(ROI_TR_X * imgW),  round(ROI_TOP_Y * imgH)];

    polyX = [bottomLeft(1), topLeft(1), topRight(1), bottomRight(1), bottomLeft(1)];
    polyY = [bottomLeft(2), topLeft(2), topRight(2), bottomRight(2), bottomLeft(2)];

    subplot(3, 5, i);
    imshow(images{i}); hold on;
    plot(polyX, polyY, 'y-', 'LineWidth', 2);
    hold off;

    if labels(i) == 0, col = [0 0.5 0]; else, col = [0.8 0 0]; end
    [~, name, ext] = fileparts(filenames{i});
    title(sprintf('[%d] %s\n%s', i, [name ext], descriptions{i}), ...
        'FontSize', 7, 'Color', col, 'Interpreter', 'none');
end

sgtitle('Figure 4a — ROI Overlay on Original  (yellow = trapezoid)', ...
    'FontSize', 13, 'FontWeight', 'bold');

% ── Figure B: Masked result (CLAHE + Gaussian + ROI) ─────────────────────
figure('Name', 'Figure 4b - ROI Masked Result', ...
    'NumberTitle', 'off', ...
    'Position', [0, 0, 1500, 900]);

for i = 1:N
    subplot(3, 5, i);
    imshow(images_roi{i});

    if labels(i) == 0, col = [0 0.5 0]; else, col = [0.8 0 0]; end
    [~, name, ext] = fileparts(filenames{i});
    title(sprintf('[%d] %s\n%s', i, [name ext], descriptions{i}), ...
        'FontSize', 7, 'Color', col, 'Interpreter', 'none');
end

sgtitle('Figure 4b — ROI Masked Result  (CLAHE + Gaussian \sigma=1 + ROI)', ...
    'FontSize', 13, 'FontWeight', 'bold');

%% ----------------------------------------------------------
%  SECTION 3: SAVE WORKSPACE
% -----------------------------------------------------------

save('./Output/workspace_phase4.mat', ...
    'images', 'images_gray', 'images_clahe', 'images_blur', ...
    'images_roi', 'roi_masks', ...
    'filenames', 'labels', 'descriptions', 'N', ...
    'CLAHE_TILES', 'CLAHE_CLIPLIMIT', 'GAUSS_SIGMA', ...
    'ROI_BL_X', 'ROI_BR_X', 'ROI_TL_X', 'ROI_TR_X', 'ROI_TOP_Y');

fprintf('\nWorkspace saved to ./Output/workspace_phase4.mat\n');