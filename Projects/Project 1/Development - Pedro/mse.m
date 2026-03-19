%% ============================================================
%  GROUND TRUTH — Visualisation Grid dentro do ROI
%  Plots all images with GT in blue, ROI in red
%% ============================================================

clear; clc; close all;

load('./Output/ground_truth.mat');

datasetPath = './Data/';
N = length(gt);

% --- Definir ROI trapezoidal (mesmo que no pipeline de otimização)
ROI_BL_X = 0.05; ROI_BR_X = 0.95;
ROI_TL_X = 0.3;  ROI_TR_X = 0.7;
ROI_TOP_Y = 0.45;

cols = 5;
rows = ceil(N/cols);

figure('Name', 'Ground Truth — Rail Annotations inside ROI', ...
    'NumberTitle', 'off', 'Position', [0 0 1600 950]);

for i = 1:N
    imgPath = fullfile(datasetPath, gt(i).filename);
    if exist(imgPath,'file')
        imgRGB = imread(imgPath);
    else
        warning('Imagem %s não encontrada, apenas plot linhas.', gt(i).filename);
        imgRGB = uint8(zeros(480,640,3));
    end
    [h,w,~] = size(imgRGB);

    % --- Cria máscara ROI
    roi_x = [ROI_BL_X*w, ROI_BR_X*w, ROI_TR_X*w, ROI_TL_X*w];
    roi_y = [h, h, ROI_TOP_Y*h, ROI_TOP_Y*h];
    mask = poly2mask(roi_x, roi_y, h, w);

    subplot(rows,cols,i);
    imshow(imgRGB); hold on;

    % --- Desenha ROI
    plot([roi_x roi_x(1)], [roi_y roi_y(1)], 'r-', 'LineWidth', 1.5);
% Left rail
if ~isempty(gt(i).left)
    x_l = gt(i).left(:,1);
    y_l = gt(i).left(:,2);
    inside = inpolygon(x_l, y_l, roi_x, roi_y); % lógico, pontos dentro do ROI

    % encontrar segmentos contínuos dentro do ROI
    d = diff([0; inside; 0]); % detecta entradas e saídas
    start_idx = find(d == 1); % início do segmento dentro do ROI
    end_idx   = find(d == -1)-1; % fim do segmento

    for k = 1:length(start_idx)
        seg_idx = start_idx(k):end_idx(k);
        plot(x_l(seg_idx), y_l(seg_idx), 'b.-', 'LineWidth', 2, 'MarkerSize', 10);
    end
end
% Right rail
if ~isempty(gt(i).right)
    x_r = gt(i).right(:,1);
    y_r = gt(i).right(:,2);
    inside = inpolygon(x_r, y_r, roi_x, roi_y);

    d = diff([0; inside; 0]);
    start_idx = find(d == 1);
    end_idx   = find(d == -1)-1;

    for k = 1:length(start_idx)
        seg_idx = start_idx(k):end_idx(k);
        plot(x_r(seg_idx), y_r(seg_idx), 'b.-', 'LineWidth', 2, 'MarkerSize', 10);
    end
end

    hold off;
    title(sprintf('[%d] %s', i, gt(i).filename), ...
        'FontSize', 7, 'Interpreter', 'none');
end

sgtitle('Ground Truth — Manual Rail Annotations dentro do ROI (blue = GT, red = ROI)', ...
    'FontSize', 13, 'FontWeight', 'bold');