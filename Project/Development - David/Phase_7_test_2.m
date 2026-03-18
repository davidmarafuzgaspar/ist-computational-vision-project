% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 7B - Indirect Obstacle Detection via Anomaly Detection
%             Method A: HSV Thresholding
%             Method B: Baseline Intensity Comparison
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
%  SECTION 1: SELECT TARGET IMAGES AND BASELINE IMAGES
% -----------------------------------------------------------

% Images to test anomaly detection on
target_names = {'p8.jpg', 'Frame1253.jpg', 'image04054.jpg'};

% Representative CLEAR images used to learn baseline track appearance.
% These should be well-lit, straight, unobstructed track images.
baseline_names = {'Frame1253.jpg', 'Frame1291.jpg', 'image02293.jpg'};

num_targets  = length(target_names);
num_baseline = length(baseline_names);

% --- Load target images ---
img_indices  = zeros(num_targets, 1);
pts_left_all  = cell(num_targets, 1);
pts_right_all = cell(num_targets, 1);
imgs          = cell(num_targets, 1);
img_sizes     = zeros(num_targets, 2);

for t = 1:num_targets
    target_name = target_names{t};

    img_idx = [];
    for i = 1:N
        [~, name, ext] = fileparts(filenames{i});
        if strcmp([name ext], target_name)
            img_idx = i;
            break;
        end
    end

    gt_idx = [];
    for j = 1:length(gt)
        if strcmp(gt(j).filename, target_name)
            gt_idx = j;
            break;
        end
    end

    if isempty(img_idx) || isempty(gt_idx)
        warning('Skipping %s — not found.', target_name);
        continue;
    end

    img_indices(t)   = img_idx;
    pts_left_all{t}  = gt(gt_idx).left;
    pts_right_all{t} = gt(gt_idx).right;
    imgs{t}          = images{img_idx};
    [h, w, ~]        = size(images{img_idx});
    img_sizes(t, :)  = [h, w];

    fprintf('[%d] %s loaded\n', t, target_name);
end

%% ----------------------------------------------------------
%  SECTION 2: BUILD BASELINE FROM CLEAR IMAGES
% -----------------------------------------------------------

% Collect all ROI pixels from clear baseline images in HSV and grayscale
baseline_hsv_pixels  = [];
baseline_gray_pixels = [];

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

    if isempty(b_idx)
        warning('Baseline image not found: %s', bname);
        continue;
    end

    b_img      = images{b_idx};
    b_roi_mask = masks{b_idx};

    % Extract ROI pixels in HSV
    b_hsv = rgb2hsv(b_img);
    for c = 1:3
        ch = b_hsv(:,:,c);
        baseline_hsv_pixels(:, end+1) = ch(b_roi_mask); %#ok<AGROW>
    end

    % Extract ROI pixels in grayscale
    b_gray = rgb2gray(b_img);
    baseline_gray_pixels = [baseline_gray_pixels; ...
        double(b_gray(b_roi_mask))]; %#ok<AGROW>

    fprintf('Baseline loaded: %s (%d ROI pixels)\n', bname, sum(b_roi_mask(:)));
end

% Compute baseline statistics for each HSV channel
baseline_hsv_mean = mean(baseline_hsv_pixels, 1);
baseline_hsv_std  = std(baseline_hsv_pixels,  0, 1);

% Compute baseline grayscale distribution (mean and std)
baseline_gray_mean = mean(baseline_gray_pixels);
baseline_gray_std  = std(baseline_gray_pixels);

fprintf('\nBaseline grayscale: mean=%.1f  std=%.1f\n', ...
    baseline_gray_mean, baseline_gray_std);
fprintf('Baseline HSV:  H=%.3f±%.3f  S=%.3f±%.3f  V=%.3f±%.3f\n', ...
    baseline_hsv_mean(1), baseline_hsv_std(1), ...
    baseline_hsv_mean(2), baseline_hsv_std(2), ...
    baseline_hsv_mean(3), baseline_hsv_std(3));

%% ----------------------------------------------------------
%  SECTION 3: PARAMETERS
% -----------------------------------------------------------

poly_degree = 2;
se_anomaly  = strel('square', 15);

% METHOD A — HSV thresholding
% How many standard deviations from baseline to flag as anomaly.
% Lower = more sensitive, higher = more conservative.
hsv_sigma_thresh = 2.0;

% METHOD B — Intensity distribution comparison
% Pixels whose intensity deviates more than this many std devs
% from the baseline mean are flagged as anomalies.
gray_sigma_thresh = 2.5;

%% ----------------------------------------------------------
%  SECTION 4: ANOMALY DETECTION LOOP
% -----------------------------------------------------------

anomaly_hsv    = cell(num_targets, 3);  % {t, region}
anomaly_gray   = cell(num_targets, 3);
flags_hsv      = false(num_targets, 1);
flags_gray     = false(num_targets, 1);
anomaly_ratios = zeros(num_targets, 3, 2); % [t, region, method]

