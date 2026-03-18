function [left_pts, right_pts, left_segments, right_segments, x_left_fit, x_right_fit, y_fit, p_left, p_right] = ...
    step1_rail_regression(bw_clean, roi_mask, n_strips, theta_min, theta_max, x_thresh)
% STEP1_RAIL_REGRESSION  Fit degree-2 polynomials to Hough-detected rail lines.
%
% Inputs:
%   bw_clean   - Binary image (Otsu DoG + ROI + bwareaopen)
%   roi_mask   - Trapezoidal ROI mask
%   n_strips   - Number of horizontal strips (e.g. 3)
%   theta_min, theta_max - Hough angle filter (e.g. -50 to 50 deg)
%   x_thresh   - Min horizontal separation between left/right lines (px)
%
% Outputs:
%   left_pts, right_pts - Nx2 [x,y] points from line endpoints
%   left_segments, right_segments - Cell arrays of line segments per strip
%   x_left_fit, x_right_fit, y_fit - Polynomial evaluated for plotting
%   p_left, p_right - polyfit coefficients: x = p(1)*y^2 + p(2)*y + p(3)

    [h, w] = size(bw_clean);
    bw_roi = bw_clean & roi_mask;
    ys = find(any(roi_mask, 2));

    if isempty(ys)
        left_pts = []; right_pts = []; left_segments = {}; right_segments = {};
        x_left_fit = []; x_right_fit = []; y_fit = []; p_left = []; p_right = [];
        return;
    end

    y_top = min(ys);
    y_bottom = max(ys);
    strip_height = (y_bottom - y_top) / n_strips;

    left_segments = {};
    right_segments = {};
    left_pts = zeros(0, 2);
    right_pts = zeros(0, 2);

    for s = 1:n_strips
        y_start = max(1, round(y_top + (s-1) * strip_height));
        y_end = min(h, round(y_top + s * strip_height));
        if y_end < y_start, continue; end

        strip_mask = false(h, w);
        strip_mask(y_start:y_end, :) = true;
        bw_strip = bw_roi & strip_mask;

        [H, theta, rho] = hough(bw_strip);
        P = houghpeaks(H, 12, 'Threshold', ceil(0.3*max(H(:))));
        lines = houghlines(bw_strip, theta, rho, P, 'FillGap', 10, 'MinLength', 50);

        lines_theta = lines([lines.theta] >= theta_min & [lines.theta] <= theta_max);
        if isempty(lines_theta), continue; end

        line_lengths = arrayfun(@(l) norm(l.point1 - l.point2), lines_theta);
        [~, idx] = sort(line_lengths, 'descend');

        selected_lines = [];
        for k = 1:numel(idx)
            line_xy = lines_theta(idx(k));
            x_mean = mean([line_xy.point1(1), line_xy.point2(1)]);

            keep = true;
            for sl = selected_lines
                x_sel = mean([sl.point1(1), sl.point2(1)]);
                if abs(x_mean - x_sel) < x_thresh
                    keep = false;
                    break;
                end
            end

            if keep
                selected_lines = [selected_lines, line_xy];
            end

            if numel(selected_lines) >= 2
                break;
            end
        end

        if isempty(selected_lines), continue; end

        x_means = arrayfun(@(l) mean([l.point1(1), l.point2(1)]), selected_lines);
        [~, idx_left] = min(x_means);
        [~, idx_right] = max(x_means);

        l_left = selected_lines(idx_left);
        l_right = selected_lines(idx_right);

        seg_left = [l_left.point1; l_left.point2];
        seg_right = [l_right.point1; l_right.point2];

        left_segments{end+1} = seg_left;
        right_segments{end+1} = seg_right;

        left_pts = [left_pts; seg_left];
        right_pts = [right_pts; seg_right];
    end

    % Polynomial fitting
    x_left_fit = [];
    x_right_fit = [];
    y_fit = [];
    p_left = [];
    p_right = [];

    if size(left_pts, 1) >= 2 && size(right_pts, 1) >= 2
        deg = 2;
        deg_left = min(deg, size(left_pts, 1) - 1);
        deg_right = min(deg, size(right_pts, 1) - 1);

        p_left = polyfit(left_pts(:,2), left_pts(:,1), deg_left);
        p_right = polyfit(right_pts(:,2), right_pts(:,1), deg_right);

        y_min = min(min(left_pts(:,2)), min(right_pts(:,2)));
        y_max = max(max(left_pts(:,2)), max(right_pts(:,2)));

        y_fit = linspace(y_min, y_max, 100)';
        x_left_fit = polyval(p_left, y_fit);
        x_right_fit = polyval(p_right, y_fit);
    end
end
