% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 7B - Region Extraction and Baseline Construction
%
%  Authors:
%   - David Marafuz Gaspar - 106541
%   - Pedro Gaspar Mónico - 106626
%
% ============================================================
clear; clc; close all;
load('./Output/workspace_phase6.mat');
load('./Output/ground_truth.mat');

%% ----------------------------------------------------------
%  ROI DEFINITION  <-- EDIT HERE
% -----------------------------------------------------------
% Define the ROI as a function of image height (h) and width (w).
% The mask must be a logical matrix of size [h, w].
% Current definition mirrors the paper's trapezoidal ROI.

% Padding to close the vertical seam at the mirror boundary
seam_padding = 5;

get_roi = @(h, w) get_roi_mask(h, w, seam_padding);

%% ----------------------------------------------------------
%  SECTION 1: SELECT BASELINE IMAGES
% -----------------------------------------------------------

baseline_names = {'Frame1253.jpg', 'Frame1291.jpg', 'Frame1532.jpg', ...
                  'Frame1603.jpg', 'image00756.jpg', 'image02293.jpg', ...
                  'image06026.jpg', 'p8.jpg'};

num_baseline  = length(baseline_names);
poly_degree   = 2;
rail_padding  = 15;  % pixels to exclude on each side of the rail lines

%% ----------------------------------------------------------
%  SECTION 2: EXTRACT 3 REGIONS PER BASELINE IMAGE
% -----------------------------------------------------------

baseline_regions = cell(num_baseline, 3);

figure('Name', 'Figure 21 - Baseline Region Split Verification', ...
    'NumberTitle', 'off', 'Position', [0, 0, 1500, 400]);

for b = 1:num_baseline
    bname = baseline_names{b};

    b_idx = [];
    for i = 1:N
        [~, name, ext] = fileparts(filenames{i});
        if strcmp([name ext], bname)
            b_idx = i;
            break;
        end
    end

    gt_idx = [];
    for j = 1:length(gt)
        if strcmp(gt(j).filename, bname)
            gt_idx = j;
            break;
        end
    end

    if isempty(b_idx) || isempty(gt_idx)
        warning('Skipping %s — image or ground truth not found.', bname);
        continue;
    end

    b_img     = images{b_idx};
    [h, w, ~] = size(b_img);

    % Apply the user-defined ROI
    b_roi_mask = get_roi(h, w);

    pts_left  = gt(gt_idx).left;
    pts_right = gt(gt_idx).right;

    % Polynomial fit to curved rails (x as function of y)
    p_left  = polyfit(pts_left(:,2),  pts_left(:,1),  poly_degree);
    p_right = polyfit(pts_right(:,2), pts_right(:,1), poly_degree);

    % Build pixel-wise region masks
    [X, Y]      = meshgrid(1:w, 1:h);
    x_left_map  = polyval(p_left,  Y);
    x_right_map = polyval(p_right, Y);

    left_region   = (X < x_left_map  - rail_padding) & b_roi_mask;
    right_region  = (X > x_right_map + rail_padding) & b_roi_mask;
    middle_region = (X >= x_left_map + rail_padding) & ...
                    (X <= x_right_map - rail_padding) & b_roi_mask;

    region_masks = {left_region, middle_region, right_region};

    for r = 1:3
        reg_img = b_img;
        reg_img(repmat(~region_masks{r}, [1 1 3])) = 0;
        baseline_regions{b, r} = reg_img;
    end

    % --- Verification figure ---
    overlay = zeros(h, w, 3);
    overlay(:,:,1) = double(left_region);
    overlay(:,:,2) = double(middle_region);
    overlay(:,:,3) = double(right_region);

    subplot(1, num_baseline, b);
    imshow(b_img); hold on;
    h_ov = imshow(overlay);
    set(h_ov, 'AlphaData', 0.4 * double(b_roi_mask));
    y_range = (1:h)';
    plot(polyval(p_left,  y_range), y_range, 'y-', 'LineWidth', 2);
    plot(polyval(p_right, y_range), y_range, 'y-', 'LineWidth', 2);
    title(sprintf('[%d] %s', b, bname), 'FontSize', 8, 'Interpreter', 'none');
    hold off;
end

sgtitle('Figure 21 — Baseline Region Split  (L=red  M=green  R=blue)', ...
    'FontSize', 12, 'FontWeight', 'bold');

%% ----------------------------------------------------------
%  SECTION 3: DISPLAY EXTRACTED REGIONS
% -----------------------------------------------------------

region_names = {'Left', 'Middle', 'Right'};

figure('Name', 'Figure 22 - Extracted Baseline Regions', ...
    'NumberTitle', 'off', 'Position', [0, 0, 1500, 700]);

for b = 1:num_baseline
    for r = 1:3
        subplot(num_baseline, 3, (b-1)*3 + r);
        imshow(baseline_regions{b, r});
        [~, bname, ~] = fileparts(baseline_names{b});
        title(sprintf('%s\n%s region', bname, region_names{r}), ...
            'FontSize', 7, 'Interpreter', 'none');
    end
end

sgtitle('Figure 22 — Extracted Baseline Regions per Image', ...
    'FontSize', 12, 'FontWeight', 'bold');

%% ----------------------------------------------------------
%  SECTION 4: SAVE BASELINE REGIONS
% -----------------------------------------------------------

save('./Output/baseline_regions.mat', ...
    'baseline_regions', 'baseline_names', ...
    'region_names', 'poly_degree');
fprintf('\nBaseline regions saved to ./Output/baseline_regions.mat\n');

%% ----------------------------------------------------------
%  ROI HELPER FUNCTION  <-- EDIT THIS TO CHANGE THE ROI
% -----------------------------------------------------------
function mask = get_roi_mask(h, w, seam_padding)
% get_roi_mask - Defines the trapezoidal ROI mask.
%
%   Inputs:
%     h            - Image height in pixels
%     w            - Image width in pixels
%     seam_padding - Extra columns added to each side of the
%                    centre seam to avoid a vertical gap
%
%   Output:
%     mask         - Logical [h x w] ROI mask
%
%   To define a new ROI, edit the constraints below.
%   All coordinates are in IMAGE coordinates:
%     - Origin is top-left
%     - Y increases downward
%     - X increases rightward

    [X, Y] = meshgrid(1:w, 1:h);

    % --- Subregion A (left half) ---
    % Edit these three constraints to redefine the ROI shape:
    %
    %   Y > 0.4*h       → exclude upper 40% (sky/background)
    %   X < 0.5*w       → left half only
    %   Y > h - 3*X     → diagonal from bottom-left to mid-image
    %
    mask_A = (Y > 0.4 * h) & ...
             (X < 0.5 * w + seam_padding) & ...
             (Y > h - 1.4 * X);

    % Mirror A around the vertical bisector to get right side
    mask_B = fliplr(mask_A);

    % Union gives the full trapezoidal ROI
    mask = mask_A | mask_B;
end