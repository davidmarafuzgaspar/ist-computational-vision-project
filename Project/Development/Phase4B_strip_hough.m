%% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 4b - Strip-Based Rail Segmentation
%  Divide ROI into horizontal strips, run Hough per strip,
%  connect detections and flag strips where rails disappear
%
%% ============================================================
clear; clc; close all;
load('./Output/workspace_phase4.mat');
disp('Workspace from Phase 4 loaded');

%% ----------------------------------------------------------
%  CONFIGURATION
% -----------------------------------------------------------

figNum = 80;   % <-- adjust to continue after Phase 4 figures

% --- ROI trapezoid (must match Phase 4) ---
roi_left_frac  = 0.05;
roi_right_frac = 0.95;
roi_top_left   = 0.30;
roi_top_right  = 0.70;
roi_top_y      = 0.25;

% --- Strip configuration ---
% 4 strips from top (far) to bottom (near)
% Weights control relative height — near strips are taller
% because rails are wider there and easier to detect
nStrips      = 4;
strip_weights = [0.15, 0.20, 0.28, 0.37];   % must sum to 1.0
                                               % [far ... near]

% --- Edge detector ---
best_detector = 'Canny';

% --- Hough parameters per strip ---
% Smaller fillGap/minLen for far strips (fewer pixels available)
% Larger for near strips (more pixels, wider rails)
hough_theta    = linspace(-30, 30, 180);
hough_nPeaks   = 6;
hough_fillGap  = [40,  60,  90,  120];   % one per strip, far→near
hough_minLen   = [20,  35,  50,   70];   % one per strip, far→near
min_angle_deg  = 2;

%% ----------------------------------------------------------
%  SECTION 1: STRIP-BASED HOUGH ON ALL 15 IMAGES
% -----------------------------------------------------------

