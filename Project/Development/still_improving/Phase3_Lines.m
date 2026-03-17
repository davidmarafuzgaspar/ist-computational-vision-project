%% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 1e - Strip-Based Hough on Binary Images
%  Input: binary images from Phase 1b (CLAHE → Gaussian → Otsu)
%  Divides ROI into strips and runs Hough per strip to detect
%  left and right rail lines
%
%% ============================================================
clear; clc; close all;
load('./Output/workspace_phase2.mat');
disp('Workspace from Phase 1b loaded');

figNum = 25;

%% ----------------------------------------------------------
%  CONFIGURATION
% -----------------------------------------------------------

% --- ROI trapezoid ---
roi_left_frac  = 0.05;
roi_right_frac = 0.95;
roi_top_left   = 0.30;
roi_top_right  = 0.70;
roi_top_y      = 0.25;

% --- Strip configuration ---
nStrips       = 4;
strip_weights = [0.15, 0.20, 0.28, 0.37];   % far → near

% --- Hough parameters per strip (far → near) ---
hough_theta   = linspace(-30, 30, 180);   % near-vertical only
hough_nPeaks  = 6;
hough_fillGap = [30,  50,  80,  120];
hough_minLen  = [15,  25,  40,   60];
min_angle_deg = 2;

%% ----------------------------------------------------------
%  SECTION 1: STRIP HOUGH ON ALL 15 IMAGES
% -----------------------------------------------------------

rail_lines_all = cell(N, 1);
strip_status   = zeros(N, nStrips, 2);   % [img, strip, L/R]

