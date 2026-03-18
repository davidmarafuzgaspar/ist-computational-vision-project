% AUX_CHECKPOINT  Load and preprocess data for rail regression pipeline.
% No plots or tables. Produces variables needed for aux_rail_regression.
%
clear; clc; close all;

% Usage: run this script, then call aux_rail_regression for each image in clear_idx.
%
% Output variables:
%   images, images_otsu_dog_roi_clean, filenames, labels, predicted_status,
%   clear_idx, ROI_BL_X, ROI_BR_X, ROI_TL_X, ROI_TR_X, ROI_TOP_Y,
%   n_strips, theta_min, theta_max, x_thresh, strel_radius, se

% =========================
% LOAD DATA
% =========================

filenames = {
    './Data/cortada11.png'
    './Data/Frame1253.jpg'
    './Data/Frame1291.jpg'
    './Data/Frame1532.jpg'
    './Data/Frame1603.jpg'
    './Data/Frame1616.jpg'
    './Data/image00756.jpg'
    './Data/image02293.jpg'
    './Data/image04054.jpg'
    './Data/image04925.jpg'
    './Data/image06026.jpg'
    './Data/j30.jpg'
    './Data/l20.jpg'
    './Data/l23.jpg'
    './Data/p8.jpg'
};

labels = [1 0 0 0 0 1 0 0 1 0 0 1 1 1 1];

N = length(filenames);

images = cell(N, 1);
for i = 1:N
    images{i} = imread(filenames{i});
end

% =========================
% GRAYSCALE
% =========================

images_gray = cell(N, 1);
for i = 1:N
    images_gray{i} = rgb2gray(images{i});
end

% =========================
% PARAMETERS
% =========================

CLAHE_TILES = [8 8];
CLAHE_CLIPLIMIT = 0.02;
SIGMA = 1.5;
SIGMA1 = 1;
SIGMA2 = 2;

% =========================
% PROCESSING (CLAHE, DoG)
% =========================

images_eq = cell(N, 1);
images_clahe = cell(N, 1);
images_eq_gauss = cell(N, 1);
images_clahe_gauss = cell(N, 1);
images_dog = cell(N, 1);

for i = 1:N
    img = images_gray{i};
    images_eq{i} = histeq(img);
    images_clahe{i} = adapthisteq(img, 'NumTiles', CLAHE_TILES, 'ClipLimit', CLAHE_CLIPLIMIT);
    images_eq_gauss{i} = imgaussfilt(images_eq{i}, SIGMA);
    images_clahe_gauss{i} = imgaussfilt(images_clahe{i}, SIGMA);
    g1 = imgaussfilt(img, SIGMA1);
    g2 = imgaussfilt(img, SIGMA2);
    images_dog{i} = imsubtract(g1, g2);
end

% =========================
% OTSU
% =========================

images_otsu_eq = cell(N, 1);
images_otsu_clahe = cell(N, 1);
images_otsu_dog = cell(N, 1);

for i = 1:N
    level_eq = graythresh(images_eq_gauss{i});
    images_otsu_eq{i} = imbinarize(images_eq_gauss{i}, level_eq);
    level_clahe = graythresh(images_clahe_gauss{i});
    images_otsu_clahe{i} = imbinarize(images_clahe_gauss{i}, level_clahe);
    level_dog = graythresh(images_dog{i});
    images_otsu_dog{i} = imbinarize(images_dog{i}, level_dog);
    images_otsu_eq{i} = bwareaopen(images_otsu_eq{i}, 50);
    images_otsu_clahe{i} = bwareaopen(images_otsu_clahe{i}, 50);
    images_otsu_dog{i} = bwareaopen(images_otsu_dog{i}, 50);
end

% =========================
% ROI PARAMETERS
% =========================

ROI_BL_X = 0.05;
ROI_BR_X = 0.95;
ROI_TL_X = 0.30;
ROI_TR_X = 0.70;
ROI_TOP_Y = 0.4;
min_pixels = 100;
strel_radius = 3;
se = strel('disk', strel_radius);

