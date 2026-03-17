clear, clc, close all

% List of all possible region properties to test
allProperties = ["Area", "Perimeter", "Eccentricity", "Solidity", "Extent", "EulerNumber", "EquivDiameter"];

foundPerfect = false;

for i = 1:length(allProperties)
    currentProp = allProperties(i);
    
    % Build table for the SINGLE property
    [propsTable, XTrain, YTrain, XTest, YTest] = lab7_buildTable(currentProp);
    
    % Build and Predict
    knnModel = fitcknn(XTrain, YTrain, 'NumNeighbors', 3);
    predictionsKNN = predict(knnModel, XTest);
    
    % Calculate Accuracy
    accuracy = sum(strcmp(predictionsKNN, YTest)) / numel(YTest);
    fprintf('Testing %s: Accuracy = %.2f%%\n', currentProp, accuracy * 100);
    
    % Check for 100% accuracy
    if accuracy == 1.0
        fprintf('\n>>> Found it! "%s" gives 100%% accuracy.\n', currentProp);
        
        % Visualize the winning feature
        figure;
        confusionchart(YTest, predictionsKNN, 'Title', ['Perfect Match: ', char(currentProp)]);
        
        foundPerfect = true;
        break; % Stop looking once we find one
    end
end

if ~foundPerfect
    fprintf('\nNo single property provided 100%% accuracy.\n');
end