% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 7D - Obstacle Detection via Superpixel Colour Anomaly
%
%  Self-referencing approach:
%    - Left + Right regions are pooled (same ground material),
%      median L*a*b* is computed from their superpixels, and
%      outliers within that group are flagged.
%    - Middle region is treated independently.
%    - If the anomalous area fraction exceeds area_thresh
%      in either group → OBSTACLE DETECTED.
%
%  Authors:
%   - David Marafuz Gaspar - 106541
%   - Pedro Gaspar Mónico - 106626
%
% ============================================================
clear; clc; close all;
load('./Output/baseline_regions.mat');

%% ----------------------------------------------------------
%  PARAMETERS  <-- TUNE HERE
% -----------------------------------------------------------

num_superpixels = 500;

% Delta E threshold: superpixels whose MAD-normalised
% Euclidean distance in L*a*b* exceeds k_mad are flagged
k_mad = 5.0;

% Minimum fraction of group pixels that must be anomalous
% to trigger an obstacle flag
area_thresh = 0.10;

%% ----------------------------------------------------------
%  SECTION 1: PER-IMAGE ANOMALY DETECTION
% -----------------------------------------------------------

num_images = size(baseline_regions, 1);

anomaly_maps   = cell(num_images, 3);   % pixel-level anomaly mask per region
anomaly_ratios = zeros(num_images, 2);  % [sides, middle]
flags_sides    = false(num_images, 1);
flags_middle   = false(num_images, 1);
final_flags    = false(num_images, 1);

sp_labels_all   = cell(num_images, 3);
sp_anomaly_all  = cell(num_images, 3);
sp_means_store  = cell(num_images, 3);
valid_sp_store  = cell(num_images, 3);
sp_count_store  = zeros(num_images, 3);

