%% Project Report: Railway Line Detection

%% 1. Line Detection
clear; clc; close all;

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

labels = [1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 1, 1, 1];

descriptions = {
    'Obstructed - rocks','Clear - straight','Clear - straight','Clear - curved','Clear - curved', ...
    'Obstructed - rocks','Clear - station','Clear - railroad crossing','Obstructed - rocks', ...
    'Clear - dark tunnel','Clear - tunnel exit','Obstructed - rocks','Obstructed - vegetation', ...
    'Obstructed - vegetation','Obstructed - rocks beside track'};

N = length(filenames);

% Load images
images = cell(N,1);
for i = 1:N
    images{i} = imread(filenames{i});
end

fprintf('\nTotal images:  %d\n', N);
fprintf('Clear:         %d\n', sum(labels == 0));
fprintf('Obstructed:    %d\n', sum(labels == 1));

%% 1.1 Grayscale Conversion
images_gray = cell(N,1);
for i = 1:N
    images_gray{i} = rgb2gray(images{i});
end

SELECTED = [1,2,11]; % Representative images
N_plot = numel(SELECTED);

figure('Name','Grayscale Images and Histograms','NumberTitle','off','Position',[100 100 1200 800]);
for k = 1:N_plot
    i = SELECTED(k);
    subplot(N_plot,2,(k-1)*2+1); imshow(images_gray{i});
    [~,name,ext] = fileparts(filenames{i});
    title([name ext],'FontSize',8,'Interpreter','none');
    
    subplot(N_plot,2,(k-1)*2+2); imhist(images_gray{i});
    xlabel('Intensity'); ylabel('Count');
end
sgtitle('Grayscale Images and Histograms','FontSize',12,'FontWeight','bold');

%% 1.2 Image Enhancement
CLAHE_TILES = [8 8]; CLAHE_CLIPLIMIT = 0.02;
images_norm = cell(N,1); images_eq = cell(N,1); images_clahe = cell(N,1);

for i = 1:N
    img = images_gray{i};
    % Normalization
    img_d = double(img);
    images_norm{i} = uint8(255*(img_d-min(img_d(:)))/(max(img_d(:))-min(img_d(:))));
    % Histogram Equalization
    images_eq{i} = histeq(img);
    % CLAHE
    images_clahe{i} = adapthisteq(img,'NumTiles',CLAHE_TILES,'ClipLimit',CLAHE_CLIPLIMIT,'Distribution','uniform');
end

% Visualization of enhancements
figure('Name','Point Processing: Images','NumberTitle','off','Position',[0 0 1600 1500]);
for row_disp = 1:length(SELECTED)
    i = SELECTED(row_disp);
    img = images_gray{i};
    [~,name,ext] = fileparts(filenames{i});
    base_title = [name ext];
    subplot(length(SELECTED),4,(row_disp-1)*4+1); imshow(img); title([base_title '\nOriginal'],'FontSize',7,'Interpreter','none');
    subplot(length(SELECTED),4,(row_disp-1)*4+2); imshow(images_norm{i}); title('Normalised','FontSize',7);
    subplot(length(SELECTED),4,(row_disp-1)*4+3); imshow(images_eq{i}); title('Equalisation','FontSize',7);
    subplot(length(SELECTED),4,(row_disp-1)*4+4); imshow(images_clahe{i}); title('CLAHE','FontSize',7);
end
sgtitle('Point Processing: Image Comparison','FontSize',12,'FontWeight','bold');

%% 1.3 Image Filtering
KERNEL_SIZE = 5; sigma = 1;
figure('Name','Spatial Filter Comparison','NumberTitle','off','Position',[0 0 2800 2400]);

for row = 1:length(SELECTED)
    i = SELECTED(row); img = images_clahe{i};
    h_avg = fspecial('average',KERNEL_SIZE);
    img_avg = imfilter(img,h_avg,'replicate');
    img_gauss = imgaussfilt(img,sigma);
    img_med = medfilt2(img,[KERNEL_SIZE KERNEL_SIZE]);
    subplot(5,4,(row-1)*4+1); imshow(img); title('CLAHE','FontSize',6);
    subplot(5,4,(row-1)*4+2); imshow(img_avg); title(sprintf('Averaging %dx%d',KERNEL_SIZE,KERNEL_SIZE),'FontSize',6);
    subplot(5,4,(row-1)*4+3); imshow(img_gauss); title('Gaussian (\sigma=1)','FontSize',6);
    subplot(5,4,(row-1)*4+4); imshow(img_med); title(sprintf('Median %dx%d',KERNEL_SIZE,KERNEL_SIZE),'FontSize',6);
