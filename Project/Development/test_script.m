% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 1 - Rail Line Detection (Hough Transform) - v4
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
HOUGH_PEAKS  = 10;
HOUGH_THRESH = 0.6;
FILL_GAP     = 40;
MIN_LENGTH   = 100;
MIN_ANGLE    = 25;

%% Process each image
for i = 1:N

    img  = images{i};
    gray = rgb2gray(img);
    [imgH, imgW] = size(gray);

    % --- Trapezoid ROI mask ---
    bottomLeft  = [round(0.05*imgW),  imgH             ];
    bottomRight = [round(0.95*imgW),  imgH             ];
    topLeft     = [round(0.30*imgW),  round(0.25*imgH) ];
    topRight    = [round(0.70*imgW),  round(0.25*imgH) ];
    polyX = [bottomLeft(1), topLeft(1), topRight(1), bottomRight(1)];
    polyY = [bottomLeft(2), topLeft(2), topRight(2), bottomRight(2)];

    mask = poly2mask(polyX, polyY, imgH, imgW);

    roi_masked = gray;
    roi_masked(~mask) = 0;

    % Bounding box crop
    row_min = min(polyY);
    row_max = max(polyY);
    col_min = min(polyX);
    col_max = max(polyX);
    roi_crop  = roi_masked(row_min:row_max, col_min:col_max);
    mask_crop = mask(row_min:row_max, col_min:col_max);

    % --- CLAHE ---
    roi_clahe = adapthisteq(roi_crop, ...
        'NumTiles',     [8 8], ...
        'ClipLimit',    0.02,  ...
        'Distribution', 'uniform');

    % --- Unsharp mask (alpha = 0.3) ---
    roi_clahe = imsharpen(roi_clahe, 'Amount', 0.3, 'Radius', 2, 'Threshold', 0);

    % Re-zero outside trapezoid
    roi_clahe(~mask_crop) = 0;

    % --- Gaussian blur ---
    blurred = imgaussfilt(roi_clahe, BLUR_SIGMA);

    % --- Canny edges ---
    edges_full = edge(blurred, 'Canny', [CANNY_LOW, CANNY_HIGH]);
    edges_full(~mask_crop) = 0;

    % --- Hough ---
    [H, theta, rho] = hough(edges_full);
    peaks = houghpeaks(H, HOUGH_PEAKS, ...
        'Threshold', HOUGH_THRESH * max(H(:)), ...
        'NHoodSize', [11, 11]);
    lines = houghlines(edges_full, theta, rho, peaks, ...
        'FillGap', FILL_GAP, 'MinLength', MIN_LENGTH);

    % --- Angle filter ---
    rail_lines = [];
    for k = 1:length(lines)
        dx = lines(k).point2(1) - lines(k).point1(1);
        dy = lines(k).point2(2) - lines(k).point1(2);
        angle = abs(atan2d(abs(dy), abs(dx)));
        if angle > MIN_ANGLE
            rail_lines = [rail_lines, lines(k)]; %#ok<AGROW>
        end
    end

    % --- Keep 2 dominant rails (x-position split) ---
    rail_lines = keep_two_rails(rail_lines, imgW, col_min);

    % --- Plot ---
    figure('Name', sprintf('Image %d — %s', i, descriptions{i}), ...
        'NumberTitle', 'off', 'Position', [50, 50, 1600, 380]);

    subplot(1, 5, 1);
    imshow(img);
    title('Original', 'FontSize', 8);

    subplot(1, 5, 2);
    imshow(gray); hold on;
    plot(polyX([1:end, 1]), polyY([1:end, 1]), 'y-', 'LineWidth', 1.5);
    hold off;
    title('ROI trapezoid', 'FontSize', 8);

    subplot(1, 5, 3);
    imshow(roi_clahe);
    title('CLAHE + unsharp', 'FontSize', 8);

    subplot(1, 5, 4);
    imshow(edges_full);
    title('Canny edges', 'FontSize', 8);

    subplot(1, 5, 5);
    imshow(img); hold on;
    x_off = col_min - 1;
    y_off = row_min - 1;
    for k = 1:length(rail_lines)
        p1 = rail_lines(k).point1 + [x_off, y_off];
        p2 = rail_lines(k).point2 + [x_off, y_off];
        plot([p1(1) p2(1)], [p1(2) p2(2)], 'g-', 'LineWidth', 3);
    end
    hold off;

    if labels(i) == 0, col = [0 0.5 0]; else, col = [0.8 0 0]; end
    title(sprintf('Lines detected: %d', length(rail_lines)), ...
        'FontSize', 8, 'Color', col);

    [~, name, ext] = fileparts(filenames{i});
    sgtitle(sprintf('[%d] %s — %s', i, [name ext], descriptions{i}), ...
        'FontSize', 11, 'FontWeight', 'bold', 'Color', col);

    saveas(gcf, sprintf('./Output/phase1_img%02d.png', i));
end

disp('Phase 1 v4 complete.');

save('./Output/workspace_phase1.mat', ...
    'images', 'filenames', 'labels', 'descriptions', 'N', ...
    'BLUR_SIGMA', 'CANNY_LOW', 'CANNY_HIGH', ...
    'HOUGH_PEAKS', 'HOUGH_THRESH', 'FILL_GAP', 'MIN_LENGTH', 'MIN_ANGLE');
fprintf('Workspace saved to ./Output/workspace_phase1.mat\n');

%% ---------------------------------------------------------------
function best = keep_two_rails(lines, imgW, col_min)
    if isempty(lines)
        best = lines;
        return;
    end

    left_idx  = [];
    right_idx = [];
    mid = imgW / 2;

    for k = 1:length(lines)
        mx = mean([lines(k).point1(1), lines(k).point2(1)]) + col_min - 1;
        if mx < mid
            left_idx  = [left_idx,  k];
        else
            right_idx = [right_idx, k];
        end
    end

    best = [];
    best = append_longest(best, lines, left_idx);
    best = append_longest(best, lines, right_idx);
end

function out = append_longest(out, lines, idx)
    if isempty(idx), return; end
    lengths = zeros(1, length(idx));
    for j = 1:length(idx)
        d = lines(idx(j)).point2 - lines(idx(j)).point1;
        lengths(j) = norm(d);
    end
    [~, best_j] = max(lengths);
    out = [out, lines(idx(best_j))];
end