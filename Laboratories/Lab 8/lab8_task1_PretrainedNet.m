clear, clc, close all
%% TASK 1: Pre-Trained Network
%% 1.a) Load and analyze network
% Load GoogLeNet
net = googlenet;

% Input size (image dimensions) -> "InputSize" property of first layer
inputSize = 

% Output size (number of possible classifications) -> "Classes" property of the last layer% Output size = number of possible classifications
outputClasses =


%% 1.b) Load and classify an image
% Load image


% Resize image


% Prediction
[pred, scores] = 

imshow(img), title(append('Best class is: ', string(predictions)))


%% 1.c) Analyze results
% Define minimum score to analyze and create logical array
threshold =
highscores =

% Extract best classes and correspondent scores
bestClasses = outputClasses(highscores);
bestScores = scores(highscores);

% Bar chart
figure, bar(bestScores)
xticklabels(bestClasses)