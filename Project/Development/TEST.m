%% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 1 - Railway Line Detection via Computer Vision
%
%  Pipeline:
%   1. Trapezoid ROI mask  (poly2mask)
%   2. Grayscale → Histogram EQ → Gaussian Blur → mask
%   3. Edge detection  ×2:  Prewitt  |  Canny
%   4. Sliding-window rail point detection (bottom → top)
%      run independently on each edge map
%   5. Bézier curve fit through detected points
%   6. Visualisation: overview grid + per-image comparison panel
%% ============================================================
clear; clc; close all;

%% ----------------------------------------------------------
%  SECTION 1: LOAD ALL IMAGES
% -----------------------------------------------------------
filenames = {
    './Data/cortada11.png',   ... %  1 - OBSTRUCTED (rocks)
    './Data/Frame1253.jpg',   ... %  2 - clear
    './Data/Frame1291.jpg',   ... %  3 - clear
    './Data/Frame1532.jpg',   ... %  4 - clear (curved)
    './Data/Frame1603.jpg',   ... %  5 - clear (curved)
    './Data/Frame1616.jpg',   ... %  6 - OBSTRUCTED (rocks)
    './Data/image00756.jpg',  ... %  7 - clear (station)
    './Data/image02293.jpg',  ... %  8 - clear (railroad crossing)
    './Data/image04054.jpg',  ... %  9 - OBSTRUCTED (rocks)
    './Data/image04925.jpg',  ... % 10 - clear (dark/tunnel)
    './Data/image06026.jpg',  ... % 11 - clear (tunnel exit)
    './Data/j30.jpg',         ... % 12 - OBSTRUCTED (rocks)
    './Data/l20.jpg',         ... % 13 - OBSTRUCTED (vegetation)
    './Data/l23.jpg',         ... % 14 - OBSTRUCTED (vegetation)
    './Data/p8.jpg',          ... % 15 - OBSTRUCTED (rocks beside track)
};

labels = [1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 1, 1, 1];

descriptions = {
    'Obstructed - rocks'; ...
    'Clear - straight'; ...
    'Clear - straight'; ...
    'Clear - curved'; ...
    'Clear - curved'; ...
    'Obstructed - rocks'; ...
    'Clear - station'; ...
    'Clear - railroad crossing'; ...
    'Obstructed - rocks'; ...
    'Clear - dark tunnel'; ...
    'Clear - tunnel exit'; ...
    'Obstructed - rocks'; ...
    'Obstructed - vegetation'; ...
    'Obstructed - vegetation'; ...
    'Obstructed - rocks beside track'; ...
};

N = numel(filenames);
images = cell(N,1);
for i = 1:N
    images{i} = imread(filenames{i});
end
disp('Images loaded.');

%% ----------------------------------------------------------
%  SECTION 2: PARAMETERS
% -----------------------------------------------------------
BLUR_SIGMA = 2;        % Gaussian pre-blur sigma (shared by all detectors)

% Canny thresholds (normalised 0–1)
CANNY_LOW  = 0.05;
CANNY_HIGH = 0.15;

% Sliding window (pixels)
SLIDE_INTERVAL = 20;   % vertical step between windows
SLIDE_HEIGHT   = 20;   % window height
SLIDE_WIDTH    = 80;   % initial adaptive half-search width

% Detector labels
DET_NAMES  = {'Prewitt', 'Canny'};
N_DET      = numel(DET_NAMES);

%% ----------------------------------------------------------
%  SECTION 3: PROCESS EVERY IMAGE × EVERY DETECTOR
% -----------------------------------------------------------
%  results(img_idx, det_idx) holds detection output
results(N, N_DET) = struct( ...
    'left_pts',  [], ...
    'right_pts', [], ...
    'left_bez',  [], ...
    'right_bez', [], ...
    'annotated', [], ...
    'edge_map',  []);

roi_masks = cell(N,1);   % store once per image (same for all detectors)

