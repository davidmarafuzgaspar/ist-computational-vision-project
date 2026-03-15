%% =========================================================================
%  All images with ROI trapezoid drawn
% =========================================================================

%% --- Load all images ---
datasetPath = '../Data/Dataset - B2/';
imgFiles = dir(fullfile(datasetPath, '*.jpg'));
if isempty(imgFiles)
    imgFiles = dir(fullfile(datasetPath, '*.png'));
end
numImages = length(imgFiles);

%% --- Display grid ---
cols = 4;
rows = ceil(numImages / cols);

figure('Name', 'ROI on All Images', 'NumberTitle', 'off');
set(gcf, 'Position', [50 50 1600 900]);

for i = 1:numImages

    imgRGB = imread(fullfile(imgFiles(i).folder, imgFiles(i).name));
    [imgH, imgW, ~] = size(imgRGB);

    % ROI trapezoid
    bottomLeft  = [round(0.05*imgW),  imgH              ];
    bottomRight = [round(0.95*imgW),  imgH              ];
    topLeft     = [round(0.30*imgW),  round(0.25*imgH)  ];
    topRight    = [round(0.70*imgW),  round(0.25*imgH)  ];
    polyX = [bottomLeft(1), topLeft(1), topRight(1), bottomRight(1)];
    polyY = [bottomLeft(2), topLeft(2), topRight(2), bottomRight(2)];

    subplot(rows, cols, i);
    imshow(imgRGB); hold on;
    plot([polyX, polyX(1)], [polyY, polyY(1)], 'y-', 'LineWidth', 2);
    plot(polyX, polyY, 'ro', 'MarkerSize', 6, 'LineWidth', 2);
    title(sprintf('%d: %s', i, imgFiles(i).name), ...
        'Interpreter', 'none', 'FontSize', 7);
    hold off;
end

sgtitle('ROI Trapezoid — All Dataset Images');