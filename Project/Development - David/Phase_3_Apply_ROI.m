% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 3 - Region of Interest (ROI) Masking
%
%  Authors:
%   - David Marafuz Gaspar - 106541
%   - Pedro Gaspar Mónico - 106626
%
% ============================================================
clear; clc; close all;
load('./Output/workspace_phase2.mat');
disp('Workspace from Phase 2 loaded');

%% Live Script Comment
% To restrict edge detection to the most relevant portion of the image,
% a Region of Interest (ROI) is defined as a trapezoidal mask centred on
% the track area. The ROI is constructed by first defining subregion A
% using three constraints in image coordinates (origin top-left, y
% increasing downward), and then mirroring it around the vertical
% bisector to produce the symmetric right-side region. A overlap padding
% is added around the centre column to avoid a vertical discontinuity
% at the mirror seam. The union of both regions forms the final
% trapezoidal ROI, which excludes sky, lateral scenery, and overhead
% infrastructure from subsequent processing.

%% ----------------------------------------------------------
%  SECTION 1: BUILD ROI MASK AND APPLY TO IMAGES
% -----------------------------------------------------------

images_roi = cell(N, 1);
masks      = cell(N, 1);

% Number of columns of padding added on each side of the centre seam
% to close the vertical gap introduced by integer mirroring.
seam_padding = 1;

for i = 1:N
    [h, w] = size(images_smooth{i});

    [X, Y] = meshgrid(1:w, 1:h);

    % --- Subregion A (left side) ---
    % In image coordinates, y increases downward, so:
    %   y > 0.4*h   → below the upper 40% of the image
    %   x < 0.5*w   → left half of the image
    %   y > h - 2*x → diagonal from p1=(0,h) to p2=(0.3*w, 0.4*h)
    mask_A = (Y > 0.4 * h) & ...
             (X < 0.5 * w + seam_padding) & ...
             (Y > h - 2 * X);

    % --- Subregion B: mirror of A around vertical bisector ---
    mask_B = fliplr(mask_A);

    % Union of both subregions forms the full trapezoidal ROI
    mask = mask_A | mask_B;

    % Apply mask: pixels outside ROI are set to zero
    roi = images_smooth{i};
    roi(~mask) = 0;

    masks{i}      = mask;
    images_roi{i} = roi;
end

%% Live Script Comment
% Figure 10 presents the ROI-masked images across the full dataset.
% The trapezoidal region is designed to capture the track area while
% suppressing irrelevant background structures. Curved track images
% and tunnel scenes are of particular interest, as the fixed geometric
% mask may not align perfectly with the rail position in all cases —
% these will be revisited in the failure case analysis.

%% ----------------------------------------------------------
%  SECTION 2: DISPLAY ROI IMAGES - GRID OVERVIEW
% -----------------------------------------------------------

figure('Name', 'Figure 10 - ROI Masked Images', ...
    'NumberTitle', 'off', ...
    'Position', [0, 0, 1500, 900]);

for i = 1:N
    subplot(3, 5, i);
    imshow(images_roi{i});

    if labels(i) == 0
        col = [0 0.5 0];
    else
        col = [0.8 0 0];
    end

    [~, name, ext] = fileparts(filenames{i});
    title(sprintf('[%d] %s\n%s', i, [name ext], descriptions{i}), ...
        'FontSize', 7, 'Color', col, 'Interpreter', 'none');
end

sgtitle('Figure 10 — ROI Masked Images  (green = clear  |  red = obstructed)', ...
    'FontSize', 13, 'FontWeight', 'bold');

%% ----------------------------------------------------------
%  SECTION 3: SAVE WORKSPACE
% -----------------------------------------------------------
save('./Output/workspace_phase3.mat', ...
    'images', 'images_gray', 'images_eq', 'images_smooth', ...
    'images_roi', 'masks', 'filenames', 'labels', 'descriptions', 'N');
fprintf('\nWorkspace saved to ./Output/workspace_phase3.mat\n');