for idx = 1:N
    img = images{idx};
    [imgH, imgW, ~] = size(img);

    % ── 1. Trapezoid ROI ───────────────────────────────────
    bottomLeft  = [round(0.10*imgW),  imgH              ];
    bottomRight = [round(0.90*imgW),  imgH              ];
    topLeft     = [round(0.35*imgW),  round(0.40*imgH)  ];
    topRight    = [round(0.65*imgW),  round(0.40*imgH)  ];

    polyX = [bottomLeft(1), topLeft(1), topRight(1), bottomRight(1)];
    polyY = [bottomLeft(2), topLeft(2), topRight(2), bottomRight(2)];

    roi_mask      = poly2mask(polyX, polyY, imgH, imgW);
    roi_masks{idx} = roi_mask;

    % ── 2. Shared pre-processing ───────────────────────────
    gray_full  = rgb2gray(img);
    histeq_img = histeq(gray_full);                           % histogram EQ
    blur_img   = imgaussfilt(double(histeq_img), BLUR_SIGMA); % Gaussian blur
    % uint8 version needed by Canny
    blur_u8    = uint8(blur_img);

    % ── 3. Edge maps ──────────────────────────────────────
    % --- Prewitt -------------------------------------------
    %   imgradient uses Prewitt kernels; returns gradient magnitude
    [Gmag_p, ~]  = imgradient(blur_u8, 'prewitt');
    prewitt_map  = Gmag_p .* double(roi_mask);   % mask outside ROI

    % --- Canny --------------------------------------------
    %   edge() returns a binary edge map
    canny_raw   = edge(blur_u8, 'canny', [CANNY_LOW CANNY_HIGH]);
    canny_map   = double(canny_raw) .* double(roi_mask);

    edge_maps = {prewitt_map, canny_map};

    % ── 4. Sliding-window detection on each edge map ───────
    rowTop    = round(0.40 * imgH);
    rowBottom = imgH;

    for d = 1:N_DET
        emap = edge_maps{d};

        left_pts  = [];
        right_pts = [];
        sw_ll = -1;  sw_lh = -1;
        sw_rl = -1;  sw_rh = -1;

        row_positions = (rowBottom - SLIDE_HEIGHT) : -SLIDE_INTERVAL : rowTop;

        for r_idx = 1:numel(row_positions)
            r     = row_positions(r_idx);
            r_end = min(r + SLIDE_HEIGHT - 1, rowBottom);
            cy    = round((r + r_end) / 2);

            % Trapezoid column bounds at this row
            t_frac   = (rowBottom - cy) / max(1, rowBottom - rowTop);
            trap_lx  = round(bottomLeft(1)  + (topLeft(1)  - bottomLeft(1))  * t_frac);
            trap_rx  = round(bottomRight(1) + (topRight(1) - bottomRight(1)) * t_frac);
            trap_mid = round((trap_lx + trap_rx) / 2);

            % Initialise on first pass
            if sw_ll < 0
                sw_ll = trap_lx;
                sw_lh = trap_mid - 5;
                sw_rl = trap_mid + 5;
                sw_rh = trap_rx;
            end

            % Clamp to trapezoid
            sw_ll = max(trap_lx,  sw_ll);
            sw_lh = min(trap_mid, sw_lh);
            sw_rl = max(trap_mid, sw_rl);
            sw_rh = min(trap_rx,  sw_rh);

            if sw_lh <= sw_ll,  sw_lh = sw_ll + 1; end
            if sw_rh <= sw_rl,  sw_rh = sw_rl + 1; end

            % Column profiles
            left_prof  = sum(emap(r:r_end, sw_ll:sw_lh), 1);
            right_prof = sum(emap(r:r_end, sw_rl:sw_rh), 1);

            % Left rail
            [~, lmax] = max(left_prof);
            if lmax > 1
                lx = sw_ll + lmax - 1;
                left_pts(end+1, :) = [lx, cy]; %#ok<AGROW>
                half  = max(5, round(SLIDE_WIDTH / (r_idx*0.3 + 1)));
                sw_ll = max(trap_lx,  lx - half);
                sw_lh = min(trap_mid, lx + half);
            end

            % Right rail
            [~, rmax] = max(right_prof);
            if rmax > 1
                rx = sw_rl + rmax - 1;
                right_pts(end+1, :) = [rx, cy]; %#ok<AGROW>
                half  = max(5, round(SLIDE_WIDTH / (r_idx*0.3 + 1)));
                sw_rl = max(trap_mid, rx - half);
                sw_rh = min(trap_rx,  rx + half);
            end
        end

        % ── 5. Bézier curves ──────────────────────────────
        bez_left  = [];
        bez_right = [];
        if size(left_pts,  1) >= 2,  bez_left  = bezier_curve(left_pts,  150); end
        if size(right_pts, 1) >= 2,  bez_right = bezier_curve(right_pts, 150); end

        % ── 6. Annotated image ────────────────────────────
        annotated = img;

        % Blue tint inside ROI
        for c = 1:3
            ch = double(annotated(:,:,c));
            if c == 3
                ch(roi_mask) = min(255, ch(roi_mask)*0.7 + 60);
            else
                ch(roi_mask) = ch(roi_mask) * 0.85;
            end
            annotated(:,:,c) = uint8(ch);
        end

        % Yellow trapezoid outline
        annotated = draw_polygon(annotated, polyX, polyY, [255 220 0], 2);

        % White detection points
        for k = 1:size(left_pts,1)
            annotated = draw_dot(annotated, left_pts(k,1), left_pts(k,2), [255 255 255], 4);
        end
        for k = 1:size(right_pts,1)
            annotated = draw_dot(annotated, right_pts(k,1), right_pts(k,2), [255 255 255], 4);
        end

        % Bézier curves
        if ~isempty(bez_left),  annotated = draw_polyline(annotated, bez_left,  [255 50  50 ], 3); end
        if ~isempty(bez_right), annotated = draw_polyline(annotated, bez_right, [50  50  255], 3); end

        % Store
        results(idx,d).left_pts  = left_pts;
        results(idx,d).right_pts = right_pts;
        results(idx,d).left_bez  = bez_left;
        results(idx,d).right_bez = bez_right;
        results(idx,d).annotated = annotated;
        results(idx,d).edge_map  = uint8(255 * mat2gray(emap));
    end
