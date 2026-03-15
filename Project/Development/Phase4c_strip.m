%% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 4c - Strip-Based Adaptive Threshold Rail Detection
%  Divide ROI into horizontal strips, binarize each strip
%  with adaptive threshold, clean with morphology, then
%  analyse connected regions to find left/right rail candidates
%
%% ============================================================
clear; clc; close all;
load('./Output/workspace_phase4b.mat');
disp('Workspace from Phase 4b loaded');

%% ----------------------------------------------------------
%  CONFIGURATION
% -----------------------------------------------------------

figNum = 120;   % <-- adjust to continue after Phase 4b figures

% --- ROI trapezoid (must match previous phases) ---
roi_left_frac  = 0.05;
roi_right_frac = 0.95;
roi_top_left   = 0.30;
roi_top_right  = 0.70;
roi_top_y      = 0.25;

% --- Strip configuration ---
nStrips       = 4;
strip_weights = [0.15, 0.20, 0.28, 0.37];   % far → near, must sum to 1.0

% --- Adaptive threshold parameters ---
sensitivity   = 0.4;          % from your experiments (try 0.3, 0.4, 0.5)
fg_polarity   = 'bright';     % rails are bright structures

% --- Morphological cleanup ---
open_radius   = 2;            % imopen disk radius to remove small noise blobs
                               % (try 1, 2, 3)
close_radius  = 4;            % imclose disk radius to fill gaps in rail blobs
                               % (try 3, 5, 8)

% --- Rail candidate criteria ---
% A connected region in a strip is considered a rail candidate if:
min_area      = 50;           % minimum blob area in pixels   (try 30, 80)
max_area_frac = 0.35;         % maximum blob area as fraction of strip area
                               % (rejects large background blobs)
max_x_width   = 0.25;         % max blob width as fraction of strip width
                               % (rails are narrow)

%% ----------------------------------------------------------
%  SECTION 1: ADAPTIVE THRESHOLD ON ALL 15 IMAGES
%  Per image, per strip:
%    1. Crop strip + apply trapezoid mask
%    2. Adaptive binarize with sensitivity 0.4
%    3. imopen to remove noise, imclose to fill rail gaps
%    4. regionprops to find rail-like blobs
%    5. Split blobs left/right of strip centre
%    6. Flag strip as detected/missing
% -----------------------------------------------------------

strip_results_c  = cell(N, 1);
strip_status_c   = zeros(N, nStrips, 2);   % [img, strip, L/R]
strip_scores_c   = zeros(N, nStrips);      % continuity score per strip

