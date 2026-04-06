% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Instituto Superior Tecnico
% Computational Vision - Lab 7 - Task 1
%
% Authors:
% David Marafuz Gaspar - 106541
% Pedro Gaspar Mónico - 106626
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

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