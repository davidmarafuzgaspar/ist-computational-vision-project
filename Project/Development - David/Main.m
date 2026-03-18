clear; clc; close all;

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

images = cell(N,1);
for i = 1:N
    images{i} = imread(filenames{i});
end

% =========================
% GRAYSCALE
% =========================

images_gray = cell(N,1);
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

SELECTED = [2 10 1 13 4];

% =========================
% PROCESSING
% =========================

images_eq = cell(N,1);
images_clahe = cell(N,1);
images_eq_gauss = cell(N,1);
images_clahe_gauss = cell(N,1);
images_dog = cell(N,1);

for i = 1:N
    img = images_gray{i};

    images_eq{i} = histeq(img);

    images_clahe{i} = adapthisteq(img, ...
        'NumTiles', CLAHE_TILES, ...
        'ClipLimit', CLAHE_CLIPLIMIT);

    images_eq_gauss{i} = imgaussfilt(images_eq{i}, SIGMA);
    images_clahe_gauss{i} = imgaussfilt(images_clahe{i}, SIGMA);

    g1 = imgaussfilt(img, SIGMA1);
    g2 = imgaussfilt(img, SIGMA2);
    images_dog{i} = imsubtract(g1, g2);
end

% =========================
% EDGE DETECTION
% =========================

edges_eq.prewitt = cell(N,1);
edges_eq.sobel   = cell(N,1);
edges_eq.log     = cell(N,1);
edges_eq.canny   = cell(N,1);

edges_clahe.prewitt = cell(N,1);
edges_clahe.sobel   = cell(N,1);
edges_clahe.log     = cell(N,1);
edges_clahe.canny   = cell(N,1);

for i = 1:N
    img_eq = images_eq_gauss{i};
    img_clahe = images_clahe_gauss{i};

    edges_eq.prewitt{i} = edge(img_eq, 'prewitt');
    edges_eq.sobel{i}   = edge(img_eq, 'sobel');
    edges_eq.log{i}     = edge(img_eq, 'log');
    edges_eq.canny{i}   = edge(img_eq, 'canny', [0.15 0.4], 2);
    edges_eq.canny{i}   = bwareaopen(edges_eq.canny{i}, 50);

    edges_clahe.prewitt{i} = edge(img_clahe, 'prewitt');
    edges_clahe.sobel{i}   = edge(img_clahe, 'sobel');
    edges_clahe.log{i}     = edge(img_clahe, 'log');
    edges_clahe.canny{i}   = edge(img_clahe, 'canny', [0.15 0.4], 2);
    edges_clahe.canny{i}   = bwareaopen(edges_clahe.canny{i}, 50);
end

% =========================
% OTSU
% =========================

images_otsu_eq = cell(N,1);
images_otsu_clahe = cell(N,1);
images_otsu_dog = cell(N,1);

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
% VISUALIZATION - EDGES
% =========================

figure;

for row = 1:length(SELECTED)
    i = SELECTED(row);

    subplot(length(SELECTED),10,(row-1)*10 + 1);
    imshow(images_eq_gauss{i}); title('Eq+Gauss');

    subplot(length(SELECTED),10,(row-1)*10 + 2);
    imshow(edges_eq.prewitt{i}); title('Prewitt');

    subplot(length(SELECTED),10,(row-1)*10 + 3);
    imshow(edges_eq.sobel{i}); title('Sobel');

    subplot(length(SELECTED),10,(row-1)*10 + 4);
    imshow(edges_eq.log{i}); title('LoG');

    subplot(length(SELECTED),10,(row-1)*10 + 5);
    imshow(edges_eq.canny{i}); title('Canny');

    subplot(length(SELECTED),10,(row-1)*10 + 6);
    imshow(images_clahe_gauss{i}); title('CLAHE+Gauss');

    subplot(length(SELECTED),10,(row-1)*10 + 7);
    imshow(edges_clahe.prewitt{i}); title('Prewitt');

    subplot(length(SELECTED),10,(row-1)*10 + 8);
    imshow(edges_clahe.sobel{i}); title('Sobel');

    subplot(length(SELECTED),10,(row-1)*10 + 9);
    imshow(edges_clahe.log{i}); title('LoG');

    subplot(length(SELECTED),10,(row-1)*10 + 10);
    imshow(edges_clahe.canny{i}); title('Canny');
end

% =========================
% VISUALIZATION - OTSU + DoG
% =========================

figure;

for row = 1:length(SELECTED)
    i = SELECTED(row);

    subplot(length(SELECTED),6,(row-1)*6 + 1);
    imshow(images_gray{i}); title('Original');

    subplot(length(SELECTED),6,(row-1)*6 + 2);
    imshow(images_clahe_gauss{i}); title('CLAHE+Gauss');

    subplot(length(SELECTED),6,(row-1)*6 + 3);
    imshow(images_otsu_clahe{i}); title('Otsu CLAHE');

    subplot(length(SELECTED),6,(row-1)*6 + 4);
    imshow(images_eq_gauss{i}); title('Eq+Gauss');

    subplot(length(SELECTED),6,(row-1)*6 + 5);
    imshow(images_dog{i}, []); title('DoG');

    subplot(length(SELECTED),6,(row-1)*6 + 6);
    imshow(images_otsu_dog{i}); title('Otsu DoG');
end

% =========================
% GRID VISUALIZATION: Otsu(DoG) ONLY
% =========================

figure('Name','Otsu(DoG) Grid','NumberTitle','off','Position',[0 0 1800 1200]);

