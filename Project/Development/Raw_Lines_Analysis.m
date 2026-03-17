% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 1 - Rail Detection via Polynomial Fit (no strips)
%
%  Authors:
%   - David Marafuz Gaspar - 106541
%   - Pedro Gaspar Mónico - 106626
%
% ============================================================
clear; clc; close all;

load('./Output/workspace_phase0.mat');
disp('Workspace loaded successfully');

%% Parameters
BLUR_SIGMA   = 3.5;
CANNY_LOW    = 0.15;
CANNY_HIGH   = 0.40;
NUM_PEAKS    = 10;
HOUGH_THRESH = 0.2;
FILL_GAP     = 15;
MIN_LENGTH   = 40;
ANGLE_RANGE  = [-50, 50];
MIN_ANGLE    = 15;
MAX_ANGLE    = 75;
X_MARGIN     = 0.25;
POLY_DEG     = 2;

out_dir = './Output/single_config/';
if ~exist(out_dir, 'dir'), mkdir(out_dir); end

%% Process all images
for i = 1:N

    img  = images{i};
    gray = rgb2gray(img);
    [imgH, imgW] = size(gray);

    % --- Trapezoid ROI ---
    bottomLeft  = [round(0.05*imgW), imgH            ];
    bottomRight = [round(0.95*imgW), imgH            ];
    topLeft     = [round(0.25*imgW), round(0.45*imgH)];
    topRight    = [round(0.75*imgW), round(0.45*imgH)];
    polyX = [bottomLeft(1), topLeft(1), topRight(1), bottomRight(1)];
    polyY = [bottomLeft(2), topLeft(2), topRight(2), bottomRight(2)];

    mask = poly2mask(polyX, polyY, imgH, imgW);
    roi_masked = gray;
    roi_masked(~mask) = 0;

    row_min = min(polyY); row_max = max(polyY);
    col_min = min(polyX); col_max = max(polyX);
    roi_crop  = roi_masked(row_min:row_max, col_min:col_max);
    mask_crop = mask(row_min:row_max, col_min:col_max);

    % --- CLAHE ---
    roi_clahe = adapthisteq(roi_crop, ...
        'NumTiles',     [8 8], ...
        'ClipLimit',    0.02,  ...
        'Distribution', 'uniform');
    roi_clahe(~mask_crop) = 0;

    % --- Gaussian blur ---
    blurred = imgaussfilt(roi_clahe, BLUR_SIGMA);

    % --- Canny ---
    edges_full = edge(blurred, 'Canny', [CANNY_LOW, CANNY_HIGH]);
    edges_full(~mask_crop) = 0;

    % --- Single Hough over full ROI ---
    [H, T, R] = hough(edges_full, ...
        'Theta', linspace(ANGLE_RANGE(1), ANGLE_RANGE(2), 180));

    P = houghpeaks(H, NUM_PEAKS, ...
        'Threshold', HOUGH_THRESH * max(H(:)), ...
        'NHoodSize', [11, 11]);

    raw_lines = [];
    if ~isempty(P)
        raw_lines = houghlines(edges_full, T, R, P, ...
            'FillGap',   FILL_GAP, ...
            'MinLength', MIN_LENGTH);
    end

    % --- Filter: angle + both endpoints inside lateral margin ---
    roi_w       = col_max - col_min;
    x_margin_px = round(X_MARGIN * roi_w);
    rail_lines  = [];

    for k = 1:length(raw_lines)
        dx  = raw_lines(k).point2(1) - raw_lines(k).point1(1);
        dy  = raw_lines(k).point2(2) - raw_lines(k).point1(2);
        ang = abs(atan2d(abs(dy), abs(dx)));

        if ang < MIN_ANGLE || ang > MAX_ANGLE
            continue;
        end

        x1 = raw_lines(k).point1(1);
        x2 = raw_lines(k).point2(1);
        if x1 < x_margin_px || x1 > (roi_w - x_margin_px)
            continue;
        end
        if x2 < x_margin_px || x2 > (roi_w - x_margin_px)
            continue;
        end

        rail_lines = [rail_lines, raw_lines(k)]; %#ok<AGROW>
    end

    % --- Split into left / right by x midpoint ---
    left_pts  = [];
    right_pts = [];
    mid_img   = imgW / 2;

    for k = 1:length(rail_lines)
        x1 = rail_lines(k).point1(1) + col_min - 1;
        y1 = rail_lines(k).point1(2) + row_min - 1;
        x2 = rail_lines(k).point2(1) + col_min - 1;
        y2 = rail_lines(k).point2(2) + row_min - 1;
        mx = (x1 + x2) / 2;
        if mx < mid_img
            left_pts  = [left_pts;  x1 y1; x2 y2]; %#ok<AGROW>
        else
            right_pts = [right_pts; x1 y1; x2 y2]; %#ok<AGROW>
        end
    end

    % --- Polynomial fit: x = f(y) ---
y_fit      = linspace(row_min, row_max, 300)';
poly_left  = [];
poly_right = [];

if size(left_pts, 1) >= POLY_DEG + 1
    p_left    = polyfit(left_pts(:,2), left_pts(:,1), POLY_DEG);
    poly_left = [polyval(p_left, y_fit), y_fit];
end

if size(right_pts, 1) >= POLY_DEG + 1
    p_right    = polyfit(right_pts(:,2), right_pts(:,1), POLY_DEG);
    poly_right = [polyval(p_right, y_fit), y_fit];
end

    % --- Plot ---
    figure('Name', sprintf('Image %d — %s', i, descriptions{i}), ...
        'NumberTitle', 'off', 'Position', [50, 50, 1600, 380]);

    subplot(1, 5, 1);
    imshow(img);
    title('Original', 'FontSize', 8);

    subplot(1, 5, 2);
    imshow(gray); hold on;
    plot(polyX([1:end,1]), polyY([1:end,1]), 'y-', 'LineWidth', 1.5);
    hold off;
    title('ROI trapezoid', 'FontSize', 8);

    subplot(1, 5, 3);
    imshow(roi_clahe);
    title('CLAHE', 'FontSize', 8);

    subplot(1, 5, 4);
    imshow(edges_full);
    title('Canny edges', 'FontSize', 8);

    subplot(1, 5, 5);
    imshow(img); hold on;
    if ~isempty(poly_left)
        plot(poly_left(:,1),  poly_left(:,2),  'g-', 'LineWidth', 2.5);
    end
    if ~isempty(poly_right)
        plot(poly_right(:,1), poly_right(:,2), 'r-', 'LineWidth', 2.5);
    end
    hold off;

    if labels(i) == 0, col = [0 0.5 0]; else, col = [0.8 0 0]; end
    n_detected = (~isempty(poly_left)) + (~isempty(poly_right));
    title(sprintf('Rails fitted: %d', n_detected), ...
        'FontSize', 8, 'Color', col);

    [~, name, ext] = fileparts(filenames{i});
    sgtitle(sprintf('[%d] %s — %s', i, [name ext], descriptions{i}), ...
        'FontSize', 11, 'FontWeight', 'bold', 'Color', col);
    fprintf('Image %d/%d done\n', i, N);
end

disp('Done — all images processed.');