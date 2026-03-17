% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 6 - BLOB Orientation Filtering and Final Reconstruction
%
%  Authors:
%   - David Marafuz Gaspar - 106541
%   - Pedro Gaspar Mónico - 106626
%
% ============================================================
clear; clc; close all;
load('./Output/workspace_phase5.mat');
disp('Workspace from Phase 5 loaded');

%% Live Script Comment
% Following the initial morphological closing, the resulting binary image
% contains both true rail BLOBs and spurious responses from ballast,
% vegetation, and other background structures. To isolate the rails,
% an orientation filtering step is applied: each connected component
% (BLOB) is measured using regionprops, and only those whose absolute
% orientation falls within a defined angular range are retained. The
% orientation threshold was calibrated on a subset of clear track images
% by inspecting the distribution of BLOB orientations. Following
% filtering, a second closing with a large 50×50 SE is applied to
% produce the final solid binary representation of the rails.

%% ----------------------------------------------------------
%  SECTION 1: ORIENTATION THRESHOLD CALIBRATION
% -----------------------------------------------------------

%% Live Script Comment
% Before applying the orientation filter, the BLOB orientation
% distribution is inspected across all images. This informs the
% selection of the angular thresholds theta_min and theta_max,
% analogous to the calibration procedure described in the reference
% paper (61–83 degrees). The distribution is printed and plotted
% to allow visual inspection.

all_orientations = [];

for i = 1:N
    props = regionprops(images_closed{i}, 'Orientation', 'Area');

    % Discard very small BLOBs — likely noise rather than rail segments
    min_area = 50;
    for k = 1:length(props)
        if props(k).Area >= min_area
            all_orientations(end+1) = abs(props(k).Orientation); %#ok<AGROW>
        end
    end
end

% --- Figure 16: BLOB Orientation Distribution ---
figure('Name', 'Figure 16 - BLOB Orientation Distribution', ...
    'NumberTitle', 'off', ...
    'Position', [0, 0, 800, 400]);

histogram(all_orientations, 36, 'FaceColor', [0.2 0.5 0.8], ...
    'EdgeColor', 'none');
xlabel('|Orientation| (degrees)');
ylabel('Count');
title('Figure 16 — BLOB Orientation Distribution (all images, area \geq 50)');
grid on;

fprintf('\nOrientation statistics:\n');
fprintf('  Min:    %.1f deg\n', min(all_orientations));
fprintf('  Max:    %.1f deg\n', max(all_orientations));
fprintf('  Mean:   %.1f deg\n', mean(all_orientations));
fprintf('  Median: %.1f deg\n', median(all_orientations));

%% ----------------------------------------------------------
%  SECTION 2: DEFINE FILTERING PARAMETERS
% -----------------------------------------------------------

% Angular range for valid rail BLOBs (degrees).
% Initial values taken from the reference paper (61-83 deg).
% Adjust based on the orientation distribution in Figure 16.
theta_min = 61;
theta_max = 83;

% Minimum BLOB area — discards small noise responses before filtering
min_blob_area = 50;

% Large SE for final reconstruction closing
se_final = strel('square', 50);

%% ----------------------------------------------------------
%  SECTION 3: ORIENTATION FILTERING AND FINAL RECONSTRUCTION
% -----------------------------------------------------------

images_filtered = cell(N, 1);
images_final    = cell(N, 1);

for i = 1:N
    % Label connected components in the closed edge map
    [labeled, num_blobs] = bwlabel(images_closed{i});
    props = regionprops(labeled, 'Orientation', 'Area', 'PixelIdxList');

    % Build filtered binary image retaining only valid rail BLOBs
    filtered = false(size(images_closed{i}));
    for k = 1:num_blobs
        angle = abs(props(k).Orientation);
        area  = props(k).Area;

        % Retain BLOB only if it passes both area and orientation tests
        if area >= min_blob_area && angle >= theta_min && angle <= theta_max
            filtered(props(k).PixelIdxList) = true;
        end
    end

    images_filtered{i} = filtered;

    % Final closing with large SE to produce solid rail representation
    images_final{i} = imclose(filtered, se_final);
