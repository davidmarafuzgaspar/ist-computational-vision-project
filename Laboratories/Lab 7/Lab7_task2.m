% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Instituto Superior Tecnico
% Computational Vision - Lab 7 - Task 2
%
% Authors:
% David Marafuz Gaspar - 106541
% Pedro Gaspar Mónico - 106626
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

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

