%% =========================================================================
%  PART 1 — Binarization WITH ROI
%  Apply trapezoid ROI first, then compare binarization methods
% =========================================================================

%% --- Load image ---
datasetPath = './Data/Dataset - B2/';
imgFiles = dir(fullfile(datasetPath, '*.jpg'));
if isempty(imgFiles)
    imgFiles = dir(fullfile(datasetPath, '*.png'));
end

imgRGB  = imread(fullfile(imgFiles(1).folder, imgFiles(1).name));
if size(imgRGB,3) == 3
    imgGray = rgb2gray(imgRGB);
else
    imgGray = imgRGB;
end
[imgH, imgW] = size(imgGray);
fprintf('Image: %s  (%d x %d)\n', imgFiles(1).name, imgH, imgW);

%% --- Define ROI trapezoid ---
% Wide at bottom (full track near train), narrow at top (horizon).
% TUNE THESE 4 values if the trapezoid cuts too much or too little:
%   bottomLeft/Right : how far in from sides at the bottom (0.05/0.95 = nearly full width)
%   topLeft/Right    : where rails converge at horizon (0.38/0.62 = 24% of width centred)
%   0.50*imgH        : how high the ROI reaches (0=top of image, 1=bottom)
%                      raise to 0.55-0.60 if rocks/sky still appear inside

bottomLeft  = [round(0.10*imgW),  imgH            ];
bottomRight = [round(0.90*imgW),  imgH            ];
topLeft     = [round(0.35*imgW),  round(0.40*imgH)];
topRight    = [round(0.65*imgW),  round(0.40*imgH)];

polyX   = [bottomLeft(1), topLeft(1),  topRight(1),  bottomRight(1)];
polyY   = [bottomLeft(2), topLeft(2),  topRight(2),  bottomRight(2)];

% Create binary mask — white inside trapezoid, black outside
roiMask = poly2mask(polyX, polyY, imgH, imgW);

% Apply mask to greyscale image
imgROI = uint8(double(imgGray) .* double(roiMask));

%% --- Show ROI boundary on original image ---
figure('Name', 'ROI Preview', 'NumberTitle', 'off');
imshow(imgRGB); hold on;
% Draw the trapezoid outline in yellow
plot([polyX, polyX(1)], [polyY, polyY(1)], 'y-', 'LineWidth', 3);
% Mark the 4 corner points
plot(polyX, polyY, 'ro', 'MarkerSize', 8, 'LineWidth', 2);
title({'ROI Trapezoid — yellow = search area'; ...
       'Adjust fractions in code if rocks/sky are still inside'}, 'FontSize', 10);
hold off;

%% --- Binarization methods applied to ROI image ---

% 1A: Raw Otsu on ROI
% Only pixels inside the trapezoid contribute to Otsu's histogram.
% This gives a much better threshold since rocks/sky are excluded.
thresh_raw = graythresh(imgROI(roiMask));   % compute threshold on ROI pixels only
bw_raw     = imbinarize(imgROI, thresh_raw);
bw_raw     = bw_raw & roiMask;             % keep only inside ROI

% 1B: Gaussian + Otsu on ROI
gaussFilt    = fspecial('gaussian', [5 5], 1);
imgGauss     = imfilter(imgROI, gaussFilt, 'replicate');
thresh_gauss = graythresh(imgGauss(roiMask));
bw_gauss     = imbinarize(imgGauss, thresh_gauss) & roiMask;

% 1C: Median + Otsu on ROI
imgMedian  = medfilt2(imgROI, [5 5]);
thresh_med = graythresh(imgMedian(roiMask));
bw_median  = imbinarize(imgMedian, thresh_med) & roiMask;

% 1D: CLAHE + Otsu on ROI
% Note: adapthisteq works on the full image but ROI zeros don't affect rails
imgCLAHE  = adapthisteq(imgGray, 'ClipLimit', 0.02, 'NumTiles', [8 8]);
imgCLAHE_roi = uint8(double(imgCLAHE) .* double(roiMask));
thresh_cl = graythresh(imgCLAHE_roi(roiMask));
bw_clahe  = imbinarize(imgCLAHE_roi, thresh_cl) & roiMask;

% 1E: Adaptive threshold on ROI
% Local neighbourhood threshold — best for uneven lighting
bw_adaptive = imbinarize(imgGray, 'adaptive', ...
    'ForegroundPolarity', 'bright', ...
    'Sensitivity', 0.4);
bw_adaptive = bw_adaptive & roiMask;   % mask out everything outside ROI

%% --- Display comparison ---
figure('Name', 'Part 1: Binarization WITH ROI', 'NumberTitle', 'off');

subplot(2,3,1);
imshow(imgROI);
title('Greyscale + ROI applied', 'FontSize', 9);

subplot(2,3,2);
imshow(bw_raw);
title(sprintf('RAW Otsu  thresh=%.2f', thresh_raw), 'FontSize', 9);

subplot(2,3,3);
imshow(bw_gauss);
title(sprintf('Gaussian [5x5] + Otsu  thresh=%.2f', thresh_gauss), 'FontSize', 9);

subplot(2,3,4);
imshow(bw_median);
title(sprintf('Median [5x5] + Otsu  thresh=%.2f', thresh_med), 'FontSize', 9);

subplot(2,3,5);
imshow(bw_clahe);
title(sprintf('CLAHE + Otsu  thresh=%.2f', thresh_cl), 'FontSize', 9);

subplot(2,3,6);
imshow(bw_adaptive);
title('Adaptive threshold', 'FontSize', 9);

sgtitle(sprintf('Part 1: Binarization WITH ROI — %s', imgFiles(1).name), ...
    'Interpreter', 'none');