end

%% Live Script Comment
% Figures 17 to 19 show, for each image, the three stages of the
% reconstruction pipeline: the initial 7×7 closed edge map, the
% orientation-filtered BLOBs, and the final binary rail representation
% after the 50×50 closing. This progression allows direct assessment
% of how many spurious BLOBs are removed by the orientation filter
% and how well the final closing consolidates the retained rail segments.

%% ----------------------------------------------------------
%  SECTION 4: DISPLAY INTERMEDIATE STEPS
% -----------------------------------------------------------

for f = 1:3
    figure('Name', sprintf('Figure %d - Reconstruction Pipeline (%d to %d)', ...
        f+16, (f-1)*5+1, f*5), ...
        'NumberTitle', 'off', ...
        'Position', [0, 0, 1400, 900]);

    for k = 1:5
        i = (f-1)*5 + k;
        [~, name, ext] = fileparts(filenames{i});

        if labels(i) == 0
            col    = [0 0.5 0];
            status = 'CLEAR';
        else
            col    = [0.8 0 0];
            status = 'OBSTRUCTED';
        end

        % Step 1: Closed edge map (7x7)
        subplot(5, 3, (k-1)*3 + 1);
        imshow(images_closed{i});
        title(sprintf('[%d] %s — %s\nClosed 7×7', i, [name ext], status), ...
            'FontSize', 7, 'Color', col, 'Interpreter', 'none');

        % Step 2: Orientation filtered BLOBs
        subplot(5, 3, (k-1)*3 + 2);
        imshow(images_filtered{i});
        title(sprintf('Orientation Filtered\n[%d°, %d°]', ...
            theta_min, theta_max), ...
            'FontSize', 7, 'Color', col);

        % Step 3: Final reconstruction (50x50 closing)
        subplot(5, 3, (k-1)*3 + 3);
        imshow(images_final{i});
        title('Final Reconstruction\nClose 50×50', ...
            'FontSize', 7, 'Color', col);
    end

    sgtitle(sprintf('Figure %d — Reconstruction Pipeline: Images %d to %d  (green = clear  |  red = obstructed)', ...
        f+16, (f-1)*5+1, f*5), ...
        'FontSize', 12, 'FontWeight', 'bold');
end

%% Live Script Comment
% Figure 20 presents the final binary rail representations across all
% 15 images as a grid overview. This is the output of the complete
% segmentation pipeline and will serve as the basis for the subsequent
% obstacle detection stage, where the vertical extent of the segmented
% rails is used to classify each image as clear or obstructed.

%% ----------------------------------------------------------
%  SECTION 5: FINAL RESULT GRID (FULL DATASET)
% -----------------------------------------------------------

figure('Name', 'Figure 20 - Final Rail Segmentation', ...
    'NumberTitle', 'off', ...
    'Position', [0, 0, 1500, 900]);

for i = 1:N
    subplot(3, 5, i);
    imshow(images_final{i});

    if labels(i) == 0
        col = [0 0.5 0];
    else
        col = [0.8 0 0];
    end

    [~, name, ext] = fileparts(filenames{i});
    title(sprintf('[%d] %s\n%s', i, [name ext], descriptions{i}), ...
        'FontSize', 7, 'Color', col, 'Interpreter', 'none');
end

sgtitle('Figure 20 — Final Rail Segmentation  (green = clear  |  red = obstructed)', ...
    'FontSize', 13, 'FontWeight', 'bold');

%% ----------------------------------------------------------
%  SECTION 6: SAVE WORKSPACE
% -----------------------------------------------------------
save('./Output/workspace_phase6.mat', ...
    'images', 'images_gray', 'images_eq', 'images_smooth', ...
    'images_roi', 'masks', 'images_canny', 'images_closed', ...
    'images_filtered', 'images_final', ...
    'filenames', 'labels', 'descriptions', 'N', ...
    'subset_idx', 'subset_names', ...
    'best_canny_sensitivity', 'theta_min', 'theta_max', ...
    'min_blob_area', 'se_final');
fprintf('\nWorkspace saved to ./Output/workspace_phase6.mat\n');    