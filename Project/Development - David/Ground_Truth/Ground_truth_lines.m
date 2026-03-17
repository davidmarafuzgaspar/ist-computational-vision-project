%% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  GROUND TRUTH — Manual Rail Annotation
%
%  HOW TO USE:
%    - LEFT rail:  click points along rail → ENTER
%    - RIGHT rail: click points along rail → ENTER
%    - Not visible: ENTER immediately (no clicks)
%
%% ============================================================
clear; clc; close all;

%% ----------------------------------------------------------
%  LOAD IMAGES DIRECTLY FROM DATA FOLDER
% -----------------------------------------------------------

datasetPath = '../Data/';
imgFiles = [dir(fullfile(datasetPath, '*.jpg')); ...
            dir(fullfile(datasetPath, '*.png'))];

N = length(imgFiles);
fprintf('Found %d images.\n', N);

%% ----------------------------------------------------------
%  ANNOTATION LOOP
% -----------------------------------------------------------

gt = struct();   % will store one entry per image

for i = 1:N

    fname  = imgFiles(i).name;
    fpath  = fullfile(imgFiles(i).folder, fname);
    imgRGB = imread(fpath);

    fprintf('[%d/%d] %s\n', i, N, fname);

    figure('Name', fname, 'NumberTitle', 'off', ...
        'Position', [80 80 950 720]);

    % --- LEFT RAIL ---
    imshow(imgRGB);
    title({'LEFT RAIL (red) — click points → ENTER', ...
           '(ENTER with no clicks = not visible)'}, 'FontSize', 11);

    [x_l, y_l] = ginput();

    hold on;
    if ~isempty(x_l)
        plot(x_l, y_l, 'r.-', 'MarkerSize', 14, 'LineWidth', 2);
    end

    % --- RIGHT RAIL ---
    title({'RIGHT RAIL (green) — click points → ENTER', ...
           '(ENTER with no clicks = not visible)'}, 'FontSize', 11);

    [x_r, y_r] = ginput();

    if ~isempty(x_r)
        plot(x_r, y_r, 'g.-', 'MarkerSize', 14, 'LineWidth', 2);
    end

    title(sprintf('Done — L:%d pts  R:%d pts', length(x_l), length(x_r)), ...
        'FontSize', 11);
    hold off;
    pause(1);
    close;

    % --- Save entry ---
    gt(i).filename = fname;
    gt(i).left     = [x_l, y_l];   % Nx2 matrix, empty if skipped
    gt(i).right    = [x_r, y_r];   % Nx2 matrix, empty if skipped

    % Auto-save after every image
    save('../Output/ground_truth.mat', 'gt');
    fprintf('  Saved: L=%d pts  R=%d pts\n\n', length(x_l), length(x_r));

end

fprintf('Done. Ground truth saved to ../Output/ground_truth.mat\n');