end
sgtitle('Spatial Filter Comparison','FontSize',12,'FontWeight','bold');

%% 1.3.1 Gaussian Sigma Optimization
SIGMAS = [0.5,1,2,3];
figure('Name','Gaussian Sigma Comparison','NumberTitle','off','Position',[0 0 2000 1100]);

for row = 1:length(SELECTED)
    i = SELECTED(row); img = images_clahe{i};
    subplot(5,5,(row-1)*5+1); imshow(img); title('CLAHE','FontSize',6,'Interpreter','none');
    for s = 1:length(SIGMAS)
        sigma = SIGMAS(s);
        img_g = imgaussfilt(img,sigma);
        subplot(5,5,(row-1)*5+s+1); imshow(img_g); title(sprintf('\\sigma=%.1f',sigma),'FontSize',6);
    end
end
sgtitle('Gaussian \sigma Comparison (\sigma \in {0.5,1,2,3})','FontSize',12,'FontWeight','bold');

%% 1.4 Edge Enhancement (DoG & Unsharp Mask)
sigma = 1;
images_gauss = cell(N,1); images_dog = cell(N,1); images_us = cell(N,1);

for i = 1:N
    img = images_clahe{i};
    img_g = imgaussfilt(img,sigma); images_gauss{i} = img_g;
    img_g2 = imgaussfilt(img,sigma*2);
    img_dog = imsubtract(img_g2,img_g); images_dog{i} = mat2gray(img_dog);
    img_us = imsharpen(img_g,'Radius',sigma,'Amount',1); images_us{i} = img_us;
end

figure('Name','Edge Enhancement','NumberTitle','off','Position',[0 0 3*200 length(SELECTED)*200]);
for row_disp = 1:length(SELECTED)
    i = SELECTED(row_disp);
    subplot(length(SELECTED),3,(row_disp-1)*3+1); imshow(images_gauss{i}); title('Gaussian','FontSize',8);
    subplot(length(SELECTED),3,(row_disp-1)*3+2); imshow(images_dog{i}); title('DoG','FontSize',8);
    subplot(length(SELECTED),3,(row_disp-1)*3+3); imshow(images_us{i}); title('Unsharp Masking','FontSize',8);
end
sgtitle('Edge Enhancement: DoG and Unsharp Masking','FontSize',12,'FontWeight','bold');

%% 1.5 Edge Detection (Classical)
figure('Name','Edge Detection','NumberTitle','off','Position',[0 0 6*200 length(SELECTED)*200]);
for row_disp = 1:length(SELECTED)
    i = SELECTED(row_disp);
    img_g = images_gauss{i}; us = images_us{i};
    img_g_prewitt = edge(img_g,'prewitt'); img_g_sobel = edge(img_g,'sobel'); img_g_canny = edge(img_g,'canny');
    e_us_prewitt = edge(us,'prewitt'); e_us_sobel = edge(us,'sobel'); e_us_canny = edge(us,'canny');
    base = (row_disp-1)*6;
    subplot(length(SELECTED),6,base+1); imshow(img_g_prewitt); title('Gaussian Prewitt','FontSize',7);
    subplot(length(SELECTED),6,base+2); imshow(img_g_sobel); title('Gaussian Sobel','FontSize',7);
    subplot(length(SELECTED),6,base+3); imshow(img_g_canny); title('Gaussian Canny','FontSize',7);
    subplot(length(SELECTED),6,base+4); imshow(e_us_prewitt); title('Unsharp Prewitt','FontSize',7);
    subplot(length(SELECTED),6,base+5); imshow(e_us_sobel); title('Unsharp Sobel','FontSize',7);
    subplot(length(SELECTED),6,base+6); imshow(e_us_canny); title('Unsharp Canny','FontSize',7);
end
sgtitle('Edge Detection (Prewitt/Sobel/Canny) on Gaussian and Unsharp Masking','FontSize',12,'FontWeight','bold');

%% 1.5 Otsu Thresholding on DoG
images_otsu_dog = cell(N,1);
for i = 1:N
    level = graythresh(images_dog{i});
    bw = imbinarize(images_dog{i},level);
    images_otsu_dog{i} = bwareaopen(bw,50);
