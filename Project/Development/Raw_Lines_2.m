% ============================================================
%  PROJECT 1 - TOPIC B: RAILWAY INSPECTION
%
%  PHASE 1 - Full Modular Pipeline
%
%  Authors:
%   - David Marafuz Gaspar - 106541
%   - Pedro Gaspar Mónico - 106626
%
% ============================================================
clear; clc; close all;

load('./Output/workspace_phase0.mat');
disp('Workspace loaded successfully');

% ============================================================
%  PIPELINE CONFIGURATION — edit only this section
% ============================================================

%% --- ROI ---
CFG.roi.top_y   = 0.45;
CFG.roi.top_x_l = 0.25;
CFG.roi.top_x_r = 0.75;
CFG.roi.bot_x_l = 0.05;
CFG.roi.bot_x_r = 0.95;

%% --- PIPELINE STAGES ---
% Each stage is a struct with field 'type' and its own parameters.
% Stages are applied IN ORDER — add, remove, or reorder freely.
%
% Available types:
%
%  CONTRAST / EQUALISATION
%   'clahe'        — adaptive histogram equalisation
%   'histeq'       — global histogram equalisation
%   'imadjust'     — intensity stretching
%
%  SMOOTHING / DENOISING
%   'gaussian'     — Gaussian blur
%   'median'       — median filter
%   'mean'         — mean (box) filter
%   'bilateral'    — edge-preserving bilateral filter (requires imbilatfilt)
%
%  SHARPENING
%   'unsharp_auto' — MATLAB imsharpen()
%   'unsharp_manual'— manual: img + alpha*(img - gaussian(img))
%
%  MORPHOLOGY  (input should be binary — place after edge detection)
%   'dilate'       — morphological dilation
%   'erode'        — morphological erosion
%   'open'         — opening  (erode then dilate)
%   'close'        — closing  (dilate then erode)
%
%  EDGE DETECTION  (converts to binary — must come before morphology)
%   'canny'        — Canny edge detector
%   'sobel'        — Sobel
%   'prewitt'      — Prewitt
%   'log'          — Laplacian of Gaussian

CFG.stages = {
    struct('type', 'clahe', ...
           'tiles',  [8 8], ...
           'clip',   0.015), ...
    ...
    struct('type', 'gaussian', ...
           'sigma',  1.0), ...
    ...
    struct('type', 'canny', ...
           'adaptive', false, ...
           'low',      0.15, ...
           'high',     0.35, ...
           'adapt_k',  2.0), ...
};

% Uncomment below for a different example pipeline:
%
% CFG.stages = {
%     struct('type', 'histeq'), ...
%     struct('type', 'median',  'size', 5), ...
%     struct('type', 'unsharp_manual', 'sigma', 2.0, 'alpha', 0.5), ...
%     struct('type', 'canny', 'adaptive', true, 'low', 0.1, ...
%            'high', 0.3, 'adapt_k', 2.0), ...
%     struct('type', 'dilate', 'shape', 'line', 'size', 3), ...
% };

%% --- HOUGH ---
CFG.hough.mode        = 'strips';   % 'strips' | 'full'
CFG.hough.num_strips  = 3;
CFG.hough.num_peaks   = 2;
CFG.hough.thresh      = 0.2;
CFG.hough.fill_gap    = 15;
CFG.hough.min_length  = 40;
CFG.hough.angle_range = [-50, 50];

%% --- LINE FILTERING ---
CFG.filter.min_angle = 15;
CFG.filter.max_angle = 75;
CFG.filter.x_margin  = 0.25;

%% --- LINE FITTING ---
CFG.fit.mode      = 'per_strip';  % 'per_strip' | 'global'
CFG.fit.max_lines = 2;

%% --- OUTPUT ---
out_dir = './Output/modular/';
if ~exist(out_dir, 'dir'), mkdir(out_dir); end

% ============================================================
%  PIPELINE EXECUTION — do not edit below
% ============================================================

strip_colors = {[0.0 0.8 0.0], [1.0 0.3 0.0], [0.0 0.5 1.0], ...
                [0.8 0.0 0.8], [1.0 0.8 0.0]};