se_open  = strel('disk', open_radius);
se_close = strel('disk', close_radius);

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

    % --- ROI y-boundaries ---
    roi_y_top  = round(roi_top_y * imgH);
    roi_height = imgH - roi_y_top;

    % --- Strip y-boundaries ---
    strip_bounds = zeros(nStrips, 2);
    y_cursor = roi_y_top;
    for s = 1:nStrips
        h_s = round(strip_weights(s) * roi_height);
        strip_bounds(s, :) = [y_cursor, min(y_cursor + h_s, imgH)];
        y_cursor = strip_bounds(s, 2);
    end
    strip_bounds(nStrips, 2) = imgH;

    % --- Full trapezoid mask ---
    [polyX, polyY] = get_roi(imgH, imgW, ...
        roi_left_frac, roi_right_frac, roi_top_left, roi_top_right, roi_top_y);
    trap_mask = poly2mask(polyX, polyY, imgH, imgW);

    % --- Storage ---
    this_strips = cell(nStrips, 2);   % {strip, L/R} → regionprops struct or []

    % --- Figure ---
    figure('Name', sprintf('Figure %d - AdaptThresh: %s [%s]', figNum, [name ext], status), ...
        'NumberTitle', 'off', 'Position', [0 0 1500 700]);

    strip_colors = {'c', 'm', 'b', 'w'};

    % Col 1 row 1: enhanced + ROI + strip lines
    subplot(3, nStrips+1, 1);
    imshow(Ie); hold on;
    plot([polyX, polyX(1)], [polyY, polyY(1)], 'y-', 'LineWidth', 1.5);
    for s = 1:nStrips
        y1 = strip_bounds(s,1);
        plot([1 imgW], [y1 y1], strip_colors{s}, 'LineWidth', 1);
        text(5, y1+8, sprintf('S%d', s), 'Color', strip_colors{s}, ...
            'FontSize', 7, 'FontWeight', 'bold');
    end
    hold off;
    title(sprintf('[%d] %s\nEnhanced + strips', i, [name ext]), ...
        'FontSize', 7, 'Color', col, 'Interpreter', 'none');

    % Col last row 1: full overlay
    ax_overlay = subplot(3, nStrips+1, nStrips+1);
    imshow(Ig); hold on;
    plot([polyX, polyX(1)], [polyY, polyY(1)], 'y--', 'LineWidth', 1);

    for s = 1:nStrips

        y1 = strip_bounds(s, 1);
        y2 = strip_bounds(s, 2);
        strip_h = y2 - y1 + 1;
        strip_w = imgW;

        % --- Crop strip ---
        Ie_strip   = Ie(y1:y2, :);
        Ig_strip   = Ig(y1:y2, :);
        mask_strip = trap_mask(y1:y2, :);

        % --- Adaptive binarize ---
        bw_raw   = imbinarize(Ie_strip, 'adaptive', ...
            'ForegroundPolarity', fg_polarity, 'Sensitivity', sensitivity);
        bw_raw   = bw_raw & mask_strip;

        % --- Morphological cleanup ---
        bw_open  = imopen(bw_raw,  se_open);
        bw_clean = imclose(bw_open, se_close);
        bw_clean = bw_clean & mask_strip;   % re-apply mask after morphology

        % --- Region properties ---
        props = regionprops(bw_clean, 'Area', 'BoundingBox', 'Centroid', 'PixelList');

        strip_area = sum(mask_strip(:));

        % --- Filter rail-like blobs ---
        left_blobs  = [];
        right_blobs = [];
        cx_strip    = strip_w / 2;

        for b = 1:length(props)
            area   = props(b).Area;
            bb     = props(b).BoundingBox;   % [x y w h]
            blob_w = bb(3);

            % Reject too small, too large, or too wide blobs
            if area < min_area; continue; end
            if area > max_area_frac * strip_area; continue; end
            if blob_w > max_x_width * strip_w; continue; end

            % Assign left / right by centroid x
            if props(b).Centroid(1) < cx_strip
                left_blobs  = [left_blobs,  props(b)]; %#ok<AGROW>
            else
                right_blobs = [right_blobs, props(b)]; %#ok<AGROW>
            end
        end

        % Keep largest blob from each side
        left_rail  = pick_largest(left_blobs);
        right_rail = pick_largest(right_blobs);

        this_strips{s, 1} = left_rail;
        this_strips{s, 2} = right_rail;
        strip_status_c(i, s, 1) = ~isempty(left_rail);
        strip_status_c(i, s, 2) = ~isempty(right_rail);

        hasL = ~isempty(left_rail);
        hasR = ~isempty(right_rail);

        % --- Plot: raw binary strip (row 2) ---
        subplot(3, nStrips+1, (nStrips+1) + s + 1);
        imshow(bw_raw);
        title(sprintf('S%d raw\ns=%.1f', s, sensitivity), 'FontSize', 7);

        % --- Plot: cleaned binary strip (row 3) ---
        subplot(3, nStrips+1, 2*(nStrips+1) + s + 1);
        imshow(bw_clean);
        title(sprintf('S%d clean\nL:%s R:%s', s, bool2str(hasL), bool2str(hasR)), ...
            'FontSize', 7);

        % --- Plot: strip result (row 1, col s+1) ---
        subplot(3, nStrips+1, s+1);
        imshow(Ig_strip); hold on;
        if hasL
            px = left_rail.PixelList;
            plot(px(:,1), px(:,2), 'r.', 'MarkerSize', 1);
            cx = left_rail.Centroid(1);
            plot([cx cx], [1 strip_h], 'r--', 'LineWidth', 1);
        end
        if hasR
            px = right_rail.PixelList;
            plot(px(:,1), px(:,2), 'g.', 'MarkerSize', 1);
            cx = right_rail.Centroid(1);
            plot([cx cx], [1 strip_h], 'g--', 'LineWidth', 1);
        end
        hold off;
        if ~hasL && ~hasR
            title(sprintf('S%d — NO RAILS', s), 'FontSize', 7, 'Color', [0.8 0 0]);
        elseif ~hasL || ~hasR
            title(sprintf('S%d — PARTIAL', s),  'FontSize', 7, 'Color', [0.8 0.4 0]);
        else
            title(sprintf('S%d — L+R OK', s),   'FontSize', 7, 'Color', [0 0.5 0]);
        end

        % --- Overlay on full image ---
        subplot(ax_overlay);
        hold on;
        plot([1 imgW], [y1 y1], strip_colors{s}, 'LineWidth', 0.5);
        if hasL
            px = left_rail.PixelList;
            plot(px(:,1), px(:,2) + y1 - 1, 'r.', 'MarkerSize', 1);
        end
        if hasR
            px = right_rail.PixelList;
            plot(px(:,1), px(:,2) + y1 - 1, 'g.', 'MarkerSize', 1);
        end

    end

    subplot(ax_overlay);
    hold off;
    n_full = sum(strip_status_c(i,:,1) & strip_status_c(i,:,2));
    title(sprintf('All strips\n%d/4 full', n_full), 'FontSize', 7);

    sgtitle(sprintf('Figure %d — Strip Adaptive Threshold: %s  [%s]', ...
        figNum, [name ext], status), ...
        'FontSize', 11, 'FontWeight', 'bold', 'Color', col);

    strip_results_c{i} = this_strips;
    figNum = figNum + 1;