% Results storage
strip_results = cell(N, 1);   % {nStrips x 2} — left/right per strip
strip_status  = zeros(N, nStrips, 2);   % 1=detected, 0=missing [img, strip, L/R]

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

    imgCx = imgW / 2;

    % --- Compute ROI y-boundaries ---
    roi_y_top = round(roi_top_y * imgH);
    roi_y_bot = imgH;
    roi_height = roi_y_bot - roi_y_top;

    % --- Compute strip y-boundaries ---
    strip_bounds = zeros(nStrips, 2);   % [y_start, y_end] per strip
    y_cursor = roi_y_top;
    for s = 1:nStrips
        h_s = round(strip_weights(s) * roi_height);
        strip_bounds(s, :) = [y_cursor, y_cursor + h_s];
        y_cursor = y_cursor + h_s;
    end
    strip_bounds(nStrips, 2) = roi_y_bot;   % ensure last strip reaches bottom

    % --- Storage for this image ---
    this_strips = cell(nStrips, 2);   % {strip, L/R}

    % --- Figure ---
    figure('Name', sprintf('Figure %d - Strip Hough: %s [%s]', figNum, [name ext], status), ...
        'NumberTitle', 'off', 'Position', [0 0 1400 700]);

    % Row 1: enhanced image with strips + final overlay
    % Row 2: edge maps per strip

    % Col 1: enhanced image with ROI and strip boundaries
    subplot(2, nStrips+1, 1);
    imshow(Ie); hold on;
    [polyX, polyY] = get_roi(imgH, imgW, ...
        roi_left_frac, roi_right_frac, roi_top_left, roi_top_right, roi_top_y);
    plot([polyX, polyX(1)], [polyY, polyY(1)], 'y-', 'LineWidth', 1.5);
    strip_colors = {'c', 'm', 'b', 'w'};
    for s = 1:nStrips
        y1 = strip_bounds(s,1); y2 = strip_bounds(s,2);
        plot([1 imgW], [y1 y1], strip_colors{s}, 'LineWidth', 1);
        text(5, y1+8, sprintf('S%d', s), 'Color', strip_colors{s}, ...
            'FontSize', 7, 'FontWeight', 'bold');
    end
    hold off;
    title(sprintf('[%d] %s\nROI + strips', i, [name ext]), ...
        'FontSize', 7, 'Color', col, 'Interpreter', 'none');

    % Process each strip
    for s = 1:nStrips

        y1 = strip_bounds(s, 1);
        y2 = strip_bounds(s, 2);

        % Build strip mask (intersection of strip rows + trapezoid)
        strip_mask_full = false(imgH, imgW);
        strip_mask_full(y1:y2, :) = true;
        [pX, pY] = get_roi(imgH, imgW, ...
            roi_left_frac, roi_right_frac, roi_top_left, roi_top_right, roi_top_y);
        trap_mask  = poly2mask(pX, pY, imgH, imgW);
        strip_mask = strip_mask_full & trap_mask;

        % Edge detection within strip
        I_edge_full = edge(Ie, best_detector);
        I_edge_strip = I_edge_full & strip_mask;

        % Hough on strip
        [H, theta, rho] = hough(I_edge_strip, 'Theta', hough_theta);
        peaks = houghpeaks(H, hough_nPeaks, 'Threshold', 0.2*max(H(:)));
        lines = houghlines(I_edge_strip, theta, rho, peaks, ...
            'FillGap', hough_fillGap(s), 'MinLength', hough_minLen(s));

        % Filter by angle
        valid = [];
        for j = 1:length(lines)
            if abs(lines(j).theta) <= (90 - min_angle_deg)
                valid = [valid, lines(j)]; %#ok<AGROW>
            end
        end

        % Split left / right by image centre
        left_cands  = [];
        right_cands = [];
        for j = 1:length(valid)
            mx = (valid(j).point1(1) + valid(j).point2(1)) / 2;
            if mx < imgCx
                left_cands  = [left_cands,  valid(j)]; %#ok<AGROW>
            else
                right_cands = [right_cands, valid(j)]; %#ok<AGROW>
            end
        end

        left_rail  = pick_longest(left_cands);
        right_rail = pick_longest(right_cands);

        this_strips{s, 1} = left_rail;
        this_strips{s, 2} = right_rail;
        strip_status(i, s, 1) = ~isempty(left_rail);
        strip_status(i, s, 2) = ~isempty(right_rail);

        % Plot edge strip
        subplot(2, nStrips+1, nStrips+1+s+1);
        imshow(I_edge_strip(y1:y2, :));
        hasL = ~isempty(left_rail);
        hasR = ~isempty(right_rail);
        title(sprintf('S%d edges\nL:%s R:%s', s, bool2str(hasL), bool2str(hasR)), ...
            'FontSize', 7);

        % Plot strip result on the strip column (top row)
        subplot(2, nStrips+1, s+1);
        imshow(Ig(y1:y2, :)); hold on;
        if ~isempty(left_rail)
            p1 = left_rail.point1;  p2 = left_rail.point2;
            % Adjust y coordinates to strip-local display
            plot([p1(1) p2(1)], [p1(2)-y1+1 p2(2)-y1+1], 'r-', 'LineWidth', 2);
        end
        if ~isempty(right_rail)
            p1 = right_rail.point1; p2 = right_rail.point2;
            plot([p1(1) p2(1)], [p1(2)-y1+1 p2(2)-y1+1], 'g-', 'LineWidth', 2);
        end
        hold off;

        if ~hasL && ~hasR
            title(sprintf('Strip %d\nNO RAILS', s), 'FontSize', 7, 'Color', [0.8 0 0]);
        elseif ~hasL || ~hasR
            title(sprintf('Strip %d\nPARTIAL', s), 'FontSize', 7, 'Color', [0.8 0.4 0]);
        else
            title(sprintf('Strip %d\nL+R OK', s), 'FontSize', 7, 'Color', [0 0.5 0]);
        end

    end

    % Col last: full overlay with all strip rails
    subplot(2, nStrips+1, nStrips+1);
    imshow(Ig); hold on;
    plot([polyX, polyX(1)], [polyY, polyY(1)], 'y--', 'LineWidth', 1);
    for s = 1:nStrips
        y1 = strip_bounds(s, 1);
        plot([1 imgW], [y1 y1], strip_colors{s}, 'LineWidth', 0.5);
        if ~isempty(this_strips{s,1})
            p1 = this_strips{s,1}.point1;
            p2 = this_strips{s,1}.point2;
            plot([p1(1) p2(1)], [p1(2) p2(2)], 'r-', 'LineWidth', 2);
        end
        if ~isempty(this_strips{s,2})
            p1 = this_strips{s,2}.point1;
            p2 = this_strips{s,2}.point2;
            plot([p1(1) p2(1)], [p1(2) p2(2)], 'g-', 'LineWidth', 2);
        end
    end
    hold off;

    % Count detected strips
    n_full    = sum(strip_status(i,:,1) & strip_status(i,:,2));
    n_missing = sum(~strip_status(i,:,1) | ~strip_status(i,:,2));
    title(sprintf('All strips\n%d/4 full  %d missing', n_full, n_missing), ...
        'FontSize', 7);

    sgtitle(sprintf('Figure %d — Strip Hough: %s  [%s]', figNum, [name ext], status), ...
        'FontSize', 11, 'FontWeight', 'bold', 'Color', col);

    strip_results{i} = this_strips;
    figNum = figNum + 1;

end

%% ----------------------------------------------------------
%  SECTION 2: STRIP DETECTION SUMMARY TABLE
%  Shows per-strip L/R detection status for all 15 images
%  Key insight: missing strips correlate with obstructions
% -----------------------------------------------------------

fprintf('\n%s\n', repmat('=', 1, 80));
fprintf('PHASE 4b — STRIP DETECTION SUMMARY\n');
fprintf('S1=far(top)  S2=mid-far  S3=mid-near  S4=near(bottom)\n');
fprintf('L=left rail  R=right rail  OK=detected  --=missing\n');
fprintf('%s\n', repmat('=', 1, 80));
fprintf('%-22s | %-6s | %-8s | %-8s | %-8s | %-8s | %s\n', ...
    'Image', 'Label', 'Strip 1', 'Strip 2', 'Strip 3', 'Strip 4', 'Score');
