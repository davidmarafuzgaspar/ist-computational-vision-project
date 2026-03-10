%% =========================================================================
%  Adaptive Threshold — Sensitivity Comparison
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

%% --- Sensitivity comparison ---
% Top row    → adaptive only
% Bottom row → adaptive + imopen (removes small noise blobs)
sensValues = [0.1, 0.2, 0.3, 0.4, 0.5];

figure('Name', 'Adaptive Sensitivity Comparison', 'NumberTitle', 'off');
set(gcf, 'Position', [100 100 1600 600]);

for k = 1:length(sensValues)
    s = sensValues(k);

    bw_s       = imbinarize(imgGray, 'adaptive', ...
        'ForegroundPolarity', 'bright', 'Sensitivity', s) & roiMask;
    bw_s_clean = imopen(bw_s, strel('disk', 2));

    subplot(2, 5, k);
    imshow(bw_s);
    title(sprintf('Sensitivity = %.1f', s), 'FontSize', 9);

    subplot(2, 5, k+5);
    imshow(bw_s_clean);
    title(sprintf('+ imopen  s=%.1f', s), 'FontSize', 9);
end

sgtitle({'Adaptive Threshold — Sensitivity Comparison'; ...
    'Top: raw adaptive    Bottom: after imopen cleanup'});