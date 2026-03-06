%% Further Work - Line Detection
img3 = imread('./Data/blobs.png');
img3_bw = edge(img3, 'Canny');

%% Hough Transform
[H, theta, rho] = hough(img3_bw);

%% Find peak
peaks = houghpeaks(H);

%% Find lines
lines = houghlines(img3_bw, theta, rho, peaks);

%% Plot
figure;
imshow(img3); hold on;
for k = 1:length(lines)
    xy = [lines(k).point1; lines(k).point2];
    plot(xy(:,1), xy(:,2), 'g-', 'LineWidth', 2);
    plot(xy(1,1), xy(1,2), 'rx', 'MarkerSize', 10, 'LineWidth', 2);
    plot(xy(2,1), xy(2,2), 'rx', 'MarkerSize', 10, 'LineWidth', 2);
end
title('Hough Lines');