fprintf('%s\n', repmat('-', 1, 80));

for i = 1:N
    [~, name, ext] = fileparts(filenames{i});
    if labels(i) == 0; lbl = 'CLEAR'; else; lbl = 'OBSTR'; end

    score = 0;
    strip_strs = cell(nStrips, 1);
    for s = 1:nStrips
        hasL = strip_status(i,s,1);
        hasR = strip_status(i,s,2);
        if hasL && hasR
            strip_strs{s} = 'L+R OK ';
            score = score + 2;
        elseif hasL
            strip_strs{s} = 'L only ';
            score = score + 1;
        elseif hasR
            strip_strs{s} = 'R only ';
            score = score + 1;
        else
            strip_strs{s} = '------ ';
        end
    end

    fprintf('%-22s | %-6s | %-8s | %-8s | %-8s | %-8s | %d/8\n', ...
        [name ext], lbl, ...
        strip_strs{1}, strip_strs{2}, strip_strs{3}, strip_strs{4}, score);
end

fprintf('%s\n', repmat('=', 1, 80));

%% ----------------------------------------------------------
%  SECTION 3: OBSTRUCTION HYPOTHESIS FROM STRIP FAILURES
%  If any strip has missing rails → flag as potentially obstructed
%  Compare with ground truth labels
% -----------------------------------------------------------

fprintf('\n%s\n', repmat('=', 1, 65));
fprintf('PHASE 4b — STRIP-BASED OBSTRUCTION HYPOTHESIS\n');
fprintf('(missing rail in any strip = potential obstruction)\n');
fprintf('%s\n', repmat('=', 1, 65));
fprintf('%-22s | %-8s | %-12s | %s\n', ...
    'Image', 'GT label', 'Hypothesis', 'Match?');
fprintf('%s\n', repmat('-', 1, 65));

tp = 0; tn = 0; fp = 0; fn = 0;

for i = 1:N
    [~, name, ext] = fileparts(filenames{i});
    gt = labels(i);   % 0=clear, 1=obstructed

    % Hypothesis: obstructed if any strip is missing both rails
    missing_strips = sum(~strip_status(i,:,1) & ~strip_status(i,:,2));
    pred = missing_strips > 0;   % 1=obstructed hypothesis

    if gt == 0; gt_str = 'CLEAR'; else; gt_str = 'OBSTR'; end
    if pred;    pred_str = 'OBSTRUCTED'; else; pred_str = 'CLEAR'; end

    match = (gt == pred);
    if match; match_str = 'OK'; else; match_str = 'WRONG'; end

    fprintf('%-22s | %-8s | %-12s | %s\n', ...
        [name ext], gt_str, pred_str, match_str);

    if pred && gt;      tp = tp + 1; end
    if ~pred && ~gt;    tn = tn + 1; end
    if pred && ~gt;     fp = fp + 1; end
    if ~pred && gt;     fn = fn + 1; end
end

fprintf('%s\n', repmat('=', 1, 65));
fprintf('TP=%d  TN=%d  FP=%d  FN=%d\n', tp, tn, fp, fn);
if (tp+fp) > 0
    precision = tp / (tp + fp);
    fprintf('Precision:  %.3f\n', precision);
end
if (tp+fn) > 0
    recall = tp / (tp + fn);
    fprintf('Recall:     %.3f\n', recall);
end
if (tp+fp) > 0 && (tp+fn) > 0
    f1 = 2 * precision * recall / (precision + recall);
    fprintf('F1 score:   %.3f\n', f1);
end
accuracy = (tp + tn) / N;
fprintf('Accuracy:   %.3f  (%d/%d correct)\n', accuracy, tp+tn, N);
fprintf('%s\n', repmat('=', 1, 65));

%% ----------------------------------------------------------
%  SECTION 4: SAVE WORKSPACE
% -----------------------------------------------------------

save('./Output/workspace_phase4b.mat', ...
    'images', 'images_gray', 'images_enhanced', ...
    'filenames', 'labels', 'descriptions', 'N', ...
    'enhance_log', 'rail_lines_all', 'strip_results', ...
    'strip_status', 'strip_bounds', ...
    'best_detector', 'hough_nPeaks', ...
    'hough_fillGap', 'hough_minLen', 'hough_theta', ...
    'roi_left_frac', 'roi_right_frac', ...
    'roi_top_left', 'roi_top_right', 'roi_top_y', ...
    'nStrips', 'strip_weights');

fprintf('\nWorkspace saved to ./Output/workspace_phase4b.mat\n');

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
%BOOL2STR Returns 'YES' or 'NO' from a boolean value.
    if b; s = 'YES'; else; s = 'NO'; end
end