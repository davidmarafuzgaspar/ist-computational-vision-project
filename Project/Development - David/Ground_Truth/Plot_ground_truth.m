%% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  GROUND TRUTH — Visualisation Grid
%  Plots all 15 images with annotated left (red) and right
%  (green) rail polylines overlaid
%
%% ============================================================
clear; clc; close all;

load('../Output/ground_truth.mat');

datasetPath = '../Data/';
N = length(gt);

figure('Name', 'Ground Truth — Rail Annotations', ...
    'NumberTitle', 'off', 'Position', [0 0 1600 950]);

for i = 1:N

    imgRGB = imread(fullfile(datasetPath, gt(i).filename));

    subplot(3, 5, i);
    imshow(imgRGB); hold on;

    if ~isempty(gt(i).left)
        plot(gt(i).left(:,1),  gt(i).left(:,2), ...
            'r.-', 'MarkerSize', 10, 'LineWidth', 2);
    end

    if ~isempty(gt(i).right)
        plot(gt(i).right(:,1), gt(i).right(:,2), ...
            'g.-', 'MarkerSize', 10, 'LineWidth', 2);
    end

    hold off;

    nL = size(gt(i).left,  1);
    nR = size(gt(i).right, 1);

    title(sprintf('[%d] %s\nL:%d pts  R:%d pts', i, gt(i).filename, nL, nR), ...
        'FontSize', 7, 'Interpreter', 'none');

end

sgtitle('Ground Truth — Manual Rail Annotations  (red = left rail  |  green = right rail)', ...
    'FontSize', 13, 'FontWeight', 'bold');