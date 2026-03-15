%% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 0 - Setup, Loading and First Visualizations
%
%% ============================================================
clear; clc; close all;

%% ----------------------------------------------------------
%  SECTION 1: LOAD ALL IMAGES
% -----------------------------------------------------------
filenames = {
    './Data/cortada11.png',   ... % 1  - OBSTRUCTED (rocks)
    './Data/Frame1253.jpg',   ... % 2  - clear
    './Data/Frame1291.jpg',   ... % 3  - clear
    './Data/Frame1532.jpg',   ... % 4  - clear (curved)
    './Data/Frame1603.jpg',   ... % 5  - clear (curved)
    './Data/Frame1616.jpg',   ... % 6  - OBSTRUCTED (rocks)
    './Data/image00756.jpg',  ... % 7  - clear (station)
    './Data/image02293.jpg',  ... % 8  - clear (railroad crossing)
    './Data/image04054.jpg',  ... % 9  - OBSTRUCTED (rocks)
    './Data/image04925.jpg',  ... % 10 - clear (dark/tunnel)
    './Data/image06026.jpg',  ... % 11 - clear (tunnel exit)
    './Data/j30.jpg',         ... % 12 - OBSTRUCTED (rocks)
    './Data/l20.jpg',         ... % 13 - OBSTRUCTED (vegetation)
    './Data/l23.jpg',         ... % 14 - OBSTRUCTED (vegetation)
    './Data/p8.jpg',          ... % 15 - OBSTRUCTED (rocks beside track)
};

% Ground truth: 0 = clear, 1 = obstructed
labels = [1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 1, 1, 1];

% Figure titles
descriptions = {
    'Obstructed - rocks',
    'Clear - straight',
    'Clear - straight',
    'Clear - curved',
    'Clear - curved',
    'Obstructed - rocks',
    'Clear - station',
    'Clear - railroad crossing',
    'Obstructed - rocks',
    'Clear - dark tunnel',
    'Clear - tunnel exit',
    'Obstructed - rocks',
    'Obstructed - vegetation',
    'Obstructed - vegetation',
    'Obstructed - rocks beside track',
};

N = length(filenames);

% Load all images into cell array
images = cell(N, 1);
for i = 1:N
    images{i} = imread(filenames{i});
end
disp('Images loaded successfully');


%% ----------------------------------------------------------
%  SECTION 2: IMAGE PROPERTIES TABLE
% -----------------------------------------------------------

fprintf('\n%-22s | %-12s | %-12s\n', ...
    'Filename', 'Size (HxW)', 'Label');
fprintf('%s\n', repmat('-', 1, 60));

for i = 1:N
    [~, name, ext] = fileparts(filenames{i});
    [h, w, ~] = size(images{i});

    if labels(i) == 0
        lbl_str = 'CLEAR';
    else
        lbl_str = 'OBSTRUCTED';
    end

    fprintf('%-22s | %4dx%-6d| %s\n', [name ext], h, w, lbl_str);
end

fprintf('\nTotal images:  %d\n', N);
fprintf('Clear:         %d\n', sum(labels == 0));
fprintf('Obstructed:    %d\n', sum(labels == 1));


%% ----------------------------------------------------------
%  SECTION 3: DISPLAY ALL IMAGES (RGB)
% -----------------------------------------------------------

figure('Name', 'Figure 1 - Full Dataset Overview', ...
    'NumberTitle', 'off', ...
    'Position', [0, 0, 1500, 900]);

for i = 1:N
    subplot(3, 5, i);
    imshow(images{i});

    if labels(i) == 0
        col = [0 0.5 0];
    else
        col = [0.8 0 0];
    end

    [~, name, ext] = fileparts(filenames{i});
    title(sprintf('[%d] %s\n%s', i, [name ext], descriptions{i}), ...
        'FontSize', 7, 'Color', col, 'Interpreter', 'none');
end

sgtitle('Figure 1 — Full Dataset Overview  (green = clear  |  red = obstructed)', ...
    'FontSize', 13, 'FontWeight', 'bold');


%% ----------------------------------------------------------
%  SECTION 4: SAVE WORKSPACE
% -----------------------------------------------------------

save('./Output/workspace_phase0.mat', ...
    'images', 'filenames', 'labels', 'descriptions', 'N');

fprintf('\nWorkspace saved to ./Output/workspace_phase0.mat\n');