end

%% ----------------------------------------------------------
%  SECTION 2: STRIP DETECTION SUMMARY TABLE
% -----------------------------------------------------------

fprintf('\n%s\n', repmat('=', 1, 80));
fprintf('PHASE 4c — STRIP ADAPTIVE THRESHOLD SUMMARY\n');
fprintf('Sensitivity=%.1f  open_r=%d  close_r=%d\n', ...
    sensitivity, open_radius, close_radius);
fprintf('S1=far  S2=mid-far  S3=mid-near  S4=near\n');
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
        hasL = strip_status_c(i,s,1);
        hasR = strip_status_c(i,s,2);
        if hasL && hasR
            strip_strs{s} = 'L+R OK '; score = score + 2;
        elseif hasL
            strip_strs{s} = 'L only '; score = score + 1;
        elseif hasR
            strip_strs{s} = 'R only '; score = score + 1;
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
%  SECTION 3: OBSTRUCTION HYPOTHESIS + METRICS
%  Missing rail in any strip → flag as obstructed
%  Compare against ground truth, compute precision/recall/F1
% -----------------------------------------------------------

fprintf('\n%s\n', repmat('=', 1, 65));
fprintf('PHASE 4c — OBSTRUCTION HYPOTHESIS VS GROUND TRUTH\n');
fprintf('%s\n', repmat('=', 1, 65));
fprintf('%-22s | %-8s | %-12s | %s\n', ...
    'Image', 'GT label', 'Hypothesis', 'Match?');
fprintf('%s\n', repmat('-', 1, 65));

tp = 0; tn = 0; fp = 0; fn = 0;