% =========================
% CLEANED Otsu(DoG) WITH ROI
% =========================

images_otsu_dog_roi_clean = cell(N, 1);

for i = 1:N
    bw = images_otsu_dog{i};
    [h, w] = size(bw);
    roi_x = [ROI_BL_X*w, ROI_BR_X*w, ROI_TR_X*w, ROI_TL_X*w];
    roi_y = [h, h, ROI_TOP_Y*h, ROI_TOP_Y*h];
    mask = poly2mask(roi_x, roi_y, h, w);
    images_otsu_dog_roi_clean{i} = bwareaopen(bw & mask, min_pixels);
end

% =========================
% HOUGH METRICS PER STRIP (for predicted_status)
% =========================

% ROI for Hough strips (matches aux_checkpoint_safe)
ROI_BL_X = 0.05;
ROI_BR_X = 0.95;
ROI_TL_X = 0.3;
ROI_TR_X = 0.7;
ROI_TOP_Y = 0.45;

theta_min = -50;
theta_max = 50;
x_thresh = 20;
n_strips = 3;

metric_data = zeros(N * n_strips, 6);  % Image, Strip, NumLines, MeanLength, MaxLength, CoverageFraction
row_idx = 1;

for i = 1:N
    bw = images_otsu_dog{i};
    [h, w] = size(bw);
    roi_x = [ROI_BL_X*w, ROI_BR_X*w, ROI_TR_X*w, ROI_TL_X*w];
    roi_y = [h, h, ROI_TOP_Y*h, ROI_TOP_Y*h];
    mask = poly2mask(roi_x, roi_y, h, w);
    bw_roi = bw & mask;
    bw_clean = bwareaopen(bw_roi, min_pixels);

    y_top = ROI_TOP_Y * h;
    y_bottom = h;
    strip_height = (y_bottom - y_top) / n_strips;

    for s = 1:n_strips
        y_start = round(y_top + (s-1) * strip_height);
        y_end = round(y_top + s * strip_height);
        strip_mask = false(h, w);
        strip_mask(y_start:y_end, :) = true;
        bw_strip = bw_clean & strip_mask;

        [H, theta, rho] = hough(bw_strip);
        P = houghpeaks(H, 12, 'Threshold', ceil(0.3*max(H(:))));
        lines = houghlines(bw_strip, theta, rho, P, 'FillGap', 10, 'MinLength', 50);
        lines_theta = lines([lines.theta] >= theta_min & [lines.theta] <= theta_max);

        if ~isempty(lines_theta)
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
            lengths_use = arrayfun(@(l) norm(l.point1 - l.point2), selected_lines);
            if isempty(lengths_use)
                mean_len = 0;
                max_len = 0;
                coverage = 0;
                num_lines_use = 0;
            else
                mean_len = mean(lengths_use);
                max_len = max(lengths_use);
                coverage = mean(arrayfun(@(l) abs(l.point1(2) - l.point2(2)) / (y_end - y_start), selected_lines));
                num_lines_use = numel(selected_lines);
            end
        else
            mean_len = 0;
            max_len = 0;
            coverage = 0;
            num_lines_use = 0;
        end

        metric_data(row_idx, :) = [i, s, num_lines_use, mean_len, max_len, coverage];
        row_idx = row_idx + 1;
    end
end

% =========================
% PREDICTED STATUS
% =========================

predicted_status = strings(N, 1);

for i = 1:N
    idx = metric_data(:, 1) == i;
    num_lines_all = metric_data(idx, 3);
    coverage_all = metric_data(idx, 6);

    status = "Clear";
    if any(num_lines_all < 2)
        status = "Obstructed";
    end
    if any(coverage_all < 0.5)
        status = "Obstructed";
    end
    if (max(coverage_all) - min(coverage_all)) > 0.25
        status = "Obstructed";
    end
    predicted_status(i) = status;
end

clear_idx = find(predicted_status == "Clear");
