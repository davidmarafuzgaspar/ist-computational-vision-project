%% LINHAS SUAVES CONTÍNUAS POR STRIP (BAIXO PARA CIMA, SEM INVENTAR PONTOS)
clear; clc; close all;

%% 1. Load data
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
N = length(filenames);

%% 2. Parâmetros
min_pixels = 100;
theta_min = -50; theta_max = 50;
x_thresh = 20;
n_strips = 3;

ROI_BL_X = 0.05; ROI_BR_X = 0.95;
ROI_TL_X = 0.3;  ROI_TR_X = 0.7;
ROI_TOP_Y = 0.45;

cols = 5;
rows = ceil(N/cols);

%% 3. Preprocessamento DoG + Otsu + Clean
images_otsu_dog = cell(N,1);
for i = 1:N
    img = imread(filenames{i});
    if size(img,3)==3, img = rgb2gray(img); end
    g1 = imgaussfilt(img,1);
    g2 = imgaussfilt(img,2);
    dog = imsubtract(g1,g2);
    level = graythresh(dog);
    bw = imbinarize(dog,level);
    bw = bwareaopen(bw,min_pixels);
    images_otsu_dog{i} = bw;
end

%% 4. Loop por imagem
figure('Name','Linhas Otimizadas Segmentadas', 'NumberTitle','off','Position',[0 0 2200 1200]);

for i = 1:N
    img_orig = imread(filenames{i});
    if size(img_orig,3)==1, img_orig = repmat(img_orig,[1 1 3]); end
    bw = images_otsu_dog{i};
    [h,w] = size(bw);

    roi_x = [ROI_BL_X*w, ROI_BR_X*w, ROI_TR_X*w, ROI_TL_X*w];
    roi_y = [h, h, ROI_TOP_Y*h, ROI_TOP_Y*h];
    mask = poly2mask(roi_x,roi_y,h,w);
    bw_roi = bw & mask;

    y_top = ROI_TOP_Y*h;
    y_bottom = h;
    strip_height = (y_bottom - y_top)/n_strips;

    left_segments = {};
    right_segments = {};

    % De baixo para cima
    for s = n_strips:-1:1
        y_start = round(y_top + (s-1)*strip_height);
        y_end   = round(y_top + s*strip_height);
        strip_mask = false(h,w);
        strip_mask(y_start:y_end,:) = true;
        bw_strip = bw_roi & strip_mask;

        [H,theta,rho] = hough(bw_strip);
        P = houghpeaks(H,12,'Threshold',ceil(0.3*max(H(:))));
        lines = houghlines(bw_strip,theta,rho,P,'FillGap',10,'MinLength',50);
        lines_theta = lines([lines.theta]>=theta_min & [lines.theta]<=theta_max);

        if isempty(lines_theta)
            % stop segment if no pixels in this strip
            break
        end

        % Seleciona até duas linhas principais
        line_lengths = arrayfun(@(l) norm(l.point1-l.point2), lines_theta);
        [~, idx_sort] = sort(line_lengths,'descend');
        selected_lines = [];
        for k = 1:numel(idx_sort)
            l = lines_theta(idx_sort(k));
            x_mean = mean([l.point1(1),l.point2(1)]);
            keep = true;
            for sl = selected_lines
                x_sel = mean([sl.point1(1),sl.point2(1)]);
                if abs(x_mean - x_sel)<x_thresh, keep=false; break; end
            end
            if keep, selected_lines = [selected_lines,l]; end
            if numel(selected_lines)>=2, break; end
        end

        if ~isempty(selected_lines)
            x_means = arrayfun(@(l) mean([l.point1(1),l.point2(1)]), selected_lines);
            [~, idx_left] = min(x_means); [~, idx_right] = max(x_means);
            l_left = selected_lines(idx_left);
            l_right = selected_lines(idx_right);

            left_segments{end+1}  = [l_left.point1; l_left.point2];
            right_segments{end+1} = [l_right.point1; l_right.point2];
        end
    end

    %% Plot
    subplot(rows,cols,i); imshow(img_orig); hold on;
    plot([roi_x roi_x(1)],[roi_y roi_y(1)],'r-','LineWidth',1.5);

    % Função para plotar cada segmento como spline suave
    plot_segments = @(segments) arrayfun(@(k) ...
        plot_segment_spline(segments{k}), 1:length(segments));

    % esquerda
    plot_segments(left_segments);
    % direita
    plot_segments(right_segments);

    title(sprintf('Img %d',i),'FontSize',8);
    hold off;
end
sgtitle('Linhas Otimizadas Suaves Segmentadas (Baixo para Cima, Sem Inventar Pontos)','FontSize',12,'FontWeight','bold');

%% Função auxiliar
function plot_segment_spline(pts)
    % pts: Nx2 [X,Y]
    [Y_unique, ~, idxu] = unique(pts(:,2));
    X_mean = accumarray(idxu, pts(:,1), [], @mean);
    if numel(Y_unique)>=2
        Y_spline = linspace(min(Y_unique), max(Y_unique), 50); % suavidade menor
        X_spline = interp1(Y_unique, X_mean, Y_spline, 'pchip');
        plot(X_spline,Y_spline,'g','LineWidth',2);
    end
end