for i = 1:N
    [~, name, ext] = fileparts(filenames{i});
    gt = labels(i);

    missing = sum(~strip_status_c(i,:,1) & ~strip_status_c(i,:,2));
    pred    = missing > 0;

    if gt == 0; gt_str = 'CLEAR'; else; gt_str = 'OBSTR'; end
    if pred;    pred_str = 'OBSTRUCTED'; else; pred_str = 'CLEAR'; end
    if (gt == pred); match_str = 'OK'; else; match_str = 'WRONG'; end

    fprintf('%-22s | %-8s | %-12s | %s\n', ...
        [name ext], gt_str, pred_str, match_str);

    if  pred &&  gt;  tp = tp + 1; end
    if ~pred && ~gt;  tn = tn + 1; end
    if  pred && ~gt;  fp = fp + 1; end
    if ~pred &&  gt;  fn = fn + 1; end
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
fprintf('Accuracy:   %.3f  (%d/%d correct)\n', (tp+tn)/N, tp+tn, N);
fprintf('%s\n', repmat('=', 1, 65));

%% ----------------------------------------------------------
%  SECTION 4: COMPARE 4b (Hough) vs 4c (Adaptive) ACCURACY
% -----------------------------------------------------------

fprintf('\n%s\n', repmat('=', 1, 50));
fprintf('COMPARISON: Phase 4b (Hough) vs Phase 4c (Adaptive)\n');
fprintf('%s\n', repmat('=', 1, 50));

% Recompute Phase 4b accuracy from strip_status
tp4b=0; tn4b=0; fp4b=0; fn4b=0;
for i = 1:N
    gt   = labels(i);
    miss = sum(~strip_status(i,:,1) & ~strip_status(i,:,2));
    pred = miss > 0;
    if  pred &&  gt; tp4b=tp4b+1; end
    if ~pred && ~gt; tn4b=tn4b+1; end
    if  pred && ~gt; fp4b=fp4b+1; end
    if ~pred &&  gt; fn4b=fn4b+1; end
end

acc4b = (tp4b+tn4b)/N;
acc4c = (tp+tn)/N;

fprintf('%-30s | %s\n', 'Metric', 'Phase 4b (Hough) | Phase 4c (Adaptive)');
fprintf('%s\n', repmat('-', 1, 60));
fprintf('%-30s | %.3f            | %.3f\n', 'Accuracy',  acc4b, acc4c);
if (tp4b+fp4b)>0 && (tp+fp)>0
    p4b = tp4b/(tp4b+fp4b); p4c = tp/(tp+fp);
    fprintf('%-30s | %.3f            | %.3f\n', 'Precision', p4b,  p4c);
end
if (tp4b+fn4b)>0 && (tp+fn)>0
    r4b = tp4b/(tp4b+fn4b); r4c = tp/(tp+fn);
    fprintf('%-30s | %.3f            | %.3f\n', 'Recall',    r4b,  r4c);
    if (tp4b+fp4b)>0 && (tp+fp)>0
        f4b = 2*p4b*r4b/(p4b+r4b);
        f4c = 2*p4c*r4c/(p4c+r4c);
        fprintf('%-30s | %.3f            | %.3f\n', 'F1 score',  f4b,  f4c);
    end
end
fprintf('%s\n', repmat('=', 1, 50));

%% ----------------------------------------------------------
%  SECTION 5: SAVE WORKSPACE
% -----------------------------------------------------------

save('./Output/workspace_phase4c.mat', ...
    'images', 'images_gray', 'images_enhanced', ...
    'filenames', 'labels', 'descriptions', 'N', ...
    'enhance_log', 'rail_lines_all', ...
    'strip_results', 'strip_status', ...
    'strip_results_c', 'strip_status_c', ...
    'sensitivity', 'open_radius', 'close_radius', ...
    'min_area', 'max_area_frac', 'max_x_width', ...
    'roi_left_frac', 'roi_right_frac', ...
    'roi_top_left', 'roi_top_right', 'roi_top_y', ...
    'nStrips', 'strip_weights');

fprintf('\nWorkspace saved to ./Output/workspace_phase4c.mat\n');

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

function best = pick_largest(blob_array)
%PICK_LARGEST Returns the blob with the largest area from a regionprops array.
    best = [];
    if isempty(blob_array); return; end
    [~, idx] = max([blob_array.Area]);
    best = blob_array(idx);
end

function s = bool2str(b)
%BOOL2STR Returns 'YES' or 'NO' from a boolean value.
    if b; s = 'YES'; else; s = 'NO'; end
end