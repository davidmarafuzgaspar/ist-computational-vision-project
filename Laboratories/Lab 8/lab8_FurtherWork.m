clear, clc, close all

%% 1) Create datastore and define training and testing sets
% Path
datastore = imageDatastore('images', ...
    'IncludeSubfolders',true,'LabelSource','foldernames');

% Show sample images of each class
% figure;
perm = randperm(100,12);
for i = 1:12
    subplot(3,4,i);
    imshow(datastore.Files{perm(i)});
end

% Split datastore in training and testing datasets
dataTrain = 0.8;
dataTest = 0.2;
[dataTrain, dataTest] = splitEachLabel(datastore, dataTrain, dataTest, 'randomize');

% Perform transformations on original datastore and combine them
dataTrainGS = transform(dataTrain,@(x) im2gray(x));
dataTrainGS = dataTrainGS.UnderlyingDatastores{1,1};
dataTrainAll = dataTrain;
Labels = [dataTrain.Labels; dataTrainGS.Labels];
Files = [dataTrain.Files; dataTrainGS.Files];
dataTrainAll.Files = Files;
dataTrainAll.Labels = Labels;


%% 2) Deep Learning Neural Network
% Network Architecture
layers=[
    imageInputLayer([240 320 3])
    
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
    
    fullyConnectedLayer(3)
    softmaxLayer
    classificationLayer];


%% 3) Training options
% Define the training options for your network
% options =


%% Net training, classification of test data and result analysis
% Train net
% net = 
% 
% % Classification
% YPred = 
% 
% % Labels to compare
% YTest = dataTest.Labels;
% 
% % Accuracy
% accuracy = 
% fprintf('Testing accuracy: %.1f%% \n', accuracy)
% 
% % Confusion matrix
% 
% title(['Testing accuracy: ', num2str(accuracy),'%'])
% 
% % Random check of images
% perm = randperm(2000,12);
% figure
% for i = 1:12
%     num = perm(i);
%     subplot(3,4,i);
%     imshow(dataTest.Files{num});
%     title(append('Predicted label: ', string(YPred(num))))
% end