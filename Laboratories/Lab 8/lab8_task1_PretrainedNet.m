clear, clc, close all
%% TASK 1: Pre-Trained Network
%% 1.a) Load and analyze network
% Load GoogLeNet
net = googlenet;

% Load the layers
layers = net.Layers;

% Input size (image dimensions) -> "InputSize" property of first layer
inputSize = net.Layers(1).InputSize;

% Output size (number of possible classifications) -> "Classes" property of the last layer% Output size = number of possible classifications
outputClasses = net.Layers(end).Classes;

%% 1.b) Load and classify an image
% Load image
image = imread("./Data/computer.jpg");

targetHeight = inputSize(1,1);
targetWidth = inputSize(1,2);

% Resize image
image_resized = imresize(image, [targetHeight targetWidth]);

% Prediction
[pred, scores] = classify(net, image_resized);

% Show the image
imshow(image), title(append('Best class is: ', string(pred)))


%% 1.c) Analyze results
% Define minimum score to analyze and create logical array
threshold = 0.01;
highscores = scores > threshold;

% Extract best classes and correspondent scores
bestClasses = outputClasses(highscores);
bestScores = scores(highscores);

% Bar chart
figure, bar(bestScores)
xticklabels(bestClasses)