for t = 1:num_targets

    if img_indices(t) == 0
        continue;
    end

    img      = imgs{t};
    h        = img_sizes(t, 1);
    w        = img_sizes(t, 2);
    i        = img_indices(t);
    roi_mask = masks{i};

    pts_left  = pts_left_all{t};
    pts_right = pts_right_all{t};

    fprintf('\nProcessing [%d/%d]: %s\n', t, num_targets, target_names{t});

    % --- Polynomial fit to curved rails ---
    p_left  = polyfit(pts_left(:,2),  pts_left(:,1),  poly_degree);
    p_right = polyfit(pts_right(:,2), pts_right(:,1), poly_degree);

    [X, Y]      = meshgrid(1:w, 1:h);
    x_left_map  = polyval(p_left,  Y);
    x_right_map = polyval(p_right, Y);

    left_region   = (X < x_left_map)  & roi_mask;
    right_region  = (X > x_right_map) & roi_mask;
    middle_region = (X >= x_left_map) & (X <= x_right_map) & roi_mask;

    region_masks = {left_region, middle_region, right_region};
    region_names = {'Left', 'Middle', 'Right'};

    % Convert image to HSV and grayscale once per image
    img_hsv  = rgb2hsv(img);
    img_gray = double(rgb2gray(img));

    for r = 1:3
        reg_mask   = region_masks{r};
        num_pixels = sum(reg_mask(:));

        if num_pixels == 0
            anomaly_hsv{t,r}  = false(h, w);
            anomaly_gray{t,r} = false(h, w);
            continue;
        end

        % -------------------------------------------------------
        % METHOD A: HSV colour thresholding
        % Flag pixels whose HSV values deviate from the baseline
        % by more than hsv_sigma_thresh standard deviations in
        % any of the three channels. Grey ballast has low
        % saturation (S≈0) and mid-range value (V≈0.4-0.6).
        % Rocks, vegetation, or foreign objects deviate from this.
        % -------------------------------------------------------
        hsv_anomaly = false(h, w);
        for c = 1:3
            ch          = img_hsv(:,:,c);
            deviation   = abs(ch - baseline_hsv_mean(c));
            channel_anom = deviation > (hsv_sigma_thresh * baseline_hsv_std(c));
            hsv_anomaly  = hsv_anomaly | channel_anom;
        end

        % Restrict to current region and refine with morphology
        hsv_anomaly       = hsv_anomaly & reg_mask;
        hsv_anomaly_ref   = imopen(imclose(hsv_anomaly, se_anomaly), se_anomaly);
        anomaly_hsv{t, r} = hsv_anomaly_ref;

        % -------------------------------------------------------
        % METHOD B: Grayscale intensity deviation from baseline
        % Flag pixels whose intensity deviates from the baseline
        % mean by more than gray_sigma_thresh standard deviations.
        % Dark rocks or bright foreign objects both get flagged.
        % -------------------------------------------------------
        gray_deviation     = abs(img_gray - baseline_gray_mean);
        gray_anomaly       = gray_deviation > (gray_sigma_thresh * baseline_gray_std);
        gray_anomaly       = gray_anomaly & reg_mask;
        gray_anomaly_ref   = imopen(imclose(gray_anomaly, se_anomaly), se_anomaly);
        anomaly_gray{t, r} = gray_anomaly_ref;

        % Anomaly ratio: fraction of region pixels flagged as anomalous
        anomaly_ratios(t, r, 1) = sum(hsv_anomaly_ref(:))  / num_pixels;
        anomaly_ratios(t, r, 2) = sum(gray_anomaly_ref(:)) / num_pixels;

        fprintf('  [%s] HSV ratio=%.3f  Gray ratio=%.3f\n', ...
            region_names{r}, ...
            anomaly_ratios(t, r, 1), ...
            anomaly_ratios(t, r, 2));
    end

    % Flag image as having indirect obstacle if any region anomaly
    % ratio exceeds the detection threshold
    anomaly_thresh    = 0.05;  % >5% of region pixels flagged = obstacle
    flags_hsv(t)      = any(anomaly_ratios(t, :, 1) > anomaly_thresh);
    flags_gray(t)     = any(anomaly_ratios(t, :, 2) > anomaly_thresh);

    fprintf('  HSV decision:  %s\n', decision_str(flags_hsv(t)));
    fprintf('  Gray decision: %s\n', decision_str(flags_gray(t)));
end

%% ----------------------------------------------------------
%  SECTION 5: DISPLAY RESULTS
% -----------------------------------------------------------

cols = min(num_targets, 5);
rows = ceil(num_targets / cols);

% --- Figure: Method A — HSV anomaly maps per region ---
figure('Name', 'Figure 25 - HSV Anomaly Maps', ...
    'NumberTitle', 'off', 'Position', [0, 0, 1500, rows*300]);

for t = 1:num_targets
    if img_indices(t) == 0; continue; end

    h = img_sizes(t, 1);
    w = img_sizes(t, 2);

    overlay = zeros(h, w, 3);
    overlay(:,:,1) = double(anomaly_hsv{t, 1});  % left   — red
    overlay(:,:,2) = double(anomaly_hsv{t, 2});  % middle — green
    overlay(:,:,3) = double(anomaly_hsv{t, 3});  % right  — blue

    subplot(rows, cols, t);
    imshow(overlay);

    if flags_hsv(t)
        dec_col = [1 0.3 0.3];
    else
        dec_col = [0.3 1 0.3];
    end

    title(sprintf('[%d] %s\n%s', t, target_names{t}, ...
        decision_str(flags_hsv(t))), ...
        'FontSize', 7, 'Color', dec_col, 'Interpreter', 'none');