cols = 5; % número de colunas na grid
rows = ceil(N / cols);

for i = 1:N
    subplot(rows, cols, i);
    imshow(images_otsu_dog{i});
    title(sprintf('[%d]', i),'FontSize',8);
end

sgtitle('Otsu(DoG) - All Images','FontSize',12,'FontWeight','bold');

% =========================
% ROI PARAMETERS (fractions of image size)
% =========================

ROI_BL_X = 0.05;   % bottom-left
ROI_BR_X = 0.95;   % bottom-right
ROI_TL_X = 0.30;   % top-left
ROI_TR_X = 0.70;   % top-right
ROI_TOP_Y = 0.4;   % top y fraction

% =========================
% APPLY ROI TO Otsu(DoG) AND DISPLAY
% =========================

figure('Name','Otsu(DoG) with ROI','NumberTitle','off','Position',[0 0 1800 1200]);

cols = 5; % 5 imagens por linha
rows = ceil(N/cols);

for i = 1:N
    bw = images_otsu_dog{i};
    [h, w] = size(bw);

    % ROI vertices in pixels
    roi_x = [ROI_BL_X*w, ROI_BR_X*w, ROI_TR_X*w, ROI_TL_X*w];
    roi_y = [h, h, ROI_TOP_Y*h, ROI_TOP_Y*h];

    % Create binary mask
    mask = poly2mask(roi_x, roi_y, h, w);

    % Apply mask
    bw_roi = bw & mask;

    % Display
    subplot(rows, cols, i);
    imshow(bw_roi);
    hold on;
    % Display ROI polygon outline on top
    plot([roi_x roi_x(1)], [roi_y roi_y(1)], 'r-', 'LineWidth', 1.5);
    hold off;
    title(sprintf('[%d]', i),'FontSize',8);
end

sgtitle('Otsu(DoG) with Trapezoidal ROI','FontSize',12,'FontWeight','bold');

% =========================
% MORPHOLOGICAL OPERATIONS TEST
% =========================

SELECTED = [2 10 1 13 4];

% ROI trapezoid parameters
ROI_BL_X = 0.05; ROI_BR_X = 0.95;
ROI_TL_X = 0.30; ROI_TR_X = 0.70;
ROI_TOP_Y = 0.4;

% Parameters for morphology
min_pixels = 100;           % for bwareaopen
strel_radius = 3;          % for imopen and imclose
se = strel('disk', strel_radius);

figure('Name','Morphological Operations Comparison','NumberTitle','off','Position',[0 0 2000 1200]);

for row = 1:length(SELECTED)
    i = SELECTED(row);
    bw = images_otsu_dog{i};
    [h, w] = size(bw);

    % ROI mask
    roi_x = [ROI_BL_X*w, ROI_BR_X*w, ROI_TR_X*w, ROI_TL_X*w];
    roi_y = [h, h, ROI_TOP_Y*h, ROI_TOP_Y*h];
    mask = poly2mask(roi_x, roi_y, h, w);

    % Apply ROI
    bw_roi = bw & mask;

    % ---- 1. bwareaopen ----
    bw_bwarea = bwareaopen(bw_roi, min_pixels);

    % ---- 2. imopen ----
    bw_open = imopen(bw_roi, se);

    % ---- 3. imclose ----
    bw_close = imclose(bw_roi, se);

    % Display results in grid
    subplot(length(SELECTED), 4, (row-1)*4 + 1);
    imshow(bw_roi);
    hold on; plot([roi_x roi_x(1)], [roi_y roi_y(1)], 'r-', 'LineWidth', 1.5);
    title(sprintf('[%d] Original ROI', i),'FontSize',8);
    hold off;

    subplot(length(SELECTED), 4, (row-1)*4 + 2);
    imshow(bw_bwarea);
    title('bwareaopen','FontSize',8);

    subplot(length(SELECTED), 4, (row-1)*4 + 3);
    imshow(bw_open);
    title('imopen','FontSize',8);

    subplot(length(SELECTED), 4, (row-1)*4 + 4);
    imshow(bw_close);
    title('imclose','FontSize',8);
end

sgtitle('Morphological Operations on Otsu(DoG) with ROI','FontSize',12,'FontWeight','bold');


% =========================
% CREATE CLEANED Otsu(DoG) WITH ROI FOR ALL IMAGES
% =========================

ROI_BL_X = 0.05; ROI_BR_X = 0.95;
ROI_TL_X = 0.30; ROI_TR_X = 0.70;
ROI_TOP_Y = 0.4;
min_pixels = 100;

images_otsu_dog_roi_clean = cell(N,1);

for i = 1:N
    bw = images_otsu_dog{i};
    [h, w] = size(bw);

    % ROI mask
    roi_x = [ROI_BL_X*w, ROI_BR_X*w, ROI_TR_X*w, ROI_TL_X*w];
    roi_y = [h, h, ROI_TOP_Y*h, ROI_TOP_Y*h];
    mask = poly2mask(roi_x, roi_y, h, w);

    % Apply ROI and remove small objects
    images_otsu_dog_roi_clean{i} = bwareaopen(bw & mask, min_pixels);
end

% =========================
% DISPLAY GRID - ALL IMAGES
% =========================

cols = 5; % 5 imagens por linha
rows = ceil(N / cols);

figure('Name','Final Otsu(DoG) with ROI Cleaned','NumberTitle','off','Position',[0 0 1800 1200]);

for i = 1:N
    subplot(rows, cols, i);
    imshow(images_otsu_dog_roi_clean{i});
    title(sprintf('[%d]', i),'FontSize',8);
