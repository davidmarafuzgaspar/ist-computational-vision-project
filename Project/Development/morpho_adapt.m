%% =========================================================================
%  Morphological Operations AFTER Adaptive Threshold
%  Sensitivity = 0.2, No pre-filter (baseline)
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

%% --- ROI ---
bottomLeft  = [round(0.10*imgW),  imgH            ];
bottomRight = [round(0.90*imgW),  imgH            ];
topLeft     = [round(0.35*imgW),  round(0.40*imgH)];
topRight    = [round(0.65*imgW),  round(0.40*imgH)];
polyX   = [bottomLeft(1), topLeft(1),  topRight(1),  bottomRight(1)];
polyY   = [bottomLeft(2), topLeft(2),  topRight(2),  bottomRight(2)];
roiMask = poly2mask(polyX, polyY, imgH, imgW);

%% --- Adaptive baseline (sensitivity=0.2) ---
bw_base = imbinarize(imgGray, 'adaptive', ...
    'ForegroundPolarity', 'bright', 'Sensitivity', 0.3) & roiMask;

%% --- Morphological operations after adaptive ---

% Erosion disk 1 — gentle shrink, removes thinnest noise pixels
bw_erode1 = imerode(bw_base, strel('disk', 1));

% Erosion disk 2 — stronger, removes more noise but may thin rails
bw_erode2 = imerode(bw_base, strel('disk', 2));

% Erosion disk 3 — aggressive, only thick structures survive
bw_erode3 = imerode(bw_base, strel('disk', 3));

% Opening disk 2 — erosion THEN dilation: removes noise, restores rail thickness
% Better than erosion alone because it gives back the size of surviving structures
bw_open2 = imopen(bw_base, strel('disk', 2));

% Opening disk 3
bw_open3 = imopen(bw_base, strel('disk', 3));

% Erosion disk 2 + Dilation disk 1 — asymmetric: erode more than dilate
% Removes noise aggressively but keeps rails slightly thicker than pure erosion
bw_erode2_dilate1 = imdilate(imerode(bw_base, strel('disk', 2)), strel('disk', 1));

% bwareaopen — removes any connected blob smaller than N pixels
% Does not affect shape of remaining blobs (unlike erosion)
bw_area500  = bwareaopen(bw_base, 500);   % remove blobs < 500 px
bw_area1000 = bwareaopen(bw_base, 1000);  % more aggressive

%% --- Figure ---
figure('Name', 'Morphology After Adaptive (sensitivity=0.2)', 'NumberTitle', 'off');
set(gcf, 'Position', [50 50 1800 850]);

subplot(2, 4, 1);
imshow(bw_base);
title('Adaptive only (baseline)', 'FontSize', 9);

subplot(2, 4, 2);
imshow(bw_erode1);
title('+ Erosion disk 1', 'FontSize', 9);

subplot(2, 4, 3);
imshow(bw_erode2);
title('+ Erosion disk 2', 'FontSize', 9);

subplot(2, 4, 4);
imshow(bw_erode3);
title('+ Erosion disk 3', 'FontSize', 9);

subplot(2, 4, 5);
imshow(bw_open2);
title('+ Opening disk 2', 'FontSize', 9);

subplot(2, 4, 6);
imshow(bw_open3);
title('+ Opening disk 3', 'FontSize', 9);

subplot(2, 4, 7);
imshow(bw_area500);
title('+ bwareaopen 500px', 'FontSize', 9);

subplot(2, 4, 8);
imshow(bw_area1000);
title('+ bwareaopen 1000px', 'FontSize', 9);

sgtitle({'Morphological Operations AFTER Adaptive Threshold  (sensitivity = 0.2)'; ...
    'Which operation best cleans noise while keeping rail lines?'});