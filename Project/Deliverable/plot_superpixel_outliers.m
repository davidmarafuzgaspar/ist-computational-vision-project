function plot_superpixel_outliers(results, images, viz_indices)
% PLOT_SUPERPIXEL_OUTLIERS  Plot anomalous superpixels overlay.
%
% Inputs:
%   results - Struct with clear_idx, anomaly_maps, region_left, region_middle, region_right,
%             sp_labels_all, anomaly_ratios, filenames, sp_params
%   images  - Cell array of images
%   viz_indices - Indices into clear_idx to plot (empty = all)

    if isempty(results.clear_idx), return; end
    if nargin < 3 || isempty(viz_indices)
        viz_indices = 1:numel(results.clear_idx);
    end
    idx_list = results.clear_idx(viz_indices);
    n = numel(idx_list);
    if n == 0, return; end
    cols = min(n, 4);
    rows = ceil(n / cols);

    figure('Name', 'Superpixel Outliers', 'NumberTitle', 'off', 'Position', [0, 0, 1600, rows*350]);
    for k = 1:n
        i = idx_list(k);
        img = images{i};
        if size(img, 3) == 1
            img = repmat(img, [1 1 3]);
        end
        [h, w, ~] = size(img);
        sides_mask = results.anomaly_maps{i, 1} | results.anomaly_maps{i, 3};
        middle_mask = results.anomaly_maps{i, 2};

        overlay = zeros(h, w, 3);
        overlay(:,:,1) = double(sides_mask);
        overlay(:,:,2) = double(middle_mask);

        reg_combined = results.region_left{i} | results.region_middle{i} | results.region_right{i};
        sp_boundary = false(h, w);
        if ~isempty(results.sp_labels_all{i, 1}) && max(results.sp_labels_all{i, 1}(:)) > 0
            sp_boundary = boundarymask(results.sp_labels_all{i, 1}) & reg_combined;
        end

        subplot(rows, cols, k);
        imshow(img); hold on;
        h_ov = imshow(overlay);
        set(h_ov, 'AlphaData', 0.5 * double(sides_mask | middle_mask));
        boundary_overlay = zeros(h, w, 3);
        boundary_overlay(:,:,2) = double(sp_boundary);
        boundary_overlay(:,:,3) = double(sp_boundary);
        h_bnd = imshow(boundary_overlay);
        set(h_bnd, 'AlphaData', 0.3 * double(sp_boundary));

        [~, fname, ext] = fileparts(results.filenames{i});
        r_s = results.anomaly_ratios(i, 1);
        r_m = results.anomaly_ratios(i, 2);
        title(sprintf('[%d] %s%s\nSides=%.3f Mid=%.3f', i, fname, ext, r_s, r_m), 'FontSize', 8, 'Interpreter', 'none');
        hold off;
    end
    sp = results.sp_params;
    sgtitle(sprintf('Superpixel Outliers (red=sides, green=middle)\nSP=%d IQR_mul=%.1f', sp.num_superpixels, sp.iqr_multiplier), ...
        'FontSize', 12, 'FontWeight', 'bold');
end
