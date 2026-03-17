clear, clc, close all

%% TASK 1: Perimeter vs Area
properties1 = ["Perimeter", "Area"];
[propsTable1, XTrain1, YTrain1, XTest1, YTest1] = lab7_buildTable(properties1);

% Build and Predict
knnModel1 = fitcknn(XTrain1, YTrain1, 'NumNeighbors', 3);
predictionsKNN1 = predict(knnModel1, XTest1);

% Plot Confusion Matrix
figure(1); 
confusionchart(YTest1, predictionsKNN1, 'Title', 'Confusion Matrix: Perimeter vs Area');

% Visualize Feature Influence
figure(2);
gscatter(propsTable1.(properties1(1)), propsTable1.(properties1(2)), propsTable1.Class)
xlabel(properties1(1)), ylabel(properties1(2))
title('Feature Space: Perimeter vs Area')

%% Task 2: Circularity vs Eccentricity
properties2 = ["Circularity", "Eccentricity"];
[propsTable2, XTrain2, YTrain2, XTest2, YTest2] = lab7_buildTable(properties2);

% Build and Predict
knnModel2 = fitcknn(XTrain2, YTrain2, 'NumNeighbors', 3);
predictionsKNN2 = predict(knnModel2, XTest2);

% Plot Confusion Matrix
figure(3); 
confusionchart(YTest2, predictionsKNN2, 'Title', 'Confusion Matrix: Circularity vs Area');

% Visualize Feature Influence
figure(4);
gscatter(propsTable2.(properties2(1)), propsTable2.(properties2(2)), propsTable2.Class)
xlabel(properties2(1)), ylabel(properties2(2))
title('Feature Space: Circularity vs Area')

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

