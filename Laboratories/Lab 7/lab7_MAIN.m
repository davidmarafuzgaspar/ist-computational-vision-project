clear, clc, close all
%% Visualize Features
% Choose properties to visualize
properties = ["Perimeter", "Area"];
[propsTable, XTrain, YTrain, XTest, YTest] = lab7_buildTable(properties);


%% TASK 1: Build KNN Model
% Build model from training data (XTrain, YTrain)


% Predict model for testing data (XTest)
predictionsKNN = zeros(size(YTest)); %% CHANGE THIS!!!

% Compute accuracy
MatchesKNN = (string(YTest) == string(predictionsKNN));
fprintf('Prediction results: %s\n', num2str(MatchesKNN'))

% Obtain the confusion matrix

return
%% TASK 2: Feature Influence in Classification Results
% Properties to visualize
prop1 = 1;  % Number of property 1
prop2 = 2;  % Number of property 2
subplot(2,2,2), gscatter(propsTable.(properties(prop1)), propsTable.(properties(prop2)),propsTable.Class)
xlabel(properties(prop1)), ylabel(properties(prop2))


%% TASK 3: Build NN Model
% Build model from training data (XTrain, YTrain)


% Predict model for testing data (XTest)
predictionsNN = zeros(size(YTest)); %% CHANGE THIS!!!

% Compute accuracy
MatchesNN = (string(YTest) == string(predictionsNN));
fprintf('Prediction results: %s\n', num2str(MatchesNN'))


% Obtain the confusion matrix


