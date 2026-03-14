%% Task 2 - Online Classification (initialization)
clear, clc, clf, close all
restoredefaultpath
addpath(cd, './Data/datasetImages');

% Calls function for computing the Hu Moments descriptors
lab6_HuMomentDescriptors(0);

% Calls function for computing the keypoint descriptors
[~, ~, ~, featuresRho, featuresSqu, featuresTri] = lab5_buildDescriptors;

return