for i = 1:N

    I_bin = images_bin{i};
    Ig    = images_gray{i};
    I_ref = images_filt{i};
    [imgH, imgW] = size(I_bin);
    [~, name, ext] = fileparts(filenames{i});
    imgCx = imgW / 2;

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
        strip_bounds(s,:) = [y_cursor, min(y_cursor+h_s, imgH)];
        y_cursor = strip_bounds(s,2);
    end
    strip_bounds(nStrips,2) = imgH;

    % --- Trapezoid mask ---
    [polyX, polyY] = get_roi(imgH, imgW, ...
        roi_left_frac, roi_right_frac, roi_top_left, roi_top_right, roi_top_y);
    trap_mask = poly2mask(polyX, polyY, imgH, imgW);

    this_strips  = cell(nStrips, 2);
    strip_colors = {'c', 'm', 'b', 'w'};

    % --- Figure ---
    figure('Name', sprintf('Figure %d - Strip Hough: %s [%s]', figNum, [name ext], status), ...
        'NumberTitle', 'off', 'Position', [0 0 1400 600]);

    % Col 1: filtered image + ROI + strip lines
    subplot(2, nStrips+1, 1);
    imshow(I_ref); hold on;
    plot([polyX, polyX(1)], [polyY, polyY(1)], 'y-', 'LineWidth', 1.5);
    for s = 1:nStrips
        y1 = strip_bounds(s,1);
        plot([1 imgW], [y1 y1], strip_colors{s}, 'LineWidth', 1);
        text(5, y1+8, sprintf('S%d',s), 'Color', strip_colors{s}, ...
            'FontSize', 7, 'FontWeight', 'bold');
    end
    hold off;
    title(sprintf('[%d] %s\nFiltered + strips', i, [name ext]), ...
        'FontSize', 7, 'Color', col, 'Interpreter', 'none');

    % Col last: full overlay on grayscale
    ax_overlay = subplot(2, nStrips+1, nStrips+1);
    imshow(Ig); hold on;
    plot([polyX, polyX(1)], [polyY, polyY(1)], 'y--', 'LineWidth', 1);

    for s = 1:nStrips

        y1 = strip_bounds(s,1);
        y2 = strip_bounds(s,2);

        % Crop binary strip + apply mask
        bw_strip   = I_bin(y1:y2, :) & trap_mask(y1:y2, :);

        % --- Hough on binary strip ---
        [H, theta, rho] = hough(bw_strip, 'Theta', hough_theta);
        peaks = houghpeaks(H, hough_nPeaks, 'Threshold', 0.2*max(H(:)));
        lines = houghlines(bw_strip, theta, rho, peaks, ...
            'FillGap', hough_fillGap(s), 'MinLength', hough_minLen(s));

        % --- Filter by angle ---
        valid = [];
        for j = 1:length(lines)
            if abs(lines(j).theta) <= (90 - min_angle_deg)
                valid = [valid, lines(j)]; %#ok<AGROW>
            end
        end

        % --- Split left / right ---
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

        this_strips{s,1} = left_rail;
        this_strips{s,2} = right_rail;
        strip_status(i,s,1) = ~isempty(left_rail);
        strip_status(i,s,2) = ~isempty(right_rail);

        hasL = ~isempty(left_rail);
        hasR = ~isempty(right_rail);

        % --- Row 2: binary strip + detected lines ---
        subplot(2, nStrips+1, nStrips+1+s+1);
        imshow(bw_strip); hold on;
        if hasL
            p1 = left_rail.point1;  p2 = left_rail.point2;
            plot([p1(1) p2(1)], [p1(2) p2(2)], 'r-', 'LineWidth', 2);
        end
        if hasR
            p1 = right_rail.point1; p2 = right_rail.point2;
            plot([p1(1) p2(1)], [p1(2) p2(2)], 'g-', 'LineWidth', 2);
        end
        hold off;
        title(sprintf('S%d binary\nL:%s R:%s', s, bool2str(hasL), bool2str(hasR)), ...
            'FontSize', 7);

        % --- Row 1, col s+1: grayscale strip + lines ---
        subplot(2, nStrips+1, s+1);
        imshow(Ig(y1:y2,:)); hold on;
        if hasL
            p1 = left_rail.point1;  p2 = left_rail.point2;
            plot([p1(1) p2(1)], [p1(2) p2(2)], 'r-', 'LineWidth', 2);
        end
        if hasR
            p1 = right_rail.point1; p2 = right_rail.point2;
            plot([p1(1) p2(1)], [p1(2) p2(2)], 'g-', 'LineWidth', 2);
        end
        hold off;
        if ~hasL && ~hasR
            title(sprintf('S%d — NO RAILS', s), 'FontSize', 7, 'Color', [0.8 0 0]);
        elseif ~hasL || ~hasR
            title(sprintf('S%d — PARTIAL',  s), 'FontSize', 7, 'Color', [0.8 0.4 0]);
        else
            title(sprintf('S%d — L+R OK',   s), 'FontSize', 7, 'Color', [0 0.5 0]);
        end

        % --- Full overlay ---
        subplot(ax_overlay); hold on;
        plot([1 imgW], [y1 y1], strip_colors{s}, 'LineWidth', 0.5);
        if hasL
            p1 = left_rail.point1;  p2 = left_rail.point2;
            plot([p1(1) p2(1)], [p1(2)+y1-1 p2(2)+y1-1], 'r-', 'LineWidth', 2);
        end
        if hasR
            p1 = right_rail.point1; p2 = right_rail.point2;
            plot([p1(1) p2(1)], [p1(2)+y1-1 p2(2)+y1-1], 'g-', 'LineWidth', 2);
        end

    end

    subplot(ax_overlay); hold off;
    n_full = sum(strip_status(i,:,1) & strip_status(i,:,2));
    title(sprintf('All strips\n%d/4 full', n_full), 'FontSize', 7);

    sgtitle(sprintf('Figure %d — Strip Hough (binary): %s  [%s]', figNum, [name ext], status), ...
        'FontSize', 11, 'FontWeight', 'bold', 'Color', col);

    rail_lines_all{i} = this_strips;
    figNum = figNum + 1;

end

%% ----------------------------------------------------------
%  SECTION 2: STRIP DETECTION SUMMARY TABLE
% -----------------------------------------------------------

