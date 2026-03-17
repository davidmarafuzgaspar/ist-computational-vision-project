%% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 5 - Hough Transform with Horizontal Strips
%
%% ============================================================
clear; clc; close all;
load('./Output/workspace_phase4.mat');
disp('Workspace from Phase 4 loaded');

%% ----------------------------------------------------------
%  SECTION 1: PARAMETERS
% -----------------------------------------------------------
num_strips  = 4;
num_peaks   = 2;
fill_gap    = 15;
min_length  = 20;
angle_range = [-35, 35];

%% ----------------------------------------------------------
%  SECTION 2: RUN HOUGH STRIPS ON ALL IMAGES
% -----------------------------------------------------------
hough_lines_gauss = cell(N, 1);
hough_lines_mean  = cell(N, 1);

for i = 1:N
    mask = roi_masks{i};

    hough_lines_gauss{i} = hough_strips(images_clean_gauss{i}, mask, ...
        num_strips, num_peaks, fill_gap, min_length, angle_range);

    hough_lines_mean{i}  = hough_strips(images_clean_mean{i},  mask, ...
        num_strips, num_peaks, fill_gap, min_length, angle_range);
end

%% ----------------------------------------------------------
%  SECTION 3: PER-IMAGE VISUALISATION
% -----------------------------------------------------------
for i = 1:N
    [~, name, ext] = fileparts(filenames{i});
    if labels(i) == 0
        col = [0 0.5 0]; status = 'CLEAR';
    else
        col = [0.8 0 0]; status = 'OBSTRUCTED';
    end

    figure('Name', sprintf('Image %d - Hough Strips', i), ...
        'NumberTitle', 'off', ...
        'Position', [0, 0, 1400, 420]);

    imgH    = size(images_final{i}, 1);
    strip_h = floor(imgH / num_strips);

    % Column 1 — binary gauss
    subplot(1, 4, 1);
    imshow(images_clean_gauss{i});
    title('Binary — gauss', 'FontSize', 9);

    % Column 2 — hough lines on enhanced (gauss)
    subplot(1, 4, 2);
    imshow(images_final{i}); hold on;
    for s = 1:num_strips-1
        yline(s * strip_h, 'y--', 'LineWidth', 0.8);
    end
    lines_g = hough_lines_gauss{i};
    for k = 1:length(lines_g)
        xy = [lines_g(k).point1; lines_g(k).point2];
        plot(xy(:,1), xy(:,2), 'r-', 'LineWidth', 2);
    end
    title(sprintf('Hough gauss  (%d lines)', length(lines_g)), 'FontSize', 9);
    hold off;

    % Column 3 — binary mean
    subplot(1, 4, 3);
    imshow(images_clean_mean{i});
    title('Binary — mean', 'FontSize', 9);

    % Column 4 — hough lines on enhanced (mean)
    subplot(1, 4, 4);
    imshow(images_final{i}); hold on;
    for s = 1:num_strips-1
        yline(s * strip_h, 'y--', 'LineWidth', 0.8);
    end
    lines_m = hough_lines_mean{i};
    for k = 1:length(lines_m)
        xy = [lines_m(k).point1; lines_m(k).point2];
        plot(xy(:,1), xy(:,2), 'b-', 'LineWidth', 2);
    end
    title(sprintf('Hough mean   (%d lines)', length(lines_m)), 'FontSize', 9);
    hold off;

    sgtitle(sprintf('[%d] %s  —  %s', i, [name ext], status), ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'Color', col, 'Interpreter', 'none');
end

%% ----------------------------------------------------------
%  SECTION 4: FULL DATASET OVERVIEW
% -----------------------------------------------------------
for method = 1:2
    if method == 1
        all_lines = hough_lines_gauss;
        line_col  = 'r';
        fig_title = 'Hough strip lines — unsharp gauss  (red)';
        fig_name  = 'Figure - Hough Overview gauss';
    else
        all_lines = hough_lines_mean;
        line_col  = 'b';
        fig_title = 'Hough strip lines — unsharp mean  (blue)';
        fig_name  = 'Figure - Hough Overview mean';
    end

    figure('Name', fig_name, ...
        'NumberTitle', 'off', ...
        'Position', [0, 0, 1500, 900]);

    for i = 1:N
        subplot(3, 5, i);
        imshow(images_final{i}); hold on;
        lines = all_lines{i};
        for k = 1:length(lines)
            xy = [lines(k).point1; lines(k).point2];
            plot(xy(:,1), xy(:,2), line_col, 'LineWidth', 1.5);
        end
        hold off;
        if labels(i) == 0, tcol = [0 0.5 0]; else, tcol = [0.8 0 0]; end
        [~, nm, ex] = fileparts(filenames{i});
        title(sprintf('[%d] %s  (%d)', i, [nm ex], length(lines)), ...
            'FontSize', 6, 'Color', tcol, 'Interpreter', 'none');
    end
    sgtitle(fig_title, 'FontSize', 12, 'FontWeight', 'bold');
end

%% ----------------------------------------------------------
%  SECTION 5: SAVE WORKSPACE
% -----------------------------------------------------------
save('./Output/workspace_phase5.mat', ...
    'images', 'images_gray', ...
    'images_roi', 'roi_masks', ...
    'images_final', ...
    'images_clean_gauss', 'images_clean_mean', ...
    'hough_lines_gauss',  'hough_lines_mean', ...
    'num_strips', 'num_peaks', 'fill_gap', ...
    'min_length', 'angle_range', ...
    'thresh_gauss', 'thresh_mean', ...
    'mean_size', 'sigma', ...
    'filenames', 'labels', 'descriptions', 'N');
fprintf('\nWorkspace saved to ./Output/workspace_phase5.mat\n');

%% ----------------------------------------------------------
%  LOCAL FUNCTION — must be at end of file
% -----------------------------------------------------------
function lines_all = hough_strips(bin_img, mask, num_strips, ...
        num_peaks, fill_gap, min_length, angle_range)

    imgH      = size(bin_img, 1);
    strip_h   = floor(imgH / num_strips);
    lines_all = [];

    for s = 1:num_strips
        y1 = (s-1) * strip_h + 1;
        y2 = min(s * strip_h, imgH);

        strip = bin_img(y1:y2, :);

        if sum(strip(:)) < 10
            continue;
        end

        [H, T, R] = hough(strip, ...
            'Theta', linspace(angle_range(1), angle_range(2), 180));
        P = houghpeaks(H, num_peaks, ...
            'Threshold', 0.2 * max(H(:)));

        if isempty(P)
            continue;
        end

        lines_strip = houghlines(strip, T, R, P, ...
            'FillGap',   fill_gap, ...
            'MinLength', min_length);

        for k = 1:length(lines_strip)
            lines_strip(k).point1(2) = lines_strip(k).point1(2) + y1 - 1;
            lines_strip(k).point2(2) = lines_strip(k).point2(2) + y1 - 1;
        end

        if ~isempty(lines_strip)
            if isempty(lines_all)
                lines_all = lines_strip;
            else
                lines_all = [lines_all, lines_strip];
            end
        end
    end
end