end
sgtitle('Figure 25 — Method A: HSV Anomaly Maps  (L=red  M=green  R=blue)', ...
    'FontSize', 12, 'FontWeight', 'bold');

% --- Figure: Method B — Grayscale anomaly maps per region ---
figure('Name', 'Figure 26 - Grayscale Anomaly Maps', ...
    'NumberTitle', 'off', 'Position', [0, 0, 1500, rows*300]);

for t = 1:num_targets
    if img_indices(t) == 0; continue; end

    h = img_sizes(t, 1);
    w = img_sizes(t, 2);

    overlay = zeros(h, w, 3);
    overlay(:,:,1) = double(anomaly_gray{t, 1});
    overlay(:,:,2) = double(anomaly_gray{t, 2});
    overlay(:,:,3) = double(anomaly_gray{t, 3});

    subplot(rows, cols, t);
    imshow(overlay);

    if flags_gray(t)
        dec_col = [1 0.3 0.3];
    else
        dec_col = [0.3 1 0.3];
    end

    title(sprintf('[%d] %s\n%s', t, target_names{t}, ...
        decision_str(flags_gray(t))), ...
        'FontSize', 7, 'Color', dec_col, 'Interpreter', 'none');
end
sgtitle('Figure 26 — Method B: Grayscale Anomaly Maps  (L=red  M=green  R=blue)', ...
    'FontSize', 12, 'FontWeight', 'bold');

% --- Figure: Side-by-side on original image ---
figure('Name', 'Figure 27 - Anomaly Detection on Original', ...
    'NumberTitle', 'off', 'Position', [0, 0, 1500, rows*350]);

for t = 1:num_targets
    if img_indices(t) == 0; continue; end

    h       = img_sizes(t, 1);
    y_range = (1:h)';
    p_left  = polyfit(pts_left_all{t}(:,2),  pts_left_all{t}(:,1),  poly_degree);
    p_right = polyfit(pts_right_all{t}(:,2), pts_right_all{t}(:,1), poly_degree);

    % Method A overlay on original
    subplot(rows, num_targets*2, (t-1)*2 + 1);
    imshow(imgs{t}); hold on;
    plot(polyval(p_left,  y_range), y_range, 'y-', 'LineWidth', 1.5);
    plot(polyval(p_right, y_range), y_range, 'y-', 'LineWidth', 1.5);

    hsv_overlay = cat(3, ...
        double(anomaly_hsv{t,1}) + double(anomaly_hsv{t,2})*0 + double(anomaly_hsv{t,3})*0, ...
        double(anomaly_hsv{t,2}), ...
        double(anomaly_hsv{t,3}));
    h_im = imshow(hsv_overlay); hold on;
    set(h_im, 'AlphaData', 0.5 * double(any(hsv_overlay > 0, 3)));

    title(sprintf('HSV | %s', decision_str(flags_hsv(t))), ...
        'FontSize', 7, 'Color', [1 0.8 0]);
    hold off;

    % Method B overlay on original
    subplot(rows, num_targets*2, (t-1)*2 + 2);
    imshow(imgs{t}); hold on;
    plot(polyval(p_left,  y_range), y_range, 'y-', 'LineWidth', 1.5);
    plot(polyval(p_right, y_range), y_range, 'y-', 'LineWidth', 1.5);

    gray_overlay = cat(3, ...
        double(anomaly_gray{t,1}), ...
        double(anomaly_gray{t,2}), ...
        double(anomaly_gray{t,3}));
    h_im2 = imshow(gray_overlay); hold on;
    set(h_im2, 'AlphaData', 0.5 * double(any(gray_overlay > 0, 3)));

    title(sprintf('Gray | %s', decision_str(flags_gray(t))), ...
        'FontSize', 7, 'Color', [1 0.8 0]);
    hold off;
end
sgtitle('Figure 27 — HSV (odd cols) vs Gray (even cols) Anomaly Overlay', ...
    'FontSize', 12, 'FontWeight', 'bold');

%% ----------------------------------------------------------
%  SECTION 6: SUMMARY TABLE
% -----------------------------------------------------------

fprintf('\n%-25s | HSV Decision          | Gray Decision\n', 'Image');
fprintf('%s\n', repmat('-', 1, 75));
for t = 1:num_targets
    if img_indices(t) == 0; continue; end
    fprintf('%-25s | %-22s| %s\n', ...
        target_names{t}, ...
        decision_str(flags_hsv(t)), ...
        decision_str(flags_gray(t)));
end

%% ----------------------------------------------------------
%  HELPER FUNCTION
% -----------------------------------------------------------
function s = decision_str(flag)
    if flag
        s = 'INDIRECT OBSTACLE DETECTED';
    else
        s = 'CLEAR';
    end
end