fprintf('\n%s\n', repmat('=', 1, 80));
fprintf('PHASE 1e — STRIP HOUGH ON BINARY IMAGES\n');
fprintf('S1=far  S2=mid-far  S3=mid-near  S4=near\n');
fprintf('%s\n', repmat('=', 1, 80));
fprintf('%-22s | %-6s | %-8s | %-8s | %-8s | %-8s | %s\n', ...
    'Image', 'Label', 'Strip 1', 'Strip 2', 'Strip 3', 'Strip 4', 'Score');
fprintf('%s\n', repmat('-', 1, 80));

for i = 1:N
    [~, name, ext] = fileparts(filenames{i});
    if labels(i) == 0; lbl = 'CLEAR'; else; lbl = 'OBSTR'; end
    score = 0;
    strip_strs = cell(nStrips,1);
    for s = 1:nStrips
        hasL = strip_status(i,s,1);
        hasR = strip_status(i,s,2);
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
        [name ext], lbl, strip_strs{1}, strip_strs{2}, ...
        strip_strs{3}, strip_strs{4}, score);
end
fprintf('%s\n', repmat('=', 1, 80));

%% ----------------------------------------------------------
%  SECTION 3: OBSTRUCTION HYPOTHESIS + METRICS
% -----------------------------------------------------------

fprintf('\n%s\n', repmat('=', 1, 65));
fprintf('PHASE 1e — OBSTRUCTION HYPOTHESIS VS GROUND TRUTH\n');
fprintf('%s\n', repmat('=', 1, 65));
fprintf('%-22s | %-8s | %-12s | %s\n', 'Image', 'GT label', 'Hypothesis', 'Match?');
fprintf('%s\n', repmat('-', 1, 65));

tp=0; tn=0; fp=0; fn=0;

for i = 1:N
    [~, name, ext] = fileparts(filenames{i});
    gt   = labels(i);
    miss = sum(~strip_status(i,:,1) & ~strip_status(i,:,2));
    pred = miss > 0;

    if gt==0;  gt_str='CLEAR';       else; gt_str='OBSTR';        end
    if pred;   pred_str='OBSTRUCTED'; else; pred_str='CLEAR';      end
    if gt==pred; match_str='OK';     else; match_str='WRONG';      end

    fprintf('%-22s | %-8s | %-12s | %s\n', [name ext], gt_str, pred_str, match_str);

    if  pred &&  gt; tp=tp+1; end
    if ~pred && ~gt; tn=tn+1; end
    if  pred && ~gt; fp=fp+1; end
    if ~pred &&  gt; fn=fn+1; end
end

fprintf('%s\n', repmat('=', 1, 65));
fprintf('TP=%d  TN=%d  FP=%d  FN=%d\n', tp, tn, fp, fn);
if (tp+fp)>0; fprintf('Precision:  %.3f\n', tp/(tp+fp)); end
if (tp+fn)>0; fprintf('Recall:     %.3f\n', tp/(tp+fn)); end
if (tp+fp)>0 && (tp+fn)>0
    p=tp/(tp+fp); r=tp/(tp+fn);
    fprintf('F1 score:   %.3f\n', 2*p*r/(p+r));
end
fprintf('Accuracy:   %.3f  (%d/%d correct)\n', (tp+tn)/N, tp+tn, N);
fprintf('%s\n', repmat('=', 1, 65));

%% ----------------------------------------------------------
%  SAVE WORKSPACE
% -----------------------------------------------------------

save('./Output/workspace_phase1e.mat', ...
    'images', 'images_gray', 'images_filt', 'images_bin', ...
    'filenames', 'labels', 'descriptions', 'N', ...
    'rail_lines_all', 'strip_status', ...
    'clahe_tiles', 'clahe_clip', 'gaus_sigma', 'gaus_size', ...
    'roi_left_frac', 'roi_right_frac', ...
    'roi_top_left', 'roi_top_right', 'roi_top_y', ...
    'nStrips', 'strip_weights');

fprintf('\nWorkspace saved to ./Output/workspace_phase1e.mat\n');

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
%PICK_LONGEST Returns the longest line from a houghlines array.
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