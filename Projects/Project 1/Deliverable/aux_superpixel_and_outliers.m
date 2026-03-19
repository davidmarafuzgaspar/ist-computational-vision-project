function [anom_left, anom_mid, anom_right, sp_labels, r_sides, r_mid] = ...
    aux_superpixel_and_outliers(img, left_region, mid_region, right_region, ...
    num_superpixels, sp_compactness, iqr_multiplier)
% SLIC segmentation + Tukey IQR outlier detection.
%
% Inputs:
%   img - RGB image
%   left_region, mid_region, right_region - Masks from step 2
%   num_superpixels - Target number (e.g. 2500)
%   sp_compactness - SLIC compactness (e.g. 10)
%   iqr_multiplier - Tukey fence multiplier (e.g. 1.5)
%
% Outputs:
%   anom_left, anom_mid, anom_right - Logical masks of anomalous pixels
%   sp_labels - Cell {1:3} of superpixel label maps
%   r_sides, r_mid - Anomaly ratios (anomalous_pixels / total_pixels)

    N_FEAT = 6;
    [h, w, ~] = size(img);
    img_lab = rgb2lab(img);
    n_sp = max(50, round(num_superpixels));
    [sp_lab_full, num_sp_total] = superpixels(img_lab, n_sp, ...
        'Compactness', sp_compactness, 'IsInputLab', true);

    reg_masks = {left_region, mid_region, right_region};
    sp_feats = cell(1, 3);
    valid_sp = cell(1, 3);
    sp_count = zeros(1, 3);

    for r = 1:3
        reg_mask = reg_masks{r};
        if sum(reg_mask(:)) == 0
            sp_feats{r} = zeros(0, N_FEAT);
            valid_sp{r} = false(0, 1);
            sp_count(r) = 0;
            continue;
        end
        sp_ids = unique(sp_lab_full(reg_mask));
        sp_ids = sp_ids(sp_ids > 0);
        sp_count(r) = num_sp_total;
        feats = zeros(num_sp_total, N_FEAT);
        valid = false(num_sp_total, 1);
        for c = 1:3
            ch = img_lab(:, :, c);
            for s = sp_ids'
                px = ch(sp_lab_full == s & reg_mask);
                if ~isempty(px)
                    feats(s, c) = median(px);
                    feats(s, c+3) = std(px);
                    valid(s) = true;
                end
            end
        end
        sp_feats{r} = feats;
        valid_sp{r} = valid;
    end

    region_imgs = cell(1, 3);
    for r = 1:3
        region_imgs{r} = img;
        region_imgs{r}(repmat(~reg_masks{r}, [1 1 3])) = 0;
    end

    % Sides: pool left + right, Tukey IQR
    sides_pool = [sp_feats{1}(valid_sp{1}, :); sp_feats{3}(valid_sp{3}, :)];
    if size(sides_pool, 1) >= 4
        sides_median = median(sides_pool, 1);
        sides_iqr = iqr(sides_pool, 1);
        sides_iqr(sides_iqr < 1e-6) = 1;
        sides_norm = (sides_pool - sides_median) ./ sides_iqr;
        sides_dist = sqrt(sum(sides_norm.^2, 2));
        Q3_s = prctile(sides_dist, 75);
        IQR_s = Q3_s - prctile(sides_dist, 25);
        sides_fence = Q3_s + iqr_multiplier * IQR_s;
    else
        sides_median = zeros(1, N_FEAT);
        sides_iqr = ones(1, N_FEAT);
        sides_fence = Inf;
    end

    sides_total = 0;
    sides_anomaly = 0;
    anom_left = false(h, w);
    anom_right = false(h, w);
    for r = [1, 3]
        reg_mask = any(region_imgs{r} > 0, 3);
        anomaly_sp = false(sp_count(r), 1);
        for s = 1:sp_count(r)
            if ~valid_sp{r}(s); continue; end
            norm_f = (sp_feats{r}(s,:) - sides_median) ./ sides_iqr;
            if sqrt(sum(norm_f.^2)) > sides_fence
                anomaly_sp(s) = true;
            end
        end
        anom_r = false(h, w);
        for s = 1:sp_count(r)
            if anomaly_sp(s)
                anom_r((sp_lab_full == s) & reg_mask) = true;
            end
        end
        if r == 1
            anom_left = anom_r;
        else
            anom_right = anom_r;
        end
        sides_total = sides_total + sum(reg_mask(:));
        sides_anomaly = sides_anomaly + sum(anom_r(:));
    end
    r_sides = sides_anomaly / max(1, sides_total);

    % Middle: Tukey IQR
    mid_pool = sp_feats{2}(valid_sp{2}, :);
    if size(mid_pool, 1) >= 4
        mid_median = median(mid_pool, 1);
        mid_iqr = iqr(mid_pool, 1);
        mid_iqr(mid_iqr < 1e-6) = 1;
        mid_norm = (mid_pool - mid_median) ./ mid_iqr;
        mid_dist = sqrt(sum(mid_norm.^2, 2));
        Q3_m = prctile(mid_dist, 75);
        IQR_m = Q3_m - prctile(mid_dist, 25);
        mid_fence = Q3_m + iqr_multiplier * IQR_m;
    else
        mid_median = zeros(1, N_FEAT);
        mid_iqr = ones(1, N_FEAT);
        mid_fence = Inf;
    end

    anom_mid = false(h, w);
    reg_mask = any(region_imgs{2} > 0, 3);
    for s = 1:sp_count(2)
        if ~valid_sp{2}(s); continue; end
        norm_f = (sp_feats{2}(s,:) - mid_median) ./ mid_iqr;
        if sqrt(sum(norm_f.^2)) > mid_fence
            m = (sp_lab_full == s) & reg_mask;
            anom_mid(m) = true;
        end
    end
    r_mid = sum(anom_mid(:)) / max(1, sum(reg_mask(:)));

    sp_labels = {sp_lab_full, sp_lab_full, sp_lab_full};
end
