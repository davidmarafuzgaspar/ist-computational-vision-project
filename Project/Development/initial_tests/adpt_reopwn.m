%% =========================================================================
%  Adaptive (s=0.3) + bwareaopen(500) — All images in dataset
% =========================================================================

%% --- Load all images ---
datasetPath = '../Data/Dataset - B2/';
imgFiles = dir(fullfile(datasetPath, '*.jpg'));
if isempty(imgFiles)
    imgFiles = dir(fullfile(datasetPath, '*.png'));
end
numImages = length(imgFiles);
fprintf('Total images: %d\n', numImages);

%% --- ROI parameters (same for all images) ---
% These fractions are applied to each image's own size
roiBot  = [0.10, 0.90];   % bottom left/right x fractions
roiTop  = [0.35, 0.65];   % top left/right x fractions
roiTopY = 0.40;            % how high the ROI reaches (fraction of height)

%% --- Display grid ---
cols = 4;
rows = ceil(numImages / cols);

figure('Name', 'Adaptive 0.3 + bwareaopen 500 — All Images', 'NumberTitle', 'off');
set(gcf, 'Position', [50 50 1600 900]);

for i = 1:numImages

    % Load
    imgPath = fullfile(imgFiles(i).folder, imgFiles(i).name);
    imgRGB  = imread(imgPath);
    if size(imgRGB, 3) == 3
        imgGray = rgb2gray(imgRGB);
    else
        imgGray = imgRGB;
    end
    [imgH, imgW] = size(imgGray);

    % ROI for this image
    bottomLeft  = [round(roiBot(1)*imgW),  imgH              ];
    bottomRight = [round(roiBot(2)*imgW),  imgH              ];
    topLeft     = [round(roiTop(1)*imgW),  round(roiTopY*imgH)];
    topRight    = [round(roiTop(2)*imgW),  round(roiTopY*imgH)];
    polyX   = [bottomLeft(1), topLeft(1), topRight(1), bottomRight(1)];
    polyY   = [bottomLeft(2), topLeft(2), topRight(2), bottomRight(2)];
    roiMask = poly2mask(polyX, polyY, imgH, imgW);

    % Pipeline: Adaptive s=0.3 → bwareaopen 500
    bw = imbinarize(imgGray, 'adaptive', ...
        'ForegroundPolarity', 'bright', 'Sensitivity', 0.3) & roiMask;
    bw = bwareaopen(bw, 500);

    % Plot
    subplot(rows, cols, i);
    imshow(bw);
    title(sprintf('%d: %s', i, imgFiles(i).name), ...
        'Interpreter', 'none', 'FontSize', 7);
end

sgtitle('Adaptive (s=0.3) + bwareaopen(500) — All Dataset Images');