for b = 1:num_images
    fprintf('\nProcessing: %s\n', baseline_names{b});

    [h, w, ~] = size(baseline_regions{b, 1});

    % === Step 1: Compute superpixels per region ===
    for r = 1:3
        reg_img  = baseline_regions{b, r};
        reg_mask = any(reg_img > 0, 3);
        num_px   = sum(reg_mask(:));

        if num_px == 0
            sp_labels_all{b, r}  = zeros(h, w);
            sp_anomaly_all{b, r} = false(0, 1);
            sp_means_store{b, r} = zeros(0, 3);
            valid_sp_store{b, r} = false(0, 1);
            sp_count_store(b, r) = 0;
            anomaly_maps{b, r}   = false(h, w);
            continue;
        end

        img_lab = rgb2lab(reg_img);
        n_sp    = max(10, round(num_superpixels * num_px / (h * w)));

        [sp_labels, num_sp] = superpixels(img_lab, n_sp, ...
            'Compactness', 20, 'IsInputLab', true);

        sp_labels_all{b, r}  = sp_labels;
        sp_count_store(b, r)  = num_sp;

        sp_means = zeros(num_sp, 3);
        valid_sp = false(num_sp, 1);

        for c = 1:3
            channel = img_lab(:,:,c);
            for s = 1:num_sp
                px = channel(sp_labels == s & reg_mask);
                if ~isempty(px)
                    sp_means(s, c) = mean(px);
                    valid_sp(s)    = true;
                end
            end
        end

        sp_means_store{b, r} = sp_means;
        valid_sp_store{b, r} = valid_sp;
    end

    % === Step 2: SIDES group (left + right pooled) ===
    sides_pool = [sp_means_store{b,1}(valid_sp_store{b,1}, :);
                  sp_means_store{b,3}(valid_sp_store{b,3}, :)];

    if size(sides_pool, 1) >= 2
        sides_median = median(sides_pool, 1);
        sides_mad    = median(abs(sides_pool - sides_median), 1);
    else
        sides_median = [0 0 0];
        sides_mad    = [1 1 1];
    end

    fprintf('  Sides: median=[%.1f %.2f %.2f]  MAD=[%.1f %.2f %.2f]\n', ...
        sides_median(1), sides_median(2), sides_median(3), ...
        sides_mad(1),    sides_mad(2),    sides_mad(3));

    sides_total_px   = 0;
    sides_anomaly_px = 0;

    for r = [1, 3]
        reg_mask = any(baseline_regions{b, r} > 0, 3);
        num_sp   = sp_count_store(b, r);

        anomaly_sp = false(num_sp, 1);
        for s = 1:num_sp
            if ~valid_sp_store{b, r}(s); continue; end
            diff = sp_means_store{b,r}(s,:) - sides_median;
            norm_diff = diff ./ max(sides_mad, 1e-6);
            deltaE = sqrt(sum(norm_diff .^ 2));
            if deltaE > k_mad
                anomaly_sp(s) = true;
            end
        end

        sp_anomaly_all{b, r} = anomaly_sp;

        anomaly_raw = false(h, w);
        for s = 1:num_sp
            if anomaly_sp(s)
                anomaly_raw(sp_labels_all{b,r} == s & reg_mask) = true;
            end
        end

        anomaly_maps{b, r} = anomaly_raw;
        sides_total_px   = sides_total_px  + sum(reg_mask(:));
        sides_anomaly_px = sides_anomaly_px + sum(anomaly_raw(:));
    end

    if sides_total_px > 0
        anomaly_ratios(b, 1) = sides_anomaly_px / sides_total_px;
    end

    % === Step 3: MIDDLE group ===
    mid_pool = sp_means_store{b,2}(valid_sp_store{b,2}, :);

    if size(mid_pool, 1) >= 2
        mid_median = median(mid_pool, 1);
        mid_mad    = median(abs(mid_pool - mid_median), 1);
    else
        mid_median = [0 0 0];
        mid_mad    = [1 1 1];
    end

    fprintf('  Middle: median=[%.1f %.2f %.2f]  MAD=[%.1f %.2f %.2f]\n', ...
        mid_median(1), mid_median(2), mid_median(3), ...
        mid_mad(1),    mid_mad(2),    mid_mad(3));

    reg_mask = any(baseline_regions{b, 2} > 0, 3);
    num_sp   = sp_count_store(b, 2);

    anomaly_sp = false(num_sp, 1);
    for s = 1:num_sp
        if ~valid_sp_store{b, 2}(s); continue; end
        diff = sp_means_store{b,2}(s,:) - mid_median;
        norm_diff = diff ./ max(mid_mad, 1e-6);
        deltaE = sqrt(sum(norm_diff .^ 2));
        if deltaE > k_mad
            anomaly_sp(s) = true;
        end
    end

    sp_anomaly_all{b, 2} = anomaly_sp;

    anomaly_raw = false(h, w);
    for s = 1:num_sp
        if anomaly_sp(s)
            anomaly_raw(sp_labels_all{b,2} == s & reg_mask) = true;
        end
    end

    anomaly_maps{b, 2} = anomaly_raw;
    mid_total_px = sum(reg_mask(:));
    if mid_total_px > 0
        anomaly_ratios(b, 2) = sum(anomaly_raw(:)) / mid_total_px;
    end

    % === Step 4: Decision ===
    flags_sides(b)  = anomaly_ratios(b, 1) > area_thresh;
    flags_middle(b) = anomaly_ratios(b, 2) > area_thresh;
    final_flags(b)  = flags_sides(b) || flags_middle(b);

    fprintf('  Sides ratio=%.3f  Middle ratio=%.3f  →  %s\n', ...
        anomaly_ratios(b, 1), anomaly_ratios(b, 2), ...
        decision_str(final_flags(b)));
end

%% ----------------------------------------------------------
%  SECTION 2: OVERLAY ANOMALOUS SUPERPIXELS ON ORIGINAL
% -----------------------------------------------------------

cols = min(num_images, 4);
rows = ceil(num_images / cols);

