% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 0 - Setup, Loading and First Visualizations
%
%  Authors:
%   - David Marafuz Gaspar - 106541
%   - Pedro Gaspar Mónico - 106626
%
% ============================================================
clear; clc; close all;

%% Live Script Comment
% This initial phase establishes the dataset structure for the remainder of 
% the pipeline. Images are loaded, assigned ground-truth labels based on 
% manual visual inspection, and displayed as an overview. The class 
% distribution is also reported, as it is relevant when interpreting 
% classification performance metrics in later phases. This initial 
% characterisation informs subsequent design decisions regarding
% preprocessing and segmentation strategies.

%% ----------------------------------------------------------
%  SECTION 1: LOAD ALL IMAGES
% -----------------------------------------------------------
filenames = {
'./Data/cortada11.png',   ... % 1  - OBSTRUCTED
'./Data/Frame1253.jpg',   ... % 2  - clear
'./Data/Frame1291.jpg',   ... % 3  - clear
'./Data/Frame1532.jpg',   ... % 4  - clear
'./Data/Frame1603.jpg',   ... % 5  - clear
'./Data/Frame1616.jpg',   ... % 6  - OBSTRUCTED
'./Data/image00756.jpg',  ... % 7  - clear
'./Data/image02293.jpg',  ... % 8  - clear
'./Data/image04054.jpg',  ... % 9  - OBSTRUCTED
'./Data/image04925.jpg',  ... % 10 - clear
'./Data/image06026.jpg',  ... % 11 - clear
'./Data/j30.jpg',         ... % 12 - OBSTRUCTED
'./Data/l20.jpg',         ... % 13 - OBSTRUCTED
'./Data/l23.jpg',         ... % 14 - OBSTRUCTED
'./Data/p8.jpg',          ... % 15 - OBSTRUCTED
};

% Binary ground-truth: 0 = clear, 1 = obstructed.
% Assigned by manual visual inspection; this will be used as reference
% for performance evaluation in later phases.
labels = [1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 1, 1, 1];

% Scene descriptions used for figure annotations
% and qualitative analysis of results.
descriptions = {
'Obstructed - Rocks',
'Clear - Straight',
'Clear - Straight',
'Clear - Curved',
'Clear - Curved',
'Obstructed - Rocks',
'Clear - Station',
'Clear - Railroad crossing',
'Obstructed - Rocks',
'Clear - Dark tunnel',
'Clear - Tunnel exit',
'Obstructed - Rocks',
'Obstructed - Vegetation',
'Obstructed - Vegetation',
'Obstructed - Rocks beside track',
};

N = length(filenames);

% Cell array accommodates images of different resolutions
images = cell(N, 1);
for i = 1:N
    images{i} = imread(filenames{i});
end
disp('Images loaded successfully');

% Class distribution — relevant when interpreting
% classification metrics in later phases.
fprintf('\nTotal images:  %d\n', N);
fprintf('Clear:         %d\n', sum(labels == 0));
fprintf('Obstructed:    %d\n', sum(labels == 1));

%% Live Script Comment
% The output confirms a near-balanced dataset of 15 images, with a
% distribution of 8 obstructed to 7 clear — approximately 50/50. Figure 1
% presents a complete visual overview of the dataset, colour-coded by
% ground-truth label (green = clear, red = obstructed). This mosaic
% captures the visual diversity present in the dataset — in terms of
% lighting conditions, track geometry, and obstruction type — and serves
% as the qualitative baseline reference for the remainder of the project.

%% ----------------------------------------------------------
%  SECTION 2: DISPLAY ALL IMAGES (RGB)
% -----------------------------------------------------------
figure('Name', 'Figure 1 - Full Dataset Overview', ...
    'NumberTitle', 'off', ...
    'Position', [0, 0, 1500, 900]);

for i = 1:N
    subplot(3, 5, i);
    imshow(images{i});

    % Colour-code titles by class for immediate visual distinction
    if labels(i) == 0
        col = [0 0.5 0];   % green — clear
    else
        col = [0.8 0 0];   % red   — obstructed
    end

    [~, name, ext] = fileparts(filenames{i});
    title(sprintf('[%d] %s\n%s', i, [name ext], descriptions{i}), ...
        'FontSize', 7, 'Color', col, 'Interpreter', 'none');
end

sgtitle('Figure 1 — Full Dataset Overview  (Green = Clear  |  Red = Obstructed)', ...
    'FontSize', 13, 'FontWeight', 'bold');

%% ----------------------------------------------------------
%  SECTION 4: SAVE WORKSPACE (Remove for report)
% -----------------------------------------------------------
save('./Output/workspace_phase0.mat', ...
    'images', 'filenames', 'labels', 'descriptions', 'N');
fprintf('\nWorkspace saved to ./Output/workspace_phase0.mat\n');