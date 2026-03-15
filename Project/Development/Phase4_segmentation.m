%% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 4 - Rail Segmentation
%  ROI masking + Edge detection + Hough Transform
%  Left/right rail split by line angle (not position)
%
%% ============================================================
clear; clc; close all;
load('./Output/workspace_phase3b.mat');
disp('Workspace from Phase 3b loaded');

%% ----------------------------------------------------------
%  CONFIGURATION
% -----------------------------------------------------------

figNum = 40;   % <-- adjust to continue after Phase 3b figures

% --- ROI trapezoid ---
roi_left_frac  = 0.05;
roi_right_frac = 0.95;
roi_top_left   = 0.30;
roi_top_right  = 0.70;
roi_top_y      = 0.25;

% --- Edge detector ---
best_detector = 'Canny';

% --- Hough parameters ---
% Rails converge to vanishing point → near-vertical lines
% Left rail leans right  → positive theta  (e.g. +5° to +30°)
% Right rail leans left  → negative theta  (e.g. -5° to -30°)
% Near-zero theta = vertical lines (e.g. poles, signs) → excluded
hough_theta    = linspace(-30, 30, 180);
hough_fillGap  = 120;   % bridge interrupted segments (try 80, 150)
hough_minLen   = 100;   % suppress short spurious segments (try 80, 150)
hough_nPeaks   = 10;    % search broadly, post-processing filters

% Minimum absolute angle to exclude near-vertical noise (poles, signs)
min_abs_theta  = 3;     % degrees (try 2, 5, 8)

%% ----------------------------------------------------------
%  SECTION 1: RAIL DETECTION ON ALL 15 IMAGES
% -----------------------------------------------------------

rail_lines_all = cell(N, 1);
detection_log  = cell(N, 1);

for i = 1:N

    Ie = images_enhanced{i};
    Ig = images_gray{i};
    [imgH, imgW] = size(Ie);
    [~, name, ext] = fileparts(filenames{i});

    if labels(i) == 0
        col = [0 0.5 0]; status = 'CLEAR';
    else
        col = [0.8 0 0]; status = 'OBSTRUCTED';
    end

    % --- ROI mask ---
    [polyX, polyY] = get_roi(imgH, imgW, ...
        roi_left_frac, roi_right_frac, ...
        roi_top_left, roi_top_right, roi_top_y);
    mask   = poly2mask(polyX, polyY, imgH, imgW);
    I_edge = edge(Ie, best_detector) & mask;

    % --- Hough ---
    [H, theta, rho] = hough(I_edge, 'Theta', hough_theta);
    peaks  = houghpeaks(H, hough_nPeaks, 'Threshold', 0.2*max(H(:)));
    lines  = houghlines(I_edge, theta, rho, peaks, ...
                 'FillGap', hough_fillGap, 'MinLength', hough_minLen);

    % --- Split by angle sign ---
    % Left rail:  positive theta → line leans right (/)
    % Right rail: negative theta → line leans left  (\)
    % Exclude lines too close to vertical (|) — likely poles/signs
    left_cands  = [];
    right_cands = [];

    for j = 1:length(lines)
        ang = lines(j).theta;
        if abs(ang) < min_abs_theta
            continue;   % skip near-vertical noise
        end
        if ang > 0
            left_cands  = [left_cands,  lines(j)]; %#ok<AGROW>
        else
            right_cands = [right_cands, lines(j)]; %#ok<AGROW>
        end
    end

    % Keep longest from each group
    left_rail  = pick_longest(left_cands);
    right_rail = pick_longest(right_cands);

    rail_lines_all{i} = {left_rail, right_rail};

    hasL = ~isempty(left_rail);
    hasR = ~isempty(right_rail);
    detection_log{i} = sprintf( ...
        'raw=%d  left_cand=%d(+θ)  right_cand=%d(-θ)  result=%s+%s', ...
        length(lines), length(left_cands), length(right_cands), ...
        bool2str(hasL), bool2str(hasR));

    % --- Figure ---
    figure('Name', sprintf('Figure %d - Rails: %s [%s]', figNum, [name ext], status), ...
        'NumberTitle', 'off', 'Position', [0 0 1400 400]);

    % Col 1: enhanced + ROI
    subplot(1, 4, 1);
    imshow(Ie); hold on;
    plot([polyX, polyX(1)], [polyY, polyY(1)], 'y-', 'LineWidth', 1.5);
    hold off;
    title(sprintf('[%d] %s\nEnhanced + ROI', i, [name ext]), ...
        'FontSize', 8, 'Color', col, 'Interpreter', 'none');

    % Col 2: edge map
    subplot(1, 4, 2);
    imshow(I_edge);
    title(sprintf('%s edges (ROI)\nDensity: %.2f%%', best_detector, ...
        sum(I_edge(:))/sum(mask(:))*100), 'FontSize', 8);

    % Col 3: Hough accumulator
    subplot(1, 4, 3);
    imshow(imadjust(mat2gray(H)), 'XData', theta, 'YData', rho);
    axis on; axis normal;
    xlabel('\theta°', 'FontSize', 7);
    ylabel('\rho (px)', 'FontSize', 7);
    hold on;
    if ~isempty(peaks)
        plot(theta(peaks(:,2)), rho(peaks(:,1)), 'rs', ...
            'LineWidth', 1.5, 'MarkerSize', 6);
    end
    % Mark the angular split
    xline(0, 'w--', 'LineWidth', 0.5);
    xline(min_abs_theta,  'y--', 'LineWidth', 0.5);
    xline(-min_abs_theta, 'y--', 'LineWidth', 0.5);
    hold off;
    title(sprintf('Accumulator\n+θ=left  -θ=right  |θ|<%d°=skip', ...
        min_abs_theta), 'FontSize', 8);

    % Col 4: final rails on grayscale
    subplot(1, 4, 4);
    imshow(Ig); hold on;
    plot([polyX, polyX(1)], [polyY, polyY(1)], 'y--', 'LineWidth', 1);
    if hasL
        xy = [left_rail.point1;  left_rail.point2];
        plot(xy(:,1), xy(:,2), 'r-', 'LineWidth', 3);
        plot(xy(:,1), xy(:,2), 'r.', 'MarkerSize', 10);
    end
    if hasR
        xy = [right_rail.point1; right_rail.point2];
        plot(xy(:,1), xy(:,2), 'g-', 'LineWidth', 3);
        plot(xy(:,1), xy(:,2), 'g.', 'MarkerSize', 10);
    end
    hold off;
    title(sprintf('Left (+θ): %s   Right (-θ): %s\nred=left  green=right', ...
        bool2str(hasL), bool2str(hasR)), 'FontSize', 8);

    sgtitle(sprintf('Figure %d — Rail detection: %s  [%s]', figNum, [name ext], status), ...
        'FontSize', 11, 'FontWeight', 'bold', 'Color', col);

    figNum = figNum + 1;

