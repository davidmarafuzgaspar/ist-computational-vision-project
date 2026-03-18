function plot_three_way_regions(results, images, viz_indices)
% PLOT_THREE_WAY_REGIONS  Plot left/middle/right region overlay.
%
% Inputs:
%   results - Struct with clear_idx, region_left, region_middle, region_right, filenames, roi_params
%   images  - Cell array of images
%   viz_indices - Indices into clear_idx to plot (empty = all)

    if isempty(results.clear_idx), return; end
    if nargin < 3 || isempty(viz_indices)
        viz_indices = 1:numel(results.clear_idx);
    end
    idx_list = results.clear_idx(viz_indices);
    n = numel(idx_list);
    if n == 0, return; end
    cols = min(n, 3);
    rows = ceil(n / cols);

    figure('Name', '3-way Region Split', 'NumberTitle', 'off', 'Position', [100, 100, 1200, 800]);
    for k = 1:n
        i = idx_list(k);
        img = images{i};
        if size(img, 3) == 1
            img = repmat(img, [1 1 3]);
        end
        [h, w, ~] = size(img);
        left_r = results.region_left{i};
        mid_r = results.region_middle{i};
        right_r = results.region_right{i};

        overlay = zeros(h, w, 3);
        overlay(:,:,1) = double(left_r);
        overlay(:,:,2) = double(mid_r);
        overlay(:,:,3) = double(right_r);

        subplot(rows, cols, k);
        imshow(img); hold on;
        h_ov = imshow(overlay);
        set(h_ov, 'AlphaData', 0.5 * double(left_r | mid_r | right_r));
        [~, fname, ext] = fileparts(results.filenames{i});
        title(sprintf('%s%s', fname, ext), 'FontSize', 10, 'Interpreter', 'none');
        hold off;
    end
    rp = results.roi_params;
    sgtitle(sprintf('3-way Region Split (red=left, green=middle, blue=right; %.0f%% width)', rp.pct_side*100), ...
        'FontSize', 14, 'FontWeight', 'bold');
end