figure('Name', 'Figure 24 - Anomalous Superpixels Overlay', ...
    'NumberTitle', 'off', 'Position', [0, 0, 1600, rows*350]);

for b = 1:num_images
    % Reconstruct full ROI image from the 3 disjoint regions
    full_img = max(max(baseline_regions{b,1}, baseline_regions{b,2}), ...
                   baseline_regions{b,3});
    [h, w, ~] = size(full_img);

    % Build colour-coded anomaly overlay:
    %   Sides anomalies (left+right) → red
    %   Middle anomalies             → green
    overlay = zeros(h, w, 3);
    sides_mask  = anomaly_maps{b,1} | anomaly_maps{b,3};
    middle_mask = anomaly_maps{b,2};

    overlay(:,:,1) = double(sides_mask);
    overlay(:,:,2) = double(middle_mask);

    % Draw superpixel boundaries across all regions
    sp_boundary = false(h, w);
    for r = 1:3
        if sp_count_store(b, r) > 0
            reg_mask = any(baseline_regions{b, r} > 0, 3);
            sp_boundary = sp_boundary | (boundarymask(sp_labels_all{b,r}) & reg_mask);
        end
    end

    subplot(rows, cols, b);
    imshow(full_img); hold on;

    h_ov = imshow(overlay);
    set(h_ov, 'AlphaData', 0.5 * double(sides_mask | middle_mask));

    % Superpixel boundaries in thin cyan
    boundary_overlay = zeros(h, w, 3);
    boundary_overlay(:,:,1) = 0;
    boundary_overlay(:,:,2) = double(sp_boundary);
    boundary_overlay(:,:,3) = double(sp_boundary);
    h_bnd = imshow(boundary_overlay);
    set(h_bnd, 'AlphaData', 0.3 * double(sp_boundary));

    if final_flags(b)
        dec_col = [1 0.3 0.3];
    else
        dec_col = [0.3 1 0.3];
    end

    title(sprintf('[%d] %s\nSides=%.2f  Mid=%.2f | %s', ...
        b, baseline_names{b}, ...
        anomaly_ratios(b,1), anomaly_ratios(b,2), ...
        decision_str(final_flags(b))), ...
        'FontSize', 7, 'Color', dec_col, 'Interpreter', 'none');
    hold off;
end

sgtitle(sprintf(['Figure 24 — Anomalous Superpixels  ' ...
    '(red=sides  green=middle  cyan=SP boundaries)\n' ...
    'k\\_mad=%.1f   area\\_thresh=%.2f'], k_mad, area_thresh), ...
    'FontSize', 11, 'FontWeight', 'bold');

%% ----------------------------------------------------------
%  SECTION 3: DETAILED VIEW OF FLAGGED IMAGES
% -----------------------------------------------------------

flagged = find(final_flags);

if isempty(flagged)
    fprintf('\nNo images flagged as obstructed.\n');
