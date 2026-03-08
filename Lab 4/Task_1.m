% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Instituto Superior Tecnico
% Computational Vision - Lab 4
%
% Authors:
% David Marafuz Gaspar - 106541
% Pedro Gaspar Mónico - 106626
%
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%% Task 1
img = imread('tire.tif');

%% Sharpened versions
sharp_imsharpen = imsharpen(img, 'Radius', 2, 'Amount', 1.5);
sharp_laplacian = imfilter(img, fspecial('laplacian', 0.5));
sharp_log       = imfilter(img, fspecial('log', 15, 2));
sharp_unsharp   = imfilter(img, fspecial('unsharp', 0.5));

%% Canny edge detection
edges_original  = edge(img,'Canny');
edges_imsharpen = edge(sharp_imsharpen,'Canny');
edges_laplacian = edge(sharp_laplacian,'Canny');
edges_log       = edge(sharp_log,'Canny');
edges_unsharp   = edge(sharp_unsharp,'Canny');

%% Plot
figure('Name', 'Filter Comparison', 'Units','normalized','Position',[0 0 1 1]);

subplot(2,5,1);  imshow(img);             title('Original');
subplot(2,5,2);  imshow(sharp_imsharpen); title('imsharpen');
subplot(2,5,3);  imshow(sharp_laplacian); title('Laplacian');
subplot(2,5,4);  imshow(sharp_log);       title('LoG');
subplot(2,5,5);  imshow(sharp_unsharp);   title('Unsharp');

subplot(2,5,6);  imshow(edges_original);  title('Canny - Original');
subplot(2,5,7);  imshow(edges_imsharpen); title('Canny - imsharpen');
subplot(2,5,8);  imshow(edges_laplacian); title('Canny - Laplacian');
subplot(2,5,9);  imshow(edges_log);       title('Canny - LoG');
subplot(2,5,10); imshow(edges_unsharp);   title('Canny - Unsharp');

sgtitle('Sharpening Filters + Canny Edge Detection');