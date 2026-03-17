%% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 2 - Preprocessing & Enhancement
%
%% ============================================================
clear; clc; close all;
load('./Output/workspace_phase1.mat');
disp('Workspace from Phase 1 loaded');

%% ----------------------------------------------------------
%  SECTION 1: COARSE ROI + NOISE REMOVAL
% -----------------------------------------------------------
images_roi      = cell(N, 1);
images_denoised = cell(N, 1);
roi_masks       = cell(N, 1);

for i = 1:N
    img  = images_gray{i};
    imgH = size(img, 1);
    imgW = size(img, 2);

    bottomLeft  = [round(0.05*imgW), imgH            ];
    bottomRight = [round(0.95*imgW), imgH            ];
    topLeft     = [round(0.30*imgW), round(0.25*imgH)];
    topRight    = [round(0.70*imgW), round(0.25*imgH)];

    polyX = [bottomLeft(1), topLeft(1), topRight(1), bottomRight(1)];
    polyY = [bottomLeft(2), topLeft(2), topRight(2), bottomRight(2)];

    mask            = poly2mask(polyX, polyY, imgH, imgW);
    roi_masks{i}    = mask;

    masked        = img;
    masked(~mask) = 0;
    images_roi{i} = masked;

    images_denoised{i} = imbilatfilt(images_roi{i});
end

%% ----------------------------------------------------------
%  SECTION 2: VISUALISE ROI ON ORIGINAL IMAGES
% -----------------------------------------------------------
figure('Name', 'Figure 7 - ROI Overlay', ...
    'NumberTitle', 'off', ...
    'Position', [0, 0, 1500, 900]);

for i = 1:N
    subplot(3, 5, i);
    imshow(images_gray{i}); hold on;

    imgH = size(images_gray{i}, 1);
    imgW = size(images_gray{i}, 2);

    bottomLeft  = [round(0.05*imgW), imgH            ];
    bottomRight = [round(0.95*imgW), imgH            ];
    topLeft     = [round(0.30*imgW), round(0.25*imgH)];
    topRight    = [round(0.70*imgW), round(0.25*imgH)];

    polyX = [bottomLeft(1), topLeft(1), topRight(1), bottomRight(1), bottomLeft(1)];
    polyY = [bottomLeft(2), topLeft(2), topRight(2), bottomRight(2), bottomLeft(2)];
    plot(polyX, polyY, 'y-', 'LineWidth', 1.5);
    hold off;

    if labels(i) == 0, col = [0 0.5 0]; else, col = [0.8 0 0]; end
    [~, name, ext] = fileparts(filenames{i});
    title(sprintf('[%d] %s', i, [name ext]), ...
        'FontSize', 6, 'Color', col, 'Interpreter', 'none');
end
sgtitle('Figure 7 — Coarse ROI trapezoid overlay (yellow)', ...
    'FontSize', 12, 'FontWeight', 'bold');

%% ----------------------------------------------------------
%  SECTION 3: FOUR ENHANCEMENT METHODS
% -----------------------------------------------------------
images_imadjust = cell(N, 1);
images_clahe    = cell(N, 1);
images_histeq   = cell(N, 1);
images_norm     = cell(N, 1);

for i = 1:N
    img  = images_denoised{i};
    mask = roi_masks{i};

    roi_pixels = img(mask);

    % --- Method A: imadjust ---
    lo  = double(prctile(double(roi_pixels), 1))  / 255;
    hi  = double(prctile(double(roi_pixels), 99)) / 255;
    lut = imadjust(img, [lo hi], [0 1]);
    out = img; out(mask) = lut(mask);
    images_imadjust{i} = out;

    % --- Method B: CLAHE ---
    clahe = adapthisteq(img, 'ClipLimit', 0.02, 'NumTiles', [8 8]);
    out   = img; out(mask) = clahe(mask);
    images_clahe{i} = out;

    % --- Method C: histeq ---
    eq  = histeq(roi_pixels);
    out = img; out(mask) = eq;
    images_histeq{i} = out;

    % --- Method D: normalisation ---
    mn    = double(min(roi_pixels));
    mx    = double(max(roi_pixels));
    roi_d = (double(roi_pixels) - mn) / (mx - mn);
    out   = img; out(mask) = im2uint8(roi_d);
    images_norm{i} = out;