for i = 1:N

    img  = images{i};
    gray = rgb2gray(img);
    [imgH, imgW] = size(gray);

    % ----------------------------------------------------------
    % STEP 1 — ROI
    % ----------------------------------------------------------
    bottomLeft  = [round(CFG.roi.bot_x_l*imgW), imgH                        ];
    bottomRight = [round(CFG.roi.bot_x_r*imgW), imgH                        ];
    topLeft     = [round(CFG.roi.top_x_l*imgW), round(CFG.roi.top_y*imgH)   ];
    topRight    = [round(CFG.roi.top_x_r*imgW), round(CFG.roi.top_y*imgH)   ];
    polyX = [bottomLeft(1), topLeft(1), topRight(1), bottomRight(1)];
    polyY = [bottomLeft(2), topLeft(2), topRight(2), bottomRight(2)];

    mask = poly2mask(polyX, polyY, imgH, imgW);
    roi_masked = gray;
    roi_masked(~mask) = 0;

    row_min = min(polyY); row_max = max(polyY);
    col_min = min(polyX); col_max = max(polyX);
    roi_crop  = roi_masked(row_min:row_max, col_min:col_max);
    mask_crop = mask(row_min:row_max, col_min:col_max);

    % ----------------------------------------------------------
    % STEP 2 — EXECUTE STAGES IN ORDER
    % ----------------------------------------------------------
    working    = roi_crop;
    edges_full = [];
    canny_low  = 0;
    canny_high = 0;
    stage_log  = {};   % for title building

    for st = 1:length(CFG.stages)
        s = CFG.stages{st};

        switch s.type

            % ---- CONTRAST / EQUALISATION ----
            case 'clahe'
                working = adapthisteq(working, ...
                    'NumTiles',     s.tiles, ...
                    'ClipLimit',    s.clip, ...
                    'Distribution', 'uniform');
                working(~mask_crop) = 0;
                stage_log{end+1} = sprintf('CLAHE[%dx%d,%.3f]', ...
                    s.tiles(1), s.tiles(2), s.clip);

            case 'histeq'
                working = histeq(working);
                working(~mask_crop) = 0;
                stage_log{end+1} = 'HEQ';

            case 'imadjust'
                working = imadjust(working);
                working(~mask_crop) = 0;
                stage_log{end+1} = 'imadjust';

            % ---- SMOOTHING ----
            case 'gaussian'
                working = imgaussfilt(working, s.sigma);
                working(~mask_crop) = 0;
                stage_log{end+1} = sprintf('Gauss(%.1f)', s.sigma);

            case 'median'
                working = medfilt2(working, [s.size s.size]);
                working(~mask_crop) = 0;
                stage_log{end+1} = sprintf('Med(%d)', s.size);

            case 'mean'
                h       = fspecial('average', s.size);
                working = imfilter(working, h, 'replicate');
                working(~mask_crop) = 0;
                stage_log{end+1} = sprintf('Mean(%d)', s.size);

            case 'bilateral'
                working = imbilatfilt(working, s.deg_std, s.spatial_std);
                working(~mask_crop) = 0;
                stage_log{end+1} = sprintf('Bilat(%.1f,%.1f)', ...
                    s.deg_std, s.spatial_std);

            % ---- SHARPENING ----
            case 'unsharp_auto'
                working = imsharpen(working, ...
                    'Amount',    s.alpha, ...
                    'Radius',    s.radius, ...
                    'Threshold', 0);
                working(~mask_crop) = 0;
                stage_log{end+1} = sprintf('US-auto(%.1f)', s.alpha);

            case 'unsharp_manual'
                blurred  = imgaussfilt(working, s.sigma);
                um       = double(working) - double(blurred);
                enhanced = double(working) + s.alpha * um;
                working  = uint8(max(0, min(255, enhanced)));
                working(~mask_crop) = 0;
                stage_log{end+1} = sprintf('US-man(s=%.1f,a=%.1f)', ...
                    s.sigma, s.alpha);

            % ---- EDGE DETECTION ----
            case 'canny'
                if s.adaptive
                    norm_img   = double(working) / 255.0;
                    img_mean   = mean(norm_img(mask_crop));
                    img_std    = std(norm_img(mask_crop));
                    canny_high = min(0.9, img_mean + s.adapt_k * img_std);
                    canny_low  = 0.4 * canny_high;
                else
                    canny_low  = s.low;
                    canny_high = s.high;
                end
                edges_full = edge(working, 'Canny', [canny_low, canny_high]);
                edges_full(~mask_crop) = 0;
                stage_log{end+1} = sprintf('Canny[%.2f,%.2f]', ...
                    canny_low, canny_high);

            case 'sobel'
                edges_full = edge(working, 'Sobel');
                edges_full(~mask_crop) = 0;
                stage_log{end+1} = 'Sobel';

            case 'prewitt'
                edges_full = edge(working, 'Prewitt');
                edges_full(~mask_crop) = 0;
                stage_log{end+1} = 'Prewitt';

            case 'log'
                edges_full = edge(working, 'log');
                edges_full(~mask_crop) = 0;
                stage_log{end+1} = 'LoG';

            % ---- MORPHOLOGY (on binary edge image) ----
            case 'dilate'
                se         = strel(s.shape, s.size);
                edges_full = imdilate(edges_full, se);
                edges_full(~mask_crop) = 0;
                stage_log{end+1} = sprintf('Dil(%s,%d)', s.shape, s.size);

            case 'erode'
                se         = strel(s.shape, s.size);
                edges_full = imerode(edges_full, se);
                edges_full(~mask_crop) = 0;
                stage_log{end+1} = sprintf('Ero(%s,%d)', s.shape, s.size);

            case 'open'
                se         = strel(s.shape, s.size);
                edges_full = imopen(edges_full, se);
                edges_full(~mask_crop) = 0;
                stage_log{end+1} = sprintf('Open(%s,%d)', s.shape, s.size);

            case 'close'
                se         = strel(s.shape, s.size);
                edges_full = imclose(edges_full, se);
                edges_full(~mask_crop) = 0;
                stage_log{end+1} = sprintf('Close(%s,%d)', s.shape, s.size);

            otherwise
                warning('Unknown stage type: %s — skipped', s.type);
        end
    end

    if isempty(edges_full)
        warning('Image %d: no edge detection stage found — skipping', i);
        continue;
    end

    % ----------------------------------------------------------
    % STEP 3 — HOUGH + FILTER + FIT
    % ----------------------------------------------------------
    roi_h       = size(edges_full, 1);
    roi_w       = col_max - col_min;
    x_margin_px = round(CFG.filter.x_margin * roi_w);

    num_strips = CFG.hough.num_strips;
    if strcmp(CFG.hough.mode, 'full'), num_strips = 1; end

    strip_h     = floor(roi_h / num_strips);
    strip_lines = cell(num_strips, 1);

    for s = 1:num_strips
        y1 = (s-1) * strip_h + 1;
        y2 = min(s * strip_h, roi_h);

        strip      = edges_full(y1:y2, :);
        strip_mask = mask_crop(y1:y2, :);

        if sum(strip(strip_mask)) < 10, continue; end

        [H, T, R] = hough(strip, ...
            'Theta', linspace( ...
                CFG.hough.angle_range(1), ...
                CFG.hough.angle_range(2), 180));

        P = houghpeaks(H, CFG.hough.num_peaks, ...
            'Threshold', CFG.hough.thresh * max(H(:)), ...
            'NHoodSize', [11, 11]);

        if isempty(P), continue; end

        lines_strip = houghlines(strip, T, R, P, ...
            'FillGap',   CFG.hough.fill_gap, ...
            'MinLength', CFG.hough.min_length);

        for k = 1:length(lines_strip)
            lines_strip(k).point1(2) = lines_strip(k).point1(2) + y1 - 1;
            lines_strip(k).point2(2) = lines_strip(k).point2(2) + y1 - 1;
        end

        % Angle + margin filter
        filtered = [];
        for k = 1:length(lines_strip)
            dx  = lines_strip(k).point2(1) - lines_strip(k).point1(1);
            dy  = lines_strip(k).point2(2) - lines_strip(k).point1(2);
            ang = abs(atan2d(abs(dy), abs(dx)));
            if ang < CFG.filter.min_angle || ang > CFG.filter.max_angle
                continue;
            end
            x1c = lines_strip(k).point1(1);
            x2c = lines_strip(k).point2(1);
            if x1c < x_margin_px || x1c > (roi_w-x_margin_px), continue; end
            if x2c < x_margin_px || x2c > (roi_w-x_margin_px), continue; end
            filtered = [filtered, lines_strip(k)]; %#ok<AGROW>
        end

        if isempty(filtered), continue; end

        % Sort by length, keep best N
        lengths = arrayfun(@(l) norm(l.point2 - l.point1), filtered);
        [~, ord] = sort(lengths, 'descend');
        best = filtered(ord(1:min(CFG.fit.max_lines, end)));

        % Fit
        y_strip_fit    = linspace(row_min+y1-1, row_min+y2-1, 100)';
        strip_lines{s} = {};

        if strcmp(CFG.fit.mode, 'per_strip')
            for k = 1:length(best)
                x1f = best(k).point1(1) + col_min - 1;
                y1f = best(k).point1(2) + row_min - 1;
                x2f = best(k).point2(1) + col_min - 1;
                y2f = best(k).point2(2) + row_min - 1;
                if abs(y2f - y1f) < 1, continue; end
                p    = polyfit([y1f;y2f], [x1f;x2f], 1);
                strip_lines{s}{end+1} = [polyval(p, y_strip_fit), y_strip_fit];
            end
        else
            for k = 1:length(best)
                x1f = best(k).point1(1) + col_min - 1;
                y1f = best(k).point1(2) + row_min - 1;
                x2f = best(k).point2(1) + col_min - 1;
                y2f = best(k).point2(2) + row_min - 1;
                mx  = (x1f+x2f)/2;
                tag = 'r';
                if mx < imgW/2, tag = 'l'; end
                strip_lines{s}{end+1} = struct( ...
                    'pts', [x1f y1f; x2f y2f], 'side', tag);
            end
        end
    end

    % Global fit
    line_left = []; line_right = [];
    if strcmp(CFG.fit.mode, 'global')
        lp = []; rp = [];
        for s = 1:num_strips
            for k = 1:length(strip_lines{s})
                seg = strip_lines{s}{k};
                if strcmp(seg.side,'l'), lp = [lp; seg.pts]; %#ok<AGROW>
                else,                   rp = [rp; seg.pts]; end %#ok<AGROW>
            end
        end
        y_fit = linspace(row_min, row_max, 300)';
        if size(lp,1)>=2
            p = polyfit(lp(:,2), lp(:,1), 1);
            line_left  = [polyval(p,y_fit), y_fit];
        end
        if size(rp,1)>=2
            p = polyfit(rp(:,2), rp(:,1), 1);
            line_right = [polyval(p,y_fit), y_fit];
        end
    end

    % ----------------------------------------------------------
    % STEP 4 — PLOT
    % ----------------------------------------------------------
    figure('Name', sprintf('Image %d', i), ...
        'NumberTitle','off','Position',[50 50 1600 380]);

    subplot(1,5,1); imshow(img); title('Original','FontSize',8);

    subplot(1,5,2); imshow(gray); hold on;
    plot(polyX([1:end,1]), polyY([1:end,1]),'y-','LineWidth',1.5);
    hold off; title('ROI','FontSize',8);

    subplot(1,5,3); imshow(working);
    title(strjoin(stage_log(1:end-1),'+'),'FontSize',6,'Interpreter','none');

    subplot(1,5,4); imshow(edges_full); hold on;
    for s = 1:num_strips-1
        yline(s*strip_h,'y--','LineWidth',1);
    end
    hold off;
    title(stage_log{end},'FontSize',7,'Interpreter','none');

    subplot(1,5,5); imshow(img); hold on;
    for s = 1:num_strips-1
        plot([col_min,col_max],[row_min+s*strip_h-1, row_min+s*strip_h-1], ...
            'y--','LineWidth',1);
    end

    n_detected = 0;
    if strcmp(CFG.fit.mode,'per_strip')
        ls = {'-','--'};
        for s = 1:num_strips
            c = strip_colors{mod(s-1,length(strip_colors))+1};
            for k = 1:length(strip_lines{s})
                lfit = strip_lines{s}{k};
                if isstruct(lfit), continue; end
                plot(lfit(:,1),lfit(:,2),'Color',c, ...
                    'LineStyle',ls{min(k,2)},'LineWidth',2.5);
                n_detected = n_detected+1;
            end
        end
    else
        if ~isempty(line_left)
            plot(line_left(:,1), line_left(:,2), 'g-','LineWidth',2.5);
            n_detected = n_detected+1;
        end
        if ~isempty(line_right)
            plot(line_right(:,1),line_right(:,2),'r-','LineWidth',2.5);
            n_detected = n_detected+1;
        end
    end
    hold off;

    if labels(i)==0, col=[0 0.5 0]; else, col=[0.8 0 0]; end
    title(sprintf('Lines: %d', n_detected),'FontSize',8,'Color',col);

    [~,name,ext] = fileparts(filenames{i});
    sgtitle(sprintf('[%d] %s — %s', i,[name ext],descriptions{i}), ...
        'FontSize',11,'FontWeight','bold','Color',col);

    saveas(gcf, sprintf('%simg%02d.png', out_dir, i));
    fprintf('Image %d/%d done\n', i, N);
end

disp('Done.');