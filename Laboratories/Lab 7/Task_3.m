clear, clc, close all

%% Perimeter vs Area
properties1 = ["Perimeter", "Area"];
[propsTable1, XTrain1, YTrain1, XTest1, YTest1] = lab7_buildTable(properties1);

%% Circularity vs Eccentricity
properties2 = ["Circularity", "Eccentricity"];
[propsTable2, XTrain2, YTrain2, XTest2, YTest2] = lab7_buildTable(properties2);

%% TASK 3: Build NN Model with Perimeter vs Area
% 1. Build the model
% 'LayerSizes' defines the architecture: [10] is one layer, [10 10] is two.
nnModel = fitcnet(XTrain1, YTrain1, ...
    'LayerSizes', [100 100], ... 
    'Activation', 'relu', ...
    'Standardize', true);

% 2. Predict model for testing data (XTest)
predictionsNN = predict(nnModel, XTest1);

% 3. Compute accuracy
MatchesNN = (string(YTest1) == string(predictionsNN));
accuracyNN = mean(MatchesNN);
fprintf('NN (Perimeter vs Area) Accuracy: %.2f%%\n', accuracyNN * 100);

% Plot the confusion matrix to see the 100% progress
figure;
confusionchart(YTest1, predictionsNN, 'Title', 'Confusion Matrix: Neural Network');

%% TASK 3: Build NN Model with Circularity vs Area
% 1. Build the model
% 'LayerSizes' defines the architecture: [10] is one layer, [10 10] is two.
nnModel = fitcnet(XTrain2, YTrain2, ...
    'LayerSizes', [100 100], ... 
    'Activation', 'relu', ...
    'Standardize', true);

% 2. Predict model for testing data (XTest)
predictionsNN = predict(nnModel, XTest1);

% 3. Compute accuracy
MatchesNN = (string(YTest2) == string(predictionsNN));
accuracyNN = mean(MatchesNN);
fprintf('NN (Circularity vs Eccentricity) Accuracy: %.2f%%\n', accuracyNN * 100);

% Plot the confusion matrix to see the 100% progress
figure;
confusionchart(YTest2, predictionsNN, 'Title', 'Confusion Matrix: Neural Network');