end

sgtitle('Otsu(DoG) + ROI + Morphological Cleaning (bwareaopen)','FontSize',12,'FontWeight','bold');

% =========================
% HOUGH TRANSFORM ON CLEANED Otsu(DoG)
% =========================

figure('Name','Hough Transform Lines','NumberTitle','off','Position',[0 0 2000 1200]);

cols = 5;
rows = ceil(N / cols);

for i = 1:N
    bw_clean = images_otsu_dog_roi_clean{i};

    % Compute Hough Transform
    [H,theta,rho] = hough(bw_clean);

    % Find peaks
    P = houghpeaks(H, 2, 'Threshold', ceil(0.3*max(H(:))));

    % Extract lines
    lines = houghlines(bw_clean, theta, rho, P, 'FillGap', 5, 'MinLength', 20);

    % Display
    subplot(rows, cols, i);
    imshow(bw_clean); hold on;

    for k = 1:length(lines)
        xy = [lines(k).point1; lines(k).point2];
        plot(xy(:,1), xy(:,2), 'LineWidth', 2, 'Color', 'green');
    end

    title(sprintf('[%d]', i),'FontSize',8);
    hold off;
end

sgtitle('Hough Transform Lines on Otsu(DoG) + ROI + bwareaopen','FontSize',12,'FontWeight','bold');

% =========================
% Hough + ROI + Strips + Top 2 Lines + Metrics + Ground Truth
% =========================

cols = 5;
rows = ceil(N/cols);

% ROI trapezoid parameters
ROI_BL_X = 0.05; ROI_BR_X = 0.95;
ROI_TL_X = 0.3;  ROI_TR_X = 0.7;
ROI_TOP_Y = 0.45;

min_pixels = 100;
theta_min = -50;
theta_max = 50;
x_thresh = 20;      % distância mínima entre linhas
n_strips = 3;       % número de strips

% Prepara tabela para métricas
metric_table = table('Size',[N*n_strips, 7], ...
    'VariableTypes',{'double','double','double','double','double','double','string'}, ...
    'VariableNames',{'Image','Strip','NumLines','MeanLength','MaxLength','CoverageFraction','GroundTruth'});

row_idx = 1;

% Prepara figura de display das linhas
figure('Name','Hough Lines per Strip','NumberTitle','off','Position',[0 0 2200 1200]);
colors = {'g','c','y'};  % cores por strip

for i = 1:N
    bw = images_otsu_dog{i};
    [h, w] = size(bw);

    % ROI trapezoidal
    roi_x = [ROI_BL_X*w, ROI_BR_X*w, ROI_TR_X*w, ROI_TL_X*w];
    roi_y = [h, h, ROI_TOP_Y*h, ROI_TOP_Y*h];
    mask = poly2mask(roi_x, roi_y, h, w);

    bw_roi = bw & mask;
    bw_clean = bwareaopen(bw_roi, min_pixels);

    % Divide ROI em strips
    y_top = ROI_TOP_Y*h;
    y_bottom = h;
    strip_height = (y_bottom - y_top)/n_strips;

    subplot(rows, cols, i); imshow(bw_clean); hold on;
    plot([roi_x roi_x(1)], [roi_y roi_y(1)], 'r-', 'LineWidth', 1.5);

    for s = 1:n_strips
        y_start = round(y_top + (s-1)*strip_height);
        y_end   = round(y_top + s*strip_height);

        strip_mask = false(h,w);
        strip_mask(y_start:y_end,:) = true;
        bw_strip = bw_clean & strip_mask;

        [H,theta,rho] = hough(bw_strip);
        P = houghpeaks(H,12,'Threshold',ceil(0.3*max(H(:))));
        lines = houghlines(bw_strip,theta,rho,P,'FillGap',10,'MinLength',50);

        % Filtrar linhas pelo theta
        lines_theta = lines([lines.theta] >= theta_min & [lines.theta] <= theta_max);

        if ~isempty(lines_theta)
            % Ordenar por comprimento
            line_lengths = arrayfun(@(l) norm(l.point1-l.point2), lines_theta);
            [~, idx] = sort(line_lengths,'descend');
            selected_lines = [];

            for k = 1:numel(idx)
                line_xy = lines_theta(idx(k));
                x_mean = mean([line_xy.point1(1), line_xy.point2(1)]);

                % Checa distância horizontal mínima
                keep = true;
                for sl = selected_lines
                    x_selected = mean([sl.point1(1), sl.point2(1)]);
                    if abs(x_mean - x_selected) < x_thresh
                        keep = false; break;
                    end
                end

                if keep
                    selected_lines = [selected_lines, line_xy];
                end

                if numel(selected_lines) >= 2
                    break;
                end
            end

            % Métricas com as 2 linhas mais longas
            lengths_use = arrayfun(@(l) norm(l.point1-l.point2), selected_lines);
            if isempty(lengths_use)
                mean_len = 0; max_len = 0; coverage = 0; num_lines_use = 0;
            else
                mean_len = mean(lengths_use);
                max_len  = max(lengths_use);
                coverage = mean(arrayfun(@(l) abs(l.point1(2)-l.point2(2))/(y_end-y_start), selected_lines));
                num_lines_use = numel(selected_lines);
            end
        else
            mean_len = 0; max_len = 0; coverage = 0; num_lines_use = 0;
        end

        % Preenche a tabela
        metric_table.Image(row_idx) = i;
        metric_table.Strip(row_idx) = s;
        metric_table.NumLines(row_idx) = num_lines_use;
        metric_table.MeanLength(row_idx) = mean_len;
        metric_table.MaxLength(row_idx) = max_len;
        metric_table.CoverageFraction(row_idx) = coverage;

        % Ground truth
        if labels(i) == 0
            metric_table.GroundTruth(row_idx) = "Clear";
        else
            metric_table.GroundTruth(row_idx) = "Obstructed";
        end

        row_idx = row_idx + 1;

        % Plotar linhas
        for l = selected_lines
            xy = [l.point1; l.point2];
            plot(xy(:,1), xy(:,2), 'LineWidth', 2, 'Color', colors{s});
        end
    end

    title(sprintf('Img %d', i),'FontSize',8);
    hold off;
