function [left_region, mid_region, right_region] = aux_three_way_regions(h, w, p_left, p_right, ...
    ROI_TOP_Y, rail_padding, pct_side)
% Define left, middle, and right regions from rail fits.
%
% Inputs:
%   h, w - Image dimensions
%   p_left, p_right - polyfit coefficients from step 1
%   ROI_TOP_Y - Fraction of image height to exclude from top (e.g. 0.4)
%   rail_padding - Pixels to exclude from rail edges (e.g. 20)
%   pct_side - Side band width as fraction of image width (e.g. 0.10 = 10%)
%
% Outputs:
%   left_region, mid_region, right_region - Logical masks (h x w)

    left_region  = false(h, w);
    mid_region   = false(h, w);
    right_region = false(h, w);

    if isempty(p_left) || isempty(p_right)
        return;
    end

    [X, Y] = meshgrid(1:w, 1:h);
    y_rows = (1:h)';
    x_left_map  = polyval(p_left,  y_rows);
    x_right_map = polyval(p_right, y_rows);
    vertical_mask = (Y >= ROI_TOP_Y * h);
    side_width = pct_side * w;

    mid_region   = (X >= x_left_map + rail_padding) & (X <= x_right_map - rail_padding) & vertical_mask;
    left_region  = (X >= x_left_map - side_width) & (X < x_left_map - rail_padding) & vertical_mask;
    right_region = (X > x_right_map + rail_padding) & (X <= x_right_map + side_width) & vertical_mask;
end
