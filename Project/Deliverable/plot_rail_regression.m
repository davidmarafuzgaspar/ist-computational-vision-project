function plot_rail_regression(results, images, viz_indices)
% PLOT_RAIL_REGRESSION  Plot Hough segments and polynomial fit for rail regression step.
%
% Inputs:
%   results - Struct with clear_idx, rail_fits, filenames
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

    figure('Name', 'Rail Regression', 'NumberTitle', 'off', 'Position', [100, 100, 1200, 800]);
    for k = 1:n
        i = idx_list(k);
        img = images{i};
        if size(img, 3) == 1
            img = repmat(img, [1 1 3]);
        end
        rf = results.rail_fits{i};
        roi_x = rf.roi_x;
        roi_y = rf.roi_y;

        subplot(rows, cols, k);
        imshow(img); hold on;
        plot([roi_x roi_x(1)], [roi_y roi_y(1)], 'r-', 'LineWidth', 1.5);
        for j = 1:length(rf.left_segments)
            xy = rf.left_segments{j};
            plot(xy(:,1), xy(:,2), 'y-', 'LineWidth', 2.5);
        end
        for j = 1:length(rf.right_segments)
            xy = rf.right_segments{j};
            plot(xy(:,1), xy(:,2), 'c-', 'LineWidth', 2.5);
        end
        if ~isempty(rf.x_left_fit)
            plot(rf.x_left_fit, rf.y_fit, 'y-', 'LineWidth', 2.5);
        end
        if ~isempty(rf.x_right_fit)
            plot(rf.x_right_fit, rf.y_fit, 'c-', 'LineWidth', 2.5);
        end
        [~, fname, ext] = fileparts(results.filenames{i});
        title(sprintf('%s%s', fname, ext), 'FontSize', 10, 'Interpreter', 'none');
        hold off;
    end
    sgtitle('Figure X: Rail Polynomial Fit (degree 2)', 'FontSize', 14, 'FontWeight', 'bold');
end