end

sgtitle('Hough Top 2 Lines per Strip on Otsu(DoG) + ROI','FontSize',12,'FontWeight','bold');

% =========================
% Predição de obstrução baseada nas métricas
% =========================

predicted_status = strings(N,1);

for i = 1:N
    idx = metric_table.Image == i;
    strips = metric_table(idx,:);

    num_lines_all = strips.NumLines;
    coverage_all  = strips.CoverageFraction;

    status = "Clear";

    % Regra 1: menos de 2 linhas em algum strip
    if any(num_lines_all < 2)
        status = "Obstructed";
    end
    % Regra 2: cobertura baixa
    if any(coverage_all < 0.5)
        status = "Obstructed";
    end
    % Regra 3: diferença grande entre strips
    if (max(coverage_all) - min(coverage_all)) > 0.25
        status = "Obstructed";
    end

    predicted_status(i) = status;
end

% Resumo final por imagem
image_summary = table((1:N)', predicted_status, 'VariableNames', {'Image','PredictedStatus'});
image_summary.GroundTruth = string(labels');
image_summary.GroundTruth(image_summary.GroundTruth=="0") = "Clear";
image_summary.GroundTruth(image_summary.GroundTruth=="1") = "Obstructed";

% Mostra tabelas
disp(metric_table);
disp(image_summary);

%% SECTION 4: RAIL REGRESSION (Hough lines per strip + 2nd degree polynomial fit)
% =========================
% Uses Hough-detected line segments per strip, then fits degree-2 polynomial through points.
% =========================

clear_idx = find(predicted_status == "Clear");

if ~isempty(clear_idx)
    cols = min(numel(clear_idx), 4);
    rows = ceil(numel(clear_idx) / cols);

    % --- Figure 1: Hough line segments per strip (before polynomial fit) ---
    figure('Name', 'Strip Hough Lines (before polynomial fit)', ...
        'NumberTitle', 'off', 'Position', [0, 0, 1600, rows*350]);

    for k = 1:numel(clear_idx)
        i = clear_idx(k);
        img = images{i};
        if size(img, 3) == 1
            img = repmat(img, [1 1 3]);
        end

        bw_clean = images_otsu_dog_roi_clean{i};
        [h, w] = size(bw_clean);

        roi_x = [ROI_BL_X*w, ROI_BR_X*w, ROI_TR_X*w, ROI_TL_X*w];
        roi_y = [h, h, ROI_TOP_Y*h, ROI_TOP_Y*h];
        roi_mask = poly2mask(roi_x, roi_y, h, w);

        [left_pts, right_pts, left_segments, right_segments] = ...
            fit_rail_lines_from_hough(bw_clean, roi_mask, n_strips, ...
            theta_min, theta_max, x_thresh);

        subplot(rows, cols, k);
        imshow(img); hold on;
        plot([roi_x roi_x(1)], [roi_y roi_y(1)], 'r-', 'LineWidth', 1.5);

        % Draw strip boundaries
        ys = find(any(roi_mask, 2));
        if ~isempty(ys)
            y_top = min(ys);
            y_bottom = max(ys);
            strip_height = (y_bottom - y_top) / n_strips;
            for s = 1:n_strips-1
                y_bound = round(y_top + s * strip_height);
                plot([1 w], [y_bound y_bound], 'm--', 'LineWidth', 1);
            end
        end

        % Plot Hough line segments (yellow=left, cyan=right)
        for j = 1:length(left_segments)
            xy = left_segments{j};
            plot(xy(:,1), xy(:,2), 'y-', 'LineWidth', 2.5);
        end
        for j = 1:length(right_segments)
            xy = right_segments{j};
            plot(xy(:,1), xy(:,2), 'c-', 'LineWidth', 2.5);
        end
        % Plot points from lines
        if ~isempty(left_pts)
            plot(left_pts(:,1), left_pts(:,2), 'yo', 'MarkerSize', 6, 'LineWidth', 1);
        end
        if ~isempty(right_pts)
            plot(right_pts(:,1), right_pts(:,2), 'co', 'MarkerSize', 6, 'LineWidth', 1);
        end

        [~, fname, ext] = fileparts(filenames{i});
        title(sprintf('[%d] %s%s', i, fname, ext), 'FontSize', 8, 'Interpreter', 'none');
        hold off;
    end

    sgtitle('Strip Hough Lines (yellow=left, cyan=right; magenta=strip boundaries)', ...
        'FontSize', 12, 'FontWeight', 'bold');

    % --- Figure 2: Degree-2 polynomial fit through line points ---
    figure('Name', 'Rail Polynomial Fit (degree 2) from Hough Line Segments', ...
        'NumberTitle', 'off', 'Position', [0, 0, 1600, rows*350]);

    for k = 1:numel(clear_idx)
        i = clear_idx(k);
        img = images{i};
        if size(img, 3) == 1
            img = repmat(img, [1 1 3]);
        end

        bw_clean = images_otsu_dog_roi_clean{i};
        [h, w] = size(bw_clean);

        roi_x = [ROI_BL_X*w, ROI_BR_X*w, ROI_TR_X*w, ROI_TL_X*w];
        roi_y = [h, h, ROI_TOP_Y*h, ROI_TOP_Y*h];
        roi_mask = poly2mask(roi_x, roi_y, h, w);

        [left_pts, right_pts, left_segments, right_segments, ...
            x_left_fit, x_right_fit, y_fit] = ...
            fit_rail_lines_from_hough(bw_clean, roi_mask, n_strips, ...
            theta_min, theta_max, x_thresh);

        subplot(rows, cols, k);
        imshow(img); hold on;
        plot([roi_x roi_x(1)], [roi_y roi_y(1)], 'r-', 'LineWidth', 1.5);

        % Plot line segments
        for j = 1:length(left_segments)
            xy = left_segments{j};
            plot(xy(:,1), xy(:,2), 'y-', 'LineWidth', 1.5);
        end
        for j = 1:length(right_segments)
            xy = right_segments{j};
            plot(xy(:,1), xy(:,2), 'c-', 'LineWidth', 1.5);
        end
        % Plot points
        if ~isempty(left_pts)
            plot(left_pts(:,1), left_pts(:,2), 'yo', 'MarkerSize', 6, 'LineWidth', 1);
        end
        if ~isempty(right_pts)
            plot(right_pts(:,1), right_pts(:,2), 'co', 'MarkerSize', 6, 'LineWidth', 1);
        end
        % Plot spline fit
        if ~isempty(x_left_fit)
            plot(x_left_fit, y_fit, 'y-', 'LineWidth', 2.5);
        end
        if ~isempty(x_right_fit)
            plot(x_right_fit, y_fit, 'c-', 'LineWidth', 2.5);
        end

        [~, fname, ext] = fileparts(filenames{i});
        title(sprintf('[%d] %s%s', i, fname, ext), 'FontSize', 8, 'Interpreter', 'none');
        hold off;
    end

    sgtitle('Rail Polynomial Fit (degree 2) from Hough Line Segments — Clear images only', ...
        'FontSize', 12, 'FontWeight', 'bold');

    % --- Figure 3: 3-way segmentation (left, middle, right) ---
    % Left/right = band of width (pct * image_width) next to each rail, so side regions don't extend too far
    % Middle = between rail lines
    rail_padding = 20;
    pct_side = 0.10;   % side region width = 10% of image (wider to include boulders further from rail)

    region_left   = cell(N, 1);  % left/mid/right masks per image (clear images only filled)
    region_middle = cell(N, 1);
    region_right  = cell(N, 1);

    figure('Name', '3-way Region Split (Left / Middle / Right)', ...
        'NumberTitle', 'off', 'Position', [0, 0, 1600, rows*350]);

    for k = 1:numel(clear_idx)
        i = clear_idx(k);
        img = images{i};
        if size(img, 3) == 1
            img = repmat(img, [1 1 3]);
        end

        bw_clean = images_otsu_dog_roi_clean{i};
        [h, w] = size(bw_clean);

        roi_x = [ROI_BL_X*w, ROI_BR_X*w, ROI_TR_X*w, ROI_TL_X*w];
        roi_y = [h, h, ROI_TOP_Y*h, ROI_TOP_Y*h];
        roi_mask = poly2mask(roi_x, roi_y, h, w);

        [~, ~, ~, ~, x_left_fit, x_right_fit, y_fit, p_left, p_right] = ...
            fit_rail_lines_from_hough(bw_clean, roi_mask, n_strips, ...
            theta_min, theta_max, x_thresh);

        left_region  = false(h, w);
        mid_region   = false(h, w);
        right_region = false(h, w);

        [X, Y] = meshgrid(1:w, 1:h);

        if ~isempty(p_left) && ~isempty(p_right)
            y_rows = (1:h)';
            x_left_map  = polyval(p_left,  y_rows);
            x_right_map = polyval(p_right, y_rows);

            % Vertical mask: exclude top of image (ROI_TOP_Y = 0.4)
            vertical_mask = (Y >= ROI_TOP_Y * h);

            % Middle = between the rail lines (with vertical clip)
            mid_region = (X >= x_left_map + rail_padding) & ...
                         (X <= x_right_map - rail_padding) & vertical_mask;

            % Left = band of width (pct_side * w) to the left of the left rail
            side_width = pct_side * w;
            left_region  = (X >= x_left_map - side_width) & (X < x_left_map - rail_padding) & vertical_mask;

            % Right = band of width (pct_side * w) to the right of the right rail
            right_region = (X > x_right_map + rail_padding) & (X <= x_right_map + side_width) & vertical_mask;
        end

        region_left{i}   = left_region;
        region_middle{i} = mid_region;
        region_right{i}  = right_region;

        overlay = zeros(h, w, 3);
        overlay(:,:,1) = double(left_region);
        overlay(:,:,2) = double(mid_region);
        overlay(:,:,3) = double(right_region);

        subplot(rows, cols, k);
        imshow(img); hold on;
        h_ov = imshow(overlay);
        set(h_ov, 'AlphaData', 0.5 * double(left_region | mid_region | right_region));

        [~, fname, ext] = fileparts(filenames{i});
        title(sprintf('[%d] %s%s', i, fname, ext), 'FontSize', 8, 'Interpreter', 'none');
        hold off;
    end

    sgtitle(sprintf('3-way Region Split (red=left %.0f%% width band, green=middle, blue=right %.0f%% width band; padding=%d px)', ...
        pct_side*100, pct_side*100, rail_padding), ...
        'FontSize', 12, 'FontWeight', 'bold');

    % --- Figure 4: Superpixel outlier detection (Phase_Final logic) ---
    num_superpixels = 2500;   % finer segmentation so boulders are isolated (not merged with ground)
    iqr_multiplier  = 1.5;    % more sensitive (lower = flag more as outliers)
    sp_compactness  = 10;     % lower = more irregular boundaries, better at following object edges
    N_FEAT = 6;  % [median_L, median_a, median_b, std_L, std_a, std_b]

    anomaly_maps   = cell(N, 3);
    anomaly_ratios = nan(N, 2);  % [sides, middle]
    sp_labels_all  = cell(N, 3);

    for k = 1:numel(clear_idx)
        i = clear_idx(k);
        img = images{i};
        if size(img, 3) == 1
            img = repmat(img, [1 1 3]);
        end

        [h, w, ~] = size(img);
        left_mask  = region_left{i};
        mid_mask   = region_middle{i};
        right_mask = region_right{i};

        region_imgs = cell(1, 3);
        region_imgs{1} = img; region_imgs{1}(repmat(~left_mask,  [1 1 3])) = 0;
        region_imgs{2} = img; region_imgs{2}(repmat(~mid_mask,   [1 1 3])) = 0;
        region_imgs{3} = img; region_imgs{3}(repmat(~right_mask, [1 1 3])) = 0;

        % Compute superpixels on FULL image so boundaries follow natural edges (boulders, etc.)
        img_lab_full = rgb2lab(img);
        n_sp_total = max(50, round(num_superpixels));
        [sp_lab_full, num_sp_total] = superpixels(img_lab_full, n_sp_total, ...
            'Compactness', sp_compactness, 'IsInputLab', true);

        sp_feats = cell(1, 3);
        valid_sp = cell(1, 3);
        sp_labels = cell(1, 3);
        sp_count = zeros(1, 3);

        reg_masks = {left_mask, mid_mask, right_mask};
        for r = 1:3
            reg_mask = reg_masks{r};
            num_px = sum(reg_mask(:));

            if num_px == 0
                sp_labels{r} = zeros(h, w);
                sp_feats{r}  = zeros(0, N_FEAT);
                valid_sp{r}  = false(0, 1);
                sp_count(r)  = 0;
                anomaly_maps{i, r} = false(h, w);
                continue;
            end

            % Find superpixels that overlap this region
            sp_ids_in_region = unique(sp_lab_full(reg_mask));
            sp_ids_in_region = sp_ids_in_region(sp_ids_in_region > 0);
            num_sp = numel(sp_ids_in_region);

            sp_labels{r} = sp_lab_full;
            sp_count(r)  = num_sp_total;

            feats = zeros(num_sp_total, N_FEAT);
            valid = false(num_sp_total, 1);
            for c = 1:3
                ch = img_lab_full(:, :, c);
                for s = sp_ids_in_region'
                    px = ch(sp_lab_full == s & reg_mask);
                    if ~isempty(px)
                        feats(s, c)     = median(px);
                        feats(s, c + 3) = std(px);
                        valid(s)        = true;
                    end
                end
            end
            sp_feats{r} = feats;
            valid_sp{r} = valid;
        end

        % SIDES: pool left + right, median + IQR
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
        for r = [1, 3]
            reg_mask = any(region_imgs{r} > 0, 3);
            num_sp = sp_count(r);
            anomaly_sp = false(num_sp, 1);
            for s = 1:num_sp
                if ~valid_sp{r}(s); continue; end
                norm_f = (sp_feats{r}(s,:) - sides_median) ./ sides_iqr;
                if sqrt(sum(norm_f.^2)) > sides_fence
                    anomaly_sp(s) = true;
                end
            end
            anom_raw = false(h, w);
            for s = 1:num_sp
                if anomaly_sp(s)
                    anom_raw(sp_labels{r} == s & reg_mask) = true;
                end
            end
            anomaly_maps{i, r} = anom_raw;
            sides_total = sides_total + sum(reg_mask(:));
            sides_anomaly = sides_anomaly + sum(anom_raw(:));
        end
        anomaly_ratios(i, 1) = sides_anomaly / max(1, sides_total);

        % MIDDLE: median + IQR
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

        reg_mask = any(region_imgs{2} > 0, 3);
        num_sp = sp_count(2);
        anomaly_sp = false(num_sp, 1);
        for s = 1:num_sp
            if ~valid_sp{2}(s); continue; end
            norm_f = (sp_feats{2}(s,:) - mid_median) ./ mid_iqr;
            if sqrt(sum(norm_f.^2)) > mid_fence
                anomaly_sp(s) = true;
            end
        end
        anom_raw = false(h, w);
        for s = 1:num_sp
            if anomaly_sp(s)
                anom_raw(sp_labels{2} == s & reg_mask) = true;
            end
        end
        anomaly_maps{i, 2} = anom_raw;
        mid_total = sum(reg_mask(:));
        anomaly_ratios(i, 2) = sum(anom_raw(:)) / max(1, mid_total);

        sp_labels_all{i, 1} = sp_labels{1};
        sp_labels_all{i, 2} = sp_labels{2};
        sp_labels_all{i, 3} = sp_labels{3};
    end

    % Plot anomalous superpixels overlay
    figure('Name', 'Superpixel Outlier Detection (Anomalous)', ...
        'NumberTitle', 'off', 'Position', [0, 0, 1600, rows*350]);

    for k = 1:numel(clear_idx)
        i = clear_idx(k);
        img = images{i};
        if size(img, 3) == 1
            img = repmat(img, [1 1 3]);
        end

        [h, w, ~] = size(img);
        sides_mask = anomaly_maps{i, 1} | anomaly_maps{i, 3};
        middle_mask = anomaly_maps{i, 2};

        overlay = zeros(h, w, 3);
        overlay(:,:,1) = double(sides_mask);
        overlay(:,:,2) = double(middle_mask);

        sp_boundary = false(h, w);
        reg_masks = {region_left{i}, region_middle{i}, region_right{i}};
        for r = 1:3
            if ~isempty(sp_labels_all{i, r}) && max(sp_labels_all{i, r}(:)) > 0
                sp_boundary = sp_boundary | (boundarymask(sp_labels_all{i, r}) & reg_masks{r});
            end
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

        [~, fname, ext] = fileparts(filenames{i});
        r_sides = anomaly_ratios(i, 1); r_mid = anomaly_ratios(i, 2);
        title(sprintf('[%d] %s%s\nSides=%.3f Mid=%.3f', i, fname, ext, r_sides, r_mid), ...
            'FontSize', 8, 'Interpreter', 'none');
        hold off;
    end

    sgtitle(sprintf('Superpixel Outliers (red=sides, green=middle, cyan=SP boundaries)\nSP=%d compact=%.0f IQR_mul=%.1f sides=%.0f%%', ...
        num_superpixels, sp_compactness, iqr_multiplier, pct_side*100), ...
        'FontSize', 12, 'FontWeight', 'bold');

    % --- Final classification: sides or middle > 0.1 → Obstructed ---
    area_thresh_final = 0.1;
    final_status = strings(N, 1);

    for i = 1:N
        if predicted_status(i) == "Obstructed"
            final_status(i) = "Obstructed";
        else
            r_s = anomaly_ratios(i, 1);
            r_m = anomaly_ratios(i, 2);
            if isnan(r_s), r_s = 0; end
            if isnan(r_m), r_m = 0; end
            if r_s > area_thresh_final || r_m > area_thresh_final
                final_status(i) = "Obstructed";
            else
                final_status(i) = "Clear";
            end
        end
    end

    % Final summary table
    img_names = cell(N, 1);
    for i = 1:N
        [~, fname, ext] = fileparts(filenames{i});
        img_names{i} = [fname ext];
    end

    final_summary = table((1:N)', img_names, predicted_status, ...
        anomaly_ratios(:,1), anomaly_ratios(:,2), final_status, ...
        'VariableNames', {'Image', 'Filename', 'InitialClass', 'SidesRatio', 'MiddleRatio', 'FinalClass'});

    fprintf('\n========== FINAL CLASSIFICATION SUMMARY ==========\n');
    fprintf('Rule: Obstructed if Sides > %.2f OR Middle > %.2f\n', area_thresh_final, area_thresh_final);
    fprintf('---------------------------------------------------\n');
    disp(final_summary);

    % Precision (Obstructed = positive class)
    gt_obstructed = (labels(:) == 1);
    pred_obstructed = (final_status == "Obstructed");
    TP = sum(pred_obstructed & gt_obstructed);
    FP = sum(pred_obstructed & ~gt_obstructed);
    FN = sum(~pred_obstructed & gt_obstructed);
    precision = TP / max(1, TP + FP);
    recall = TP / max(1, TP + FN);
    accuracy = sum(pred_obstructed == gt_obstructed) / N;

    fprintf('---------------------------------------------------\n');
    fprintf('PRECISION (Obstructed): %.2f  (TP=%d, FP=%d)\n', precision, TP, FP);
    fprintf('Recall (Obstructed):    %.2f  (FN=%d)\n', recall, FN);
    fprintf('Accuracy:               %.2f\n', accuracy);
    fprintf('===================================================\n');
end

% =========================
% Local functions
% =========================

function [p_left, p_right, centroids_left, centroids_right] = fit_rail_lines_degree2(bw_roi, roi_mask, n_strips)
% Fit left/right rail lines as x = f(y) using degree-2 polynomial regression
% on strip-wise centroids of detected line pixels.
%
% Inputs:
%   bw_roi   - binary image (Otsu DoG + ROI) with rail pixels
%   roi_mask - trapezoidal ROI mask
%   n_strips - number of horizontal strips
%
% Outputs:
%   p_left, p_right - polyfit coefficients (degree 2): x = p(1)*y^2 + p(2)*y + p(3)
%   centroids_left, centroids_right - Nx2 [x,y] centroid per strip per side

    [h, w] = size(bw_roi);

    ys = find(any(roi_mask, 2));
    if isempty(ys)
        p_left = []; p_right = [];
        centroids_left = []; centroids_right = [];
        return;
    end

    y_top = min(ys);
    y_bottom = max(ys);
    strip_height = (y_bottom - y_top) / n_strips;

    centroids_left  = zeros(0, 2);
    centroids_right = zeros(0, 2);
    x_mid = w / 2;

    for s = 1:n_strips
        y_start = max(1, round(y_top + (s-1) * strip_height));
        y_end   = min(h, round(y_top + s * strip_height));
        if y_end < y_start
            continue;
        end

        strip_mask = false(h, w);
        strip_mask(y_start:y_end, :) = true;
        bw_strip = bw_roi & strip_mask;

        [yy, xx] = find(bw_strip);
        if isempty(xx)
            continue;
        end

        left_sel  = xx < x_mid;
        right_sel = ~left_sel;

        if any(left_sel)
            centroids_left(end+1, :) = [mean(xx(left_sel)), mean(yy(left_sel))]; %#ok<AGROW>
        end
        if any(right_sel)
            centroids_right(end+1, :) = [mean(xx(right_sel)), mean(yy(right_sel))]; %#ok<AGROW>
        end
    end

    if size(centroids_left, 1) < 2 || size(centroids_right, 1) < 2
        p_left = []; p_right = [];
        return;
    end

    deg = 2;
    deg_left  = min(deg, size(centroids_left, 1) - 1);
    deg_right = min(deg, size(centroids_right, 1) - 1);

    p_left  = polyfit(centroids_left(:,2),  centroids_left(:,1),  deg_left);
    p_right = polyfit(centroids_right(:,2), centroids_right(:,1), deg_right);
end

function [left_pts, right_pts, left_segments, right_segments, x_left_fit, x_right_fit, y_fit, p_left, p_right] = ...
    fit_rail_lines_from_hough(bw_clean, roi_mask, n_strips, theta_min, theta_max, x_thresh)
% FIT_RAIL_LINES_FROM_HOUGH  Fit left/right rails using Hough line segments per strip + degree-2 polynomial.
%
%   Runs Hough per strip, selects top 2 lines (left/right by x), collects points,
%   and fits a 2nd-degree polynomial x = f(y) through them. Returns segments for plotting and fitted curve.
%
%   Inputs:
%     bw_clean   - binary image (Otsu DoG + ROI + bwareaopen)
%     roi_mask   - trapezoidal ROI mask
%     n_strips   - number of horizontal strips
%     theta_min, theta_max, x_thresh - Hough filter params (same as main loop)
%
%   Outputs:
%     left_pts, right_pts - Nx2 [x,y] points from line endpoints
%     left_segments, right_segments - cell arrays of 2x2 [point1; point2] per strip
%     x_left_fit, x_right_fit, y_fit - polynomial evaluated at y_fit (for plotting)

    [h, w] = size(bw_clean);
    bw_roi = bw_clean & roi_mask;

    ys = find(any(roi_mask, 2));
    if isempty(ys)
        left_pts = []; right_pts = [];
        left_segments = {}; right_segments = {};
        x_left_fit = []; x_right_fit = []; y_fit = [];
        p_left = []; p_right = [];
        return;
    end

    y_top = min(ys);
    y_bottom = max(ys);
    strip_height = (y_bottom - y_top) / n_strips;

    left_segments  = {};
    right_segments = {};
    left_pts  = zeros(0, 2);
    right_pts = zeros(0, 2);

    for s = 1:n_strips
        y_start = max(1, round(y_top + (s-1) * strip_height));
        y_end   = min(h, round(y_top + s * strip_height));
        if y_end < y_start
            continue;
        end

        strip_mask = false(h, w);
        strip_mask(y_start:y_end, :) = true;
        bw_strip = bw_roi & strip_mask;

        [H, theta, rho] = hough(bw_strip);
        P = houghpeaks(H, 12, 'Threshold', ceil(0.3*max(H(:))));
        lines = houghlines(bw_strip, theta, rho, P, 'FillGap', 10, 'MinLength', 50);

        lines_theta = lines([lines.theta] >= theta_min & [lines.theta] <= theta_max);

        if isempty(lines_theta)
            continue;
        end

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
                    keep = false; break;
                end
            end
            if keep
                selected_lines = [selected_lines, line_xy]; %#ok<AGROW>
            end
            if numel(selected_lines) >= 2
                break;
            end
        end

        if isempty(selected_lines)
            continue;
        end

        x_means = arrayfun(@(l) mean([l.point1(1), l.point2(1)]), selected_lines);
        [~, idx_left] = min(x_means);
        [~, idx_right] = max(x_means);
        l_left  = selected_lines(idx_left);
        l_right = selected_lines(idx_right);

        seg_left  = [l_left.point1;  l_left.point2];
        seg_right = [l_right.point1; l_right.point2];

        left_segments{end+1}  = seg_left;  %#ok<AGROW>
        right_segments{end+1} = seg_right; %#ok<AGROW>

        left_pts  = [left_pts;  seg_left];  %#ok<AGROW>
        right_pts = [right_pts; seg_right]; %#ok<AGROW>
    end

    % Fit degree-2 polynomial through points (x = f(y))
    x_left_fit = []; x_right_fit = []; y_fit = [];
    p_left = []; p_right = [];

    if size(left_pts, 1) >= 2 && size(right_pts, 1) >= 2
        deg = 2;
        deg_left  = min(deg, size(left_pts, 1) - 1);
        deg_right = min(deg, size(right_pts, 1) - 1);

        p_left  = polyfit(left_pts(:,2),  left_pts(:,1),  deg_left);
        p_right = polyfit(right_pts(:,2), right_pts(:,1), deg_right);

        y_min = min(min(left_pts(:,2)), min(right_pts(:,2)));
        y_max = max(max(left_pts(:,2)), max(right_pts(:,2)));
        y_fit = linspace(y_min, y_max, 100)';

        x_left_fit  = polyval(p_left,  y_fit);
        x_right_fit = polyval(p_right, y_fit);
    end
end