end

%% ----------------------------------------------------------
%  SECTION 2: DETECTION SUMMARY TABLE
% -----------------------------------------------------------

fprintf('\n%s\n', repmat('=', 1, 90));
fprintf('PHASE 4 — RAIL DETECTION SUMMARY\n');
fprintf('%s\n', repmat('=', 1, 90));
fprintf('%-22s | %-6s | %-5s | %-5s | %s\n', ...
    'Image', 'Label', 'Left', 'Right', 'Diagnostics');
fprintf('%s\n', repmat('-', 1, 90));

n_both    = 0;
n_partial = 0;
n_none    = 0;

for i = 1:N
    [~, name, ext] = fileparts(filenames{i});
    if labels(i) == 0; lbl = 'CLEAR'; else; lbl = 'OBSTR'; end

    hasL = ~isempty(rail_lines_all{i}{1});
    hasR = ~isempty(rail_lines_all{i}{2});

    if hasL && hasR
        result = 'BOTH';    n_both    = n_both + 1;
    elseif hasL || hasR
        result = 'PARTIAL'; n_partial = n_partial + 1;
    else
        result = 'NONE';    n_none    = n_none + 1;
    end

    fprintf('%-22s | %-6s | %-5s | %-5s | [%s]  %s\n', ...
        [name ext], lbl, bool2str(hasL), bool2str(hasR), ...
        result, detection_log{i});
end

fprintf('%s\n', repmat('=', 1, 90));
fprintf('Both rails detected:  %d / %d\n', n_both,    N);
fprintf('Partial detection:    %d / %d\n', n_partial, N);
fprintf('No rails detected:    %d / %d\n', n_none,    N);
fprintf('%s\n', repmat('=', 1, 90));

%% ----------------------------------------------------------
%  SECTION 3: SAVE WORKSPACE
% -----------------------------------------------------------

save('./Output/workspace_phase4.mat', ...
    'images', 'images_gray', 'images_enhanced', ...
    'filenames', 'labels', 'descriptions', 'N', ...
    'enhance_log', 'rail_lines_all', 'detection_log', ...
    'best_detector', 'hough_nPeaks', ...
    'hough_fillGap', 'hough_minLen', 'hough_theta', ...
    'min_abs_theta', ...
    'roi_left_frac', 'roi_right_frac', ...
    'roi_top_left',  'roi_top_right', 'roi_top_y');

fprintf('\nWorkspace saved to ./Output/workspace_phase4.mat\n');

%% ----------------------------------------------------------
%  LOCAL FUNCTIONS
% -----------------------------------------------------------

function [polyX, polyY] = get_roi(imgH, imgW, left_frac, right_frac, top_left, top_right, top_y)
%GET_ROI Returns trapezoid ROI vertices for a given image size.
    bottomLeft  = [round(left_frac  * imgW), imgH               ];
    bottomRight = [round(right_frac * imgW), imgH               ];
    topLeft     = [round(top_left   * imgW), round(top_y * imgH)];
    topRight    = [round(top_right  * imgW), round(top_y * imgH)];
    polyX = [bottomLeft(1), topLeft(1), topRight(1), bottomRight(1)];
    polyY = [bottomLeft(2), topLeft(2), topRight(2), bottomRight(2)];
end

function best = pick_longest(line_array)
%PICK_LONGEST Returns the longest line segment from a houghlines array.
    best = [];
    if isempty(line_array); return; end
    best_len = -1;
    for k = 1:length(line_array)
        p1  = line_array(k).point1;
        p2  = line_array(k).point2;
        len = sqrt((p2(1)-p1(1))^2 + (p2(2)-p1(2))^2);
        if len > best_len
            best_len = len;
            best = line_array(k);
        end
    end
end

function s = bool2str(b)
%BOOL2STR Returns 'YES' or 'NO' from a boolean.
    if b; s = 'YES'; else; s = 'NO'; end
end