else
    fprintf('\n%d image(s) flagged. Showing detail views.\n', length(flagged));

    for b = flagged'
        full_img = max(max(baseline_regions{b,1}, baseline_regions{b,2}), ...
                       baseline_regions{b,3});
        [h, w, ~] = size(full_img);

        figure('Name', sprintf('Figure 25.%d - Detail: %s', b, baseline_names{b}), ...
            'NumberTitle', 'off', 'Position', [0, 0, 1400, 450]);

        group_names  = {'Sides (Left + Right)', 'Middle'};
        group_maps   = {anomaly_maps{b,1} | anomaly_maps{b,3}, anomaly_maps{b,2}};
        group_ratios = anomaly_ratios(b, :);
        group_flags  = [flags_sides(b), flags_middle(b)];
        group_colors = {[1 0.2 0.2], [0.2 0.8 0.2]};

        for g = 1:2
            subplot(1, 3, g);

            display_img = full_img;
            anom_mask   = group_maps{g};

            % Tint anomalous pixels with the group colour
            for c = 1:3
                ch = double(display_img(:,:,c));
                ch(anom_mask) = ch(anom_mask) * 0.4 + group_colors{g}(c) * 255 * 0.6;
                display_img(:,:,c) = uint8(ch);
            end

            imshow(display_img);

            if group_flags(g)
                t_col = [1 0.3 0.3]; flag_str = 'FLAGGED';
            else
                t_col = [0.3 1 0.3]; flag_str = 'clear';
            end

            title(sprintf('%s\nratio=%.3f  (thresh=%.2f)  %s', ...
                group_names{g}, group_ratios(g), area_thresh, flag_str), ...
                'FontSize', 8, 'Color', t_col);
        end

        % Third panel: combined with SP boundaries
        subplot(1, 3, 3);

        combined_mask = group_maps{1} | group_maps{2};
        display_img   = full_img;

        for c_ch = 1:3
            ch = double(display_img(:,:,c_ch));
            ch(group_maps{1}) = ch(group_maps{1}) * 0.4 + group_colors{1}(c_ch) * 255 * 0.6;
            ch(group_maps{2}) = ch(group_maps{2}) * 0.4 + group_colors{2}(c_ch) * 255 * 0.6;
            display_img(:,:,c_ch) = uint8(ch);
        end

        sp_boundary = false(h, w);
        for r = 1:3
            if sp_count_store(b, r) > 0
                reg_mask = any(baseline_regions{b,r} > 0, 3);
                sp_boundary = sp_boundary | (boundarymask(sp_labels_all{b,r}) & reg_mask);
            end
        end
        display_img = imoverlay(display_img, sp_boundary, [0 0.8 0.8]);

        imshow(display_img);
        title(sprintf('Combined + SP boundaries\n%s', ...
            decision_str(final_flags(b))), ...
            'FontSize', 8, 'Color', [1 0.9 0.3]);

        sgtitle(sprintf('Figure 25.%d — Detail: %s  (red=sides  green=middle  cyan=boundaries)', ...
            b, baseline_names{b}), ...
            'FontSize', 11, 'FontWeight', 'bold', 'Interpreter', 'none');
    end
end

%% ----------------------------------------------------------
%  SECTION 4: ANOMALY RATIO BAR CHART
% -----------------------------------------------------------

figure('Name', 'Figure 26 - Anomaly Ratios', ...
    'NumberTitle', 'off', 'Position', [0, 0, 1400, 450]);

b_chart = bar(anomaly_ratios, 'grouped');
b_chart(1).FaceColor = [0.8 0.2 0.2];
b_chart(2).FaceColor = [0.2 0.7 0.2];
yline(area_thresh, 'k--', 'LineWidth', 2);
xticks(1:num_images);
xticklabels(baseline_names);
xtickangle(30);
ylabel('Anomaly Ratio');
legend({'Sides (L+R)', 'Middle', 'Threshold'}, 'Location', 'northeast');
title(sprintf('Figure 26 — Anomaly Ratio  (k\\_mad=%.1f  area\\_thresh=%.2f)', ...
    k_mad, area_thresh), 'FontSize', 11);
grid on;

%% ----------------------------------------------------------
%  SECTION 5: SUMMARY TABLE
% -----------------------------------------------------------

fprintf('\n%-25s | Sides  | Middle | Decision\n', 'Image');
fprintf('%s\n', repmat('-', 1, 65));
for b = 1:num_images
    fprintf('%-25s | %.3f  | %.3f  | %s\n', ...
        baseline_names{b}, ...
        anomaly_ratios(b, 1), anomaly_ratios(b, 2), ...
        decision_str(final_flags(b)));
end

%% ----------------------------------------------------------
%  HELPER FUNCTION
% -----------------------------------------------------------
function s = decision_str(flag)
    if flag
        s = 'OBSTACLE DETECTED';
    else
        s = 'CLEAR';
    end
end