end

%% ----------------------------------------------------------
%  SECTION 4: PER-IMAGE COMPARISON GRID
% -----------------------------------------------------------
method_names = {'Original', 'imadjust', 'CLAHE', 'histeq', 'Normalisation'};

for i = 1:N
    [~, name, ext] = fileparts(filenames{i});
    if labels(i) == 0
        col = [0 0.5 0]; status = 'CLEAR';
    else
        col = [0.8 0 0]; status = 'OBSTRUCTED';
    end

    figure('Name', sprintf('Image %d Enhancement', i), ...
        'NumberTitle', 'off', ...
        'Position', [0, 0, 1400, 320]);

    imgs_row = {images_roi{i}, images_imadjust{i}, ...
                images_clahe{i}, images_histeq{i}, images_norm{i}};

    for m = 1:5
        subplot(1, 5, m);
        imshow(imgs_row{m});
        title(method_names{m}, 'FontSize', 9);
    end

    sgtitle(sprintf('[%d] %s  —  %s', i, [name ext], status), ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'Color', col, 'Interpreter', 'none');
end

%% ----------------------------------------------------------
%  SECTION 5: UNSHARP MASKING ON CLAHE (FINAL ENHANCED)
% -----------------------------------------------------------
% Subtracts denoised from CLAHE to isolate the detail/edge
% layer that CLAHE introduced, then amplifies it back in.
% Applied only inside the ROI mask — boundary artefacts avoided.

alpha         = 0.3;   % sharpening strength — tune if needed
images_final  = cell(N, 1);

for i = 1:N
    mask     = roi_masks{i};
    clahe_d  = double(images_clahe{i});
    orig_d   = double(images_denoised{i});

    detail   = clahe_d - orig_d;
    sharp    = clahe_d + alpha * detail;
    sharp    = max(0, min(255, sharp));

    out      = images_denoised{i};
    out(mask) = uint8(sharp(mask));
    images_final{i} = out;
end

%% ----------------------------------------------------------
%  SECTION 6: FINAL RESULT GRID
% -----------------------------------------------------------
figure('Name', 'Figure 8 - Final Enhanced Images', ...
    'NumberTitle', 'off', ...
    'Position', [0, 0, 1500, 900]);

for i = 1:N
    subplot(3, 5, i);
    imshow(images_final{i});

    if labels(i) == 0, col = [0 0.5 0]; else, col = [0.8 0 0]; end
    [~, name, ext] = fileparts(filenames{i});
    title(sprintf('[%d] %s', i, [name ext]), ...
        'FontSize', 6, 'Color', col, 'Interpreter', 'none');
end
sgtitle('Figure 8 — Final enhanced images (CLAHE + unsharp mask, \alpha=1.5)', ...
        'FontSize', 12, 'FontWeight', 'bold');

%% ----------------------------------------------------------
%  SECTION 7: BEFORE vs AFTER GRID
% -----------------------------------------------------------
figure('Name', 'Figure 9 - Before vs After', ...
    'NumberTitle', 'off', ...
    'Position', [0, 0, 1500, 900]);

for i = 1:N
    subplot(3, 5, i);
    imshowpair(images_roi{i}, images_final{i}, 'montage');

    if labels(i) == 0, col = [0 0.5 0]; else, col = [0.8 0 0]; end
    [~, name, ext] = fileparts(filenames{i});
    title(sprintf('[%d] %s', i, [name ext]), ...
        'FontSize', 6, 'Color', col, 'Interpreter', 'none');
end
sgtitle('Figure 9 — Original ROI (left) vs Final enhanced (right)', ...
    'FontSize', 12, 'FontWeight', 'bold');

%% ----------------------------------------------------------
%  SECTION 8: SAVE WORKSPACE
% -----------------------------------------------------------
save('./Output/workspace_phase2.mat', ...
    'images', 'images_gray', ...
    'images_roi', 'roi_masks', ...
    'images_denoised', ...
    'images_imadjust', 'images_clahe', ...
    'images_histeq', 'images_norm', ...
    'images_final', ...
    'filenames', 'labels', 'descriptions', 'N');
fprintf('\nWorkspace saved to ./Output/workspace_phase2.mat\n');