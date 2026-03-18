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
% HOUGH TRANSFORM PER STRIP COM FILTRO DE THETA + TOP 2 LINHAS SEPARADAS
% =========================

cols = 5;
rows = ceil(N/cols);

% ROI trapezoid parameters
ROI_BL_X = 0.05; ROI_BR_X = 0.95;
ROI_TL_X = 0.3; ROI_TR_X = 0.7;
ROI_TOP_Y = 0.45;

min_pixels = 100;
se_disk = strel('disk', 3);
se_line_h = strel('line', 5, 0);

% Faixa de theta aceitável (em graus)
theta_min = -50;
theta_max = 50;

% Distância horizontal mínima entre linhas (pixels)
x_thresh = 20;

figure('Name','Hough Transform per Strip (Theta Filter, Top 2 Separated)','NumberTitle','off','Position',[0 0 2200 1200]);

for i = 1:N
    bw = images_otsu_dog{i};
    [h, w] = size(bw);

    % ROI completo
    roi_x = [ROI_BL_X*w, ROI_BR_X*w, ROI_TR_X*w, ROI_TL_X*w];
    roi_y = [h, h, ROI_TOP_Y*h, ROI_TOP_Y*h];
    mask = poly2mask(roi_x, roi_y, h, w);

    bw_roi = bw & mask;
    bw_clean = bwareaopen(bw_roi, min_pixels);

    % Divide ROI em 3 strips
    y_top = ROI_TOP_Y*h;
    y_bottom = h;
    strip_height = (y_bottom - y_top)/3;

    subplot(rows, cols, i);
    imshow(bw_clean); hold on;
    plot([roi_x roi_x(1)], [roi_y roi_y(1)], 'r-', 'LineWidth', 1);

    colors = {'g','c','y'};

    for s = 1:3
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

                % Verifica se está suficientemente distante das já escolhidas
                keep = true;
                for sl = selected_lines
                    x_selected = mean([sl.point1(1), sl.point2(1)]);
                    if abs(x_mean - x_selected) < x_thresh
                        keep = false;
                        break;
                    end
                end

                if keep
                    selected_lines = [selected_lines, line_xy];
                end

                if numel(selected_lines) >= 2
                    break; % já temos 2 linhas separadas
                end
            end

            % Plotar apenas as linhas selecionadas
            for l = selected_lines
                xy = [l.point1; l.point2];
                plot(xy(:,1), xy(:,2), 'LineWidth', 2, 'Color', colors{s});
            end
        end
    end

    title(sprintf('[%d]', i),'FontSize',8);
    hold off;
end

sgtitle('Hough Transform on Otsu(DoG) + ROI per Strip (Top 2 Separated by X)','FontSize',12,'FontWeight','bold');