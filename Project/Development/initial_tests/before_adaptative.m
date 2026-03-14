%% =========================================================================
%  Filters BEFORE Adaptive Threshold — Comparison
%  Sensitivity fixed at 0.2 (best from previous test)
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

%% --- Apply filters before adaptive ---
% Sensitivity fixed at 0.2 for all — only the pre-filter changes

% No filter — baseline
imgNoFilter = imgGray;

% Gaussian 3x3 — light smoothing
imgGauss3 = imfilter(imgGray, fspecial('gaussian', [3 3], 1), 'replicate');

% Gaussian 7x7 — stronger smoothing
imgGauss7 = imfilter(imgGray, fspecial('gaussian', [7 7], 2), 'replicate');

% Median 3x3 — removes salt & pepper, preserves edges
imgMed3 = medfilt2(imgGray, [3 3]);

% Median 7x7 — stronger median
imgMed7 = medfilt2(imgGray, [7 7]);

% CLAHE — boost local contrast before adaptive
imgCLAHE = adapthisteq(imgGray, 'ClipLimit', 0.02, 'NumTiles', [8 8]);

% Bilateral — smooths noise but keeps sharp edges (rails stay clean)
% DegreeOfSmoothing controls how much smoothing — higher = more blur
imgBilat = imbilatfilt(double(imgGray)/255, 0.1, 5);
imgBilat = uint8(imgBilat * 255);

% Wiener — adaptive noise removal based on local variance
% [5 5] = neighbourhood size for local statistics estimation
imgWiener = wiener2(imgGray, [5 5]);

%% --- Compute adaptive on each filtered image ---
S = 0.4;   % fixed sensitivity

bw_none   = imbinarize(imgNoFilter, 'adaptive', 'ForegroundPolarity', 'bright', 'Sensitivity', S) & roiMask;
bw_g3     = imbinarize(imgGauss3,   'adaptive', 'ForegroundPolarity', 'bright', 'Sensitivity', S) & roiMask;
bw_g7     = imbinarize(imgGauss7,   'adaptive', 'ForegroundPolarity', 'bright', 'Sensitivity', S) & roiMask;
bw_m3     = imbinarize(imgMed3,     'adaptive', 'ForegroundPolarity', 'bright', 'Sensitivity', S) & roiMask;
bw_m7     = imbinarize(imgMed7,     'adaptive', 'ForegroundPolarity', 'bright', 'Sensitivity', S) & roiMask;
bw_clahe  = imbinarize(imgCLAHE,    'adaptive', 'ForegroundPolarity', 'bright', 'Sensitivity', S) & roiMask;
bw_bilat  = imbinarize(imgBilat,    'adaptive', 'ForegroundPolarity', 'bright', 'Sensitivity', S) & roiMask;
bw_wiener = imbinarize(imgWiener,   'adaptive', 'ForegroundPolarity', 'bright', 'Sensitivity', S) & roiMask;

%% --- Figure: all filters before adaptive ---
figure('Name', 'Filters Before Adaptive (sensitivity=0.2)', 'NumberTitle', 'off');
set(gcf, 'Position', [50 50 1800 850]);

results = {bw_none, bw_g3, bw_g7, bw_m3, bw_m7, bw_clahe, bw_bilat, bw_wiener};
labels  = {'No filter', 'Gaussian 3x3', 'Gaussian 7x7', ...
           'Median 3x3', 'Median 7x7', 'CLAHE', ...
           'Bilateral', 'Wiener [5x5]'};

for k = 1:8
    subplot(2, 4, k);
    imshow(results{k});
    title(labels{k}, 'FontSize', 9);
end

sgtitle({'Filters BEFORE Adaptive Threshold  (sensitivity = 0.2)'; ...
    'Which pre-filter gives the cleanest rail lines?'});