end

figure('Name','Otsu on DoG','NumberTitle','off','Position',[0 0 2*200 length(SELECTED)*200]);
for row_disp = 1:length(SELECTED)
    i = SELECTED(row_disp);
    subplot(length(SELECTED),2,(row_disp-1)*2+1); imshow(images_dog{i}); title('DoG','FontSize',8);
    subplot(length(SELECTED),2,(row_disp-1)*2+2); imshow(images_otsu_dog{i}); title('Otsu(DoG)','FontSize',8);
end
sgtitle('Otsu Thresholding on DoG','FontSize',12,'FontWeight','bold');

%% 1.6 ROI Application
ROI_BL_X = 0.05; ROI_BR_X = 0.95; ROI_TL_X = 0.30; ROI_TR_X = 0.70; ROI_TOP_Y = 0.4;
images_otsu_dog_roi = cell(N,1);

for i = 1:N
    bw = images_otsu_dog{i};
    [h,w] = size(bw);
    roi_x = [ROI_BL_X*w, ROI_BR_X*w, ROI_TR_X*w, ROI_TL_X*w];
    roi_y = [h,h,ROI_TOP_Y*h,ROI_TOP_Y*h];
    mask = poly2mask(roi_x,roi_y,h,w);
    images_otsu_dog_roi{i} = bw .* mask;
end

% 3x2 Grid: Original RGB and Otsu(DoG) with ROI
figure('Name','Original and Otsu(DoG) with ROI','NumberTitle','off','Position',[0 0 800 600]);

for k = 1:length(SELECTED)
    i = SELECTED(k);  % selected image index
    rgb_img = images{i};        % original RGB
    bw_roi  = images_otsu_dog_roi{i};  % Otsu(DoG) with ROI

    [h,w] = size(bw_roi);
    roi_x = [ROI_BL_X*w, ROI_BR_X*w, ROI_TR_X*w, ROI_TL_X*w];
    roi_y = [h,h,ROI_TOP_Y*h,ROI_TOP_Y*h];

    % Original RGB with ROI
    subplot(length(SELECTED),2,(k-1)*2 + 1);
    imshow(rgb_img);
    hold on;
    plot([roi_x roi_x(1)], [roi_y roi_y(1)], 'r-', 'LineWidth', 1.5);
    hold off;
    title(sprintf('Original RGB with ROI [%d]', i),'FontSize',10);

    % Otsu(DoG) with ROI overlay
    subplot(length(SELECTED),2,(k-1)*2 + 2);
    imshow(bw_roi);
    hold on;
    plot([roi_x roi_x(1)], [roi_y roi_y(1)], 'r-', 'LineWidth', 1.5);
    hold off;
    title(sprintf('Otsu(DoG) with ROI [%d]', i),'FontSize',10);
end

sgtitle('Comparison: Original RGB vs Otsu(DoG) with ROI','FontSize',12,'FontWeight','bold');

min_pixels = 100;          % bwareaopen threshold
strel_radius = 3;          % imopen/imclose radius
se = strel('disk', strel_radius);

figure('Name','Morphological Operations on Otsu(DoG)','NumberTitle','off', ...
       'Position',[0 0 1800 900]);

for row = 1:length(SELECTED)
    i = SELECTED(row);

    % Original Otsu(DoG)
    bw = images_otsu_dog{i};

    % Morphological operations (no ROI overlay)
    bw_bwarea = bwareaopen(bw, min_pixels);
    bw_open   = imopen(bw, se);
    bw_close  = imclose(bw, se);

    % 1. Original Otsu(DoG)
    subplot(length(SELECTED),4,(row-1)*4 + 1);
    imshow(bw);
    title(sprintf('Original Otsu(DoG) [%d]', i),'FontSize',10);

    % 2. bwareaopen
    subplot(length(SELECTED),4,(row-1)*4 + 2);
    imshow(bw_bwarea);
    title('bwareaopen','FontSize',10);

    % 3. imopen
    subplot(length(SELECTED),4,(row-1)*4 + 3);
    imshow(bw_open);
    title('imopen','FontSize',10);

    % 4. imclose
    subplot(length(SELECTED),4,(row-1)*4 + 4);
    imshow(bw_close);
    title('imclose','FontSize',10);
end

sgtitle('Morphological Operations on Selected Otsu(DoG)','FontSize',12,'FontWeight','bold');