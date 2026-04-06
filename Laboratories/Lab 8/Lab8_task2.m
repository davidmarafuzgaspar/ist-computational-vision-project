% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Instituto Superior Tecnico
% Computational Vision - Lab 8 - Task 2
%
% Authors:
% David Marafuz Gaspar - 106541
% Pedro Gaspar Mónico - 106626
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

% Create datastore
datastore=imageDatastore('./Data/DigitDataset', ...
    'IncludeSubfolders',true,'LabelSource','foldernames');

% Show sample images of each class
figure;
perm = randperm(10000,12);
for i = 1:12
    subplot(3,4,i);
    imshow(datastore.Files{perm(i)});
end

% Split datastore in training and testing datasets
dataTrain = 0.8;
dataTest = 0.2;
[dataTrain, dataTest] = splitEachLabel(datastore, dataTrain, dataTest, 'randomize');

% Network Architecture
layers = [
            imageInputLayer([28 28 1])

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

            fullyConnectedLayer(10)
            softmaxLayer
            classificationLayer];


% Define the training options for your network
options = trainingOptions("adam", ...
    "InitialLearnRate", 0.0001, ...
    "MaxEpochs", 100, ...
    "Verbose", true, ...
    "Plots", "training-progress");


% Train net
net = trainNetwork(dataTrain, layers, options);

% Classification
YPred = classify(net, dataTest);

% Labels to compare
YTest = dataTest.Labels;
 
% Accuracy
accuracy = sum(YPred == YTest) / numel(YTest) * 100;
fprintf('Testing accuracy: %.1f%% \n', accuracy)

% Confusion matrix
title(['Testing accuracy: ', num2str(accuracy),'%'])

% Random check of images
perm = randperm(2000,12);
figure
for i = 1:12
     num = perm(i);
     subplot(3,4,i);
     imshow(dataTest.Files{num});
     title(append('Predicted label: ', string(YPred(num))))
end

%% Confusion matrix
figure;
cm = confusionchart(YTest, YPred);
cm.Title = 'Confusion Matrix';
cm.RowSummary = 'row-normalized';
cm.ColumnSummary = 'column-normalized';

