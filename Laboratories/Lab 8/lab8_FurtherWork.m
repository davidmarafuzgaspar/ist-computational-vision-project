clear; clc; close all

%% 1) Create datastore and define training and testing sets
% Path
datastore = imageDatastore('./Data/images', ...
'IncludeSubfolders', true, ...
'LabelSource', 'foldernames');

% Show sample images
figure;
perm = randperm(numel(datastore.Files), min(12,numel(datastore.Files)));
for i = 1:numel(perm)
subplot(3,4,i);
imshow(datastore.Files{perm(i)});
title(string(datastore.Labels(perm(i))));
end

% Split datastore into training and testing datasets
[ dataTrain, dataTest ] = splitEachLabel(datastore, 0.8, 0.2, 'randomize');

%% 2) Data preprocessing (resize + augmentation)
inputSize = [240 320 3];

% Data augmentation (helps due to small dataset)
imageAugmenter = imageDataAugmenter( ...
'RandRotation', [-20 20], ...
'RandXReflection', true);

augTrain = augmentedImageDatastore(inputSize, dataTrain, ...
'DataAugmentation', imageAugmenter);

augTest = augmentedImageDatastore(inputSize, dataTest);

%% 3) Deep Learning Neural Network
layers = [
    imageInputLayer(inputSize)
    convolution2dLayer(3,8,'Padding','same')
    batchNormalizationLayer
    reluLayer
    maxPooling2dLayer(2,'Stride',2)
    convolution2dLayer(3,16,'Padding','same')
    batchNormalizationLayer
    reluLayer
    maxPooling2dLayer(2,'Stride',2)
    convolution2dLayer(3,32,'Padding','same')
    batchNormalizationLayer
    reluLayer
    fullyConnectedLayer(3) % 3 shape classes
    softmaxLayer
    classificationLayer];


%% 4) Training options
options = trainingOptions("adam", ...
"InitialLearnRate", 1e-3, ...
"MaxEpochs", 30, ...
"MiniBatchSize", 8, ...
"Shuffle", "every-epoch", ...
"Verbose", true, ...
"Plots", "training-progress");

%% 5) Train network
net = trainNetwork(augTrain, layers, options);

%% 6) Classification
YPred = classify(net, augTest);
YTest = dataTest.Labels;

%% 7) Accuracy
accuracy = sum(YPred == YTest) / numel(YTest) * 100;
fprintf('Testing accuracy: %.1f%% \n', accuracy)

%% 8) Confusion matrix
figure;
cm = confusionchart(YTest, YPred);
cm.Title = ['Confusion Matrix (Accuracy: ', num2str(accuracy), '%)'];
cm.RowSummary = 'row-normalized';
cm.ColumnSummary = 'column-normalized';

%% 9) Random check of predictions
perm = randperm(numel(dataTest.Files), min(12,numel(dataTest.Files)));
figure;
for i = 1:numel(perm)
num = perm(i);
subplot(3,4,i);
imshow(dataTest.Files{num});
title(['Predicted: ', string(YPred(num))]);
end