end
disp('Detection complete.');

%% ----------------------------------------------------------
%  SECTION 4: OVERVIEW GRIDS  (one figure per detector)
% -----------------------------------------------------------
for d = 1:N_DET
    figure('Name', sprintf('Figure %d – %s Detection', d+1, DET_NAMES{d}), ...
           'NumberTitle', 'off', 'Position', [0 0 1600 960]);

    for i = 1:N
        subplot(3,5,i);
        imshow(results(i,d).annotated);
        nL  = size(results(i,d).left_pts,  1);
        nR  = size(results(i,d).right_pts, 1);
        col = [0 0.5 0];
        if labels(i) == 1, col = [0.8 0 0]; end
        [~, name, ext] = fileparts(filenames{i});
        title(sprintf('[%d] %s\nL:%d  R:%d pts', i, [name ext], nL, nR), ...
              'FontSize', 7, 'Color', col, 'Interpreter', 'none');
    end
    sgtitle(sprintf('%s  —  Rail Detection  (yellow=ROI | red=left | blue=right)', ...
            DET_NAMES{d}), 'FontSize', 12, 'FontWeight', 'bold');
end

%% ----------------------------------------------------------
%  SECTION 5: PER-IMAGE COMPARISON PANEL
%  Rows: Original | Prewitt edge | Prewitt result | Canny edge | Canny result
% -----------------------------------------------------------
for idx = 1:N
    img = images{idx};

    figure('Name', sprintf('Image %d – %s', idx, descriptions{idx}), ...
           'NumberTitle', 'off', 'Position', [30 30 1400 560]);

    % Col 1: original
    subplot(2,5,1);  imshow(img);
    title('Original', 'FontWeight', 'bold');
    subplot(2,5,6);  imshow(img);
    title('Original', 'FontWeight', 'bold');

    % Cols 2-3: Prewitt
    subplot(2,5,2);
    imshow(results(idx,1).edge_map);
    title('Prewitt edge map', 'FontWeight', 'bold');

    subplot(2,5,3);
    imshow(results(idx,1).annotated);
    nL = size(results(idx,1).left_pts,1);
    nR = size(results(idx,1).right_pts,1);
    title(sprintf('Prewitt rails  L:%d R:%d', nL, nR), 'FontWeight', 'bold');

    % Cols 4-5: Canny
    subplot(2,5,4);
    imshow(results(idx,2).edge_map);
    title('Canny edge map', 'FontWeight', 'bold');

    subplot(2,5,5);
    imshow(results(idx,2).annotated);
    nL = size(results(idx,2).left_pts,1);
    nR = size(results(idx,2).right_pts,1);
    title(sprintf('Canny rails  L:%d R:%d', nL, nR), 'FontWeight', 'bold');

    % Bottom row: pre-processing steps
    gray_full  = rgb2gray(img);
    histeq_img = histeq(gray_full);
    blur_img   = imgaussfilt(double(histeq_img), BLUR_SIGMA);
    blur_masked = uint8(blur_img .* double(roi_masks{idx}));

    subplot(2,5,7);  imshow(gray_full);    title('Grayscale',          'FontWeight','bold');
    subplot(2,5,8);  imshow(histeq_img);   title('Hist. Equalised',    'FontWeight','bold');
    subplot(2,5,9);  imshow(blur_masked);  title('Blur + ROI Mask',    'FontWeight','bold');

    % Bottom-right: label
    subplot(2,5,10); imshow(img);
    if labels(idx) == 0
        title('GT: CLEAR',      'FontWeight','bold','Color',[0 0.6 0]);
    else
        title('GT: OBSTRUCTED', 'FontWeight','bold','Color',[0.8 0 0]);
    end

    sgtitle(sprintf('[%d] %s  —  %s', idx, ...
        strrep(filenames{idx},'./Data/',''), descriptions{idx}), ...
        'FontSize', 11, 'FontWeight', 'bold', 'Interpreter', 'none');
end

%% ----------------------------------------------------------
%  SECTION 6: SUMMARY TABLE
% -----------------------------------------------------------
fprintf('\n%-25s | %-10s', 'Filename', 'GT Label');
for d = 1:N_DET
    fprintf(' | %-14s', sprintf('%s L/R pts', DET_NAMES{d}));
end
fprintf('\n%s\n', repmat('-',1,80));

for i = 1:N
    [~, fname, ext] = fileparts(filenames{i});
    lbl = 'CLEAR';  if labels(i), lbl = 'OBSTRUCTED'; end
    fprintf('%-25s | %-10s', [fname ext], lbl);
    for d = 1:N_DET
        nL = size(results(i,d).left_pts,  1);
        nR = size(results(i,d).right_pts, 1);
        fprintf(' | %5d / %-7d', nL, nR);
    end
    fprintf('\n');
end

%% ----------------------------------------------------------
%  SECTION 7: SAVE
% -----------------------------------------------------------
if ~exist('./Output','dir'), mkdir('./Output'); end
save('./Output/workspace_phase1.mat', ...
     'images','filenames','labels','descriptions','N','results','DET_NAMES');
fprintf('\nWorkspace saved → ./Output/workspace_phase1.mat\n');


%% ==========================================================
%  LOCAL HELPER FUNCTIONS
%% ==========================================================

function pts = bezier_curve(control_pts, n_steps)
% BEZIER_CURVE  Bernstein-polynomial Bézier curve.
%   control_pts : M×2 [x y]
%   n_steps     : number of output sample points
%   Returns     : n_steps×2 [x y] integer coordinates
    n = size(control_pts, 1);
    t = linspace(0, 1, n_steps)';
    B = zeros(n_steps, n);
    for i = 1:n
        k = i - 1;
        B(:,i) = nchoosek(n-1,k) .* (t.^(n-1-k)) .* ((1-t).^k);
    end
    pts = [round(B * control_pts(:,1)), round(B * control_pts(:,2))];
end


function img = draw_dot(img, cx, cy, colour, radius)
    [H, W, ~] = size(img);
    [xx, yy]  = meshgrid(1:W, 1:H);
    mask = (xx-cx).^2 + (yy-cy).^2 <= radius^2;
    for c = 1:3
        ch = img(:,:,c);  ch(mask) = colour(c);  img(:,:,c) = ch;
    end
end


function img = draw_polyline(img, pts, colour, thickness)
    [H, W, ~] = size(img);
    half = floor(thickness/2);
    for k = 1:size(pts,1)-1
        ns = max(abs(pts(k+1,1)-pts(k,1)), abs(pts(k+1,2)-pts(k,2))) + 1;
        xs = round(linspace(pts(k,1), pts(k+1,1), ns));
        ys = round(linspace(pts(k,2), pts(k+1,2), ns));
        for th = -half:half
            xc  = max(1,min(W,xs));
            yc  = max(1,min(H,ys+th));
            lin = sub2ind([H W], yc, xc);
            for c = 1:3
                ch = img(:,:,c);  ch(lin) = colour(c);  img(:,:,c) = ch;
            end
        end
    end
end


function img = draw_polygon(img, px, py, colour, thickness)
    n = numel(px);
    for k = 1:n
        k2 = mod(k,n)+1;
        img = draw_polyline(img, [px(k),py(k); px(k2),py(k2)], colour, thickness);
    end
end