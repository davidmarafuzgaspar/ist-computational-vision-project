%% =========================================================
%  People & Vehicle Detection - Thermal Imagery
%  Topic A3 | Computation Vision - Project 2
%  Full Pipeline: Data Analysis + Storage + Transfer Learning
%  Authors: David Marafuz Gaspar (106541)
%           Pedro Gaspar Monico (106626)
%% =========================================================

%% ---- 1. Define Dataset Paths and Splits -----------------

datasetPaths = {
    '../../Data/images_thermal_train', ...
    '../../Data/images_thermal_val',   ...
    '../../Data/video_thermal_test'
};
splitNames = {'Train', 'Validation', 'Test'};

%% ---- 2. Read Categories from the Training Dataset -------

cocoPath = fullfile(datasetPaths{1}, 'coco.json');
cocoData = jsondecode(fileread(cocoPath));

numCategoriesAll = length(cocoData.categories);
classNames_coco  = strings(1, numCategoriesAll);
classIDs         = zeros(1,  numCategoriesAll);

for i = 1:numCategoriesAll
    classNames_coco(i) = cocoData.categories(i).name;
    classIDs(i)        = cocoData.categories(i).id;
end

lowerClassNames = lower(classNames_coco);

%% ---- 3. Define Target Classes ---------------------------

targetClass1 = "person";
targetClass2 = ["car", "motorcycle", "bus", "train", "truck", "other vehicle"];

class1_IDs = classIDs(lowerClassNames == targetClass1);
class2_IDs = classIDs(ismember(lowerClassNames, targetClass2));

%% ---- 4. Dataset Distribution Analysis -------------------

numImagesPerSplit  = zeros(1, length(datasetPaths));
countsPerSplit     = zeros(numCategoriesAll, length(datasetPaths));
filenames_train    = [];
peopleBoxes_train  = [];
vehicleBoxes_train = [];

for d = 1:length(datasetPaths)
    cocoPath = fullfile(datasetPaths{d}, 'coco.json');
    cocoData = jsondecode(fileread(cocoPath));

    numImgsD             = length(cocoData.images);
    numImagesPerSplit(d) = numImgsD;

    if d == 1
        filenames_train    = cell(numImgsD, 1);
        peopleBoxes_train  = cell(numImgsD, 1);
        vehicleBoxes_train = cell(numImgsD, 1);
        imageIDList        = zeros(numImgsD, 1);
        for k = 1:numImgsD
            filenames_train{k} = fullfile(datasetPaths{1}, cocoData.images(k).file_name);
            imageIDList(k)     = cocoData.images(k).id;
        end
    end

    annotations = cocoData.annotations;
    for i = 1:length(annotations)
        if iscell(annotations), ann = annotations{i};
        else,                   ann = annotations(i);
        end
        idx = find(classIDs == ann.category_id);
        if ~isempty(idx)
            countsPerSplit(idx, d) = countsPerSplit(idx, d) + 1;
        end
        if d == 1
            catName = lower(classNames_coco(idx));
            imgIdx  = find(imageIDList == ann.image_id, 1);
            bbox    = ann.bbox;
            if catName == targetClass1
                peopleBoxes_train{imgIdx} = [peopleBoxes_train{imgIdx}; bbox];
            elseif any(catName == targetClass2)
                vehicleBoxes_train{imgIdx} = [vehicleBoxes_train{imgIdx}; bbox];
            end
        end
    end
end

%% ---- 5. Print Image Counts per Split --------------------

totalImages = sum(numImagesPerSplit);
fprintf('\nImage Count and Percentage by Dataset Split\n');
fprintf('%-12s | %-10s | %-11s\n', 'Dataset', 'N Images', 'Percentage');
fprintf('------------------------------------------\n');
for d = 1:length(datasetPaths)
    pct = (numImagesPerSplit(d) / totalImages) * 100;
    fprintf('%-12s | %-10d | %.2f%%\n', splitNames{d}, numImagesPerSplit(d), pct);
end

%% ---- 6. Print Per-Category Instance Counts --------------

targetCategories = [targetClass1, targetClass2];
fprintf('\nNumber of Instances for Relevant Categories\n');
fprintf('%-15s | %-7s | %-7s | %-7s\n', 'Category', 'Train', 'Val', 'Test');
fprintf('---------------------------------------------------\n');
for c = 1:length(targetCategories)
    idxCat = find(lowerClassNames == targetCategories(c));
    if ~isempty(idxCat)
        fprintf('%-15s | %-7d | %-7d | %-7d\n', ...
            classNames_coco(idxCat), ...
            countsPerSplit(idxCat,1), countsPerSplit(idxCat,2), countsPerSplit(idxCat,3));
    end
end

%% ---- 7. Print Grouped Class Counts ----------------------

countsClass1 = zeros(1,3);
countsClass2 = zeros(1,3);
idxPerson = find(lowerClassNames == targetClass1);
if ~isempty(idxPerson)
    countsClass1 = countsPerSplit(idxPerson, :);
end
for v = 1:length(targetClass2)
    idxVeh = find(lowerClassNames == targetClass2(v));
    if ~isempty(idxVeh)
        countsClass2 = countsClass2 + countsPerSplit(idxVeh, :);
    end
end

fprintf('\nGrouped Instance Counts\n');
fprintf('%-20s | %-7s | %-7s | %-7s\n', 'Class', 'Train', 'Val', 'Test');
fprintf('------------------------------------------------------\n');
fprintf('%-20s | %-7d | %-7d | %-7d\n', 'Class 1 (People)',   countsClass1(1), countsClass1(2), countsClass1(3));
fprintf('%-20s | %-7d | %-7d | %-7d\n', 'Class 2 (Vehicles)', countsClass2(1), countsClass2(2), countsClass2(3));

%% ---- 8. Visualise Training Samples ----------------------

sampleIndices = [700, 1000, 2000];
figure('Name', 'Dataset Samples with Grouped Classes', 'Position', [100,100,1500,500]);
for i = 1:length(sampleIndices)
    idx = sampleIndices(i);
    img = imread(filenames_train{idx});
    img = aux_annotate(img, double(peopleBoxes_train{idx}), double(vehicleBoxes_train{idx}));
    subplot(1,3,i); imshow(img);
    title(sprintf('Image %d', i), 'FontSize', 12);
end

%% ---- 9. Create Datastores for All Splits ----------------

combinedDatastores = cell(1, length(datasetPaths));

for d = 1:length(datasetPaths)
    cocoPath = fullfile(datasetPaths{d}, 'coco.json');
    cocoData = jsondecode(fileread(cocoPath));

    numImgs      = length(cocoData.images);
    filenames    = cell(numImgs, 1);
    peopleBoxes  = cell(numImgs, 1);
    vehicleBoxes = cell(numImgs, 1);

    imgID_to_idx = containers.Map('KeyType','int32','ValueType','int32');
    for i = 1:numImgs
        img = cocoData.images(i);
        if iscell(img), img = img{1}; end
        filenames{i}                = fullfile(datasetPaths{d}, img.file_name);
        imgID_to_idx(int32(img.id)) = int32(i);
        peopleBoxes{i}  = zeros(0,4);
        vehicleBoxes{i} = zeros(0,4);
    end

    annotations = cocoData.annotations;
    for i = 1:length(annotations)
        ann = annotations(i);
        if iscell(ann), ann = ann{1}; end
        imgID = int32(ann.image_id);
        catID = ann.category_id;
        if isKey(imgID_to_idx, imgID)
            idx  = imgID_to_idx(imgID);
            bbox = ann.bbox(:)';
            if ismember(catID, class1_IDs)
                peopleBoxes{idx}  = [peopleBoxes{idx};  bbox];
            elseif ismember(catID, class2_IDs)
                vehicleBoxes{idx} = [vehicleBoxes{idx}; bbox];
            end
        end
    end

    gtTable = table(filenames, peopleBoxes, vehicleBoxes, ...
        'VariableNames', {'Filename','People','Vehicles'});
    imds = imageDatastore(gtTable.Filename);
    blds = boxLabelDatastore(gtTable(:,2:3));
    combinedDatastores{d} = combine(imds, blds);
    fprintf('Created Combined Datastore for %-12s: %d images\n', splitNames{d}, numImgs);
end

dsTrain = combinedDatastores{1};
dsVal   = combinedDatastores{2};
dsTest  = combinedDatastores{3};

%% ---- 10. Data Augmentation ------------------------------

dsTrainAugmented = transform(dsTrain, @aux_augment_data);

reset(dsTrain); reset(dsTrainAugmented);
originalData  = read(dsTrain);
augmentedData = read(dsTrainAugmented);

figure('Name', 'Augmentation Verification');
subplot(1,2,1);
imshow(aux_annotate(originalData{1}, originalData{2}, originalData{3}));
title('Original Thermal Image', 'FontSize', 12);
subplot(1,2,2);
imshow(aux_annotate(augmentedData{1}, augmentedData{2}, augmentedData{3}));
title('Augmented (Random Flip & Scale)', 'FontSize', 12);

fprintf('\nPipeline complete. Datastores ready: dsTrain, dsVal, dsTest, dsTrainAugmented.\n');

%% =========================================================
%  PHASE 1: TRANSFER LEARNING BASELINES
%% =========================================================

detClassNames = {'People', 'Vehicles'};
numDetClasses = numel(detClassNames);

%% ---- 11. Build Classification Datastores ----------------
% Converts combined datastores into labelled imageDatastores.
% Labels are embedded via imds.Labels so trainNetwork(ds,layers,opts)
% can read both predictors and responses from a single datastore.

fprintf('\nBuilding classification datastores...\n');

[imdsTrainCls, labelsTrain] = build_cls_ds(dsTrain, detClassNames);
[imdsValCls,   labelsVal  ] = build_cls_ds(dsVal,   detClassNames);
[imdsTestCls,  labelsTest ] = build_cls_ds(dsTest,  detClassNames);

% Embed labels into the imageDatastore — this is the ONLY correct way
% to make trainNetwork(ds, layers, opts) see both image and label
imdsTrainCls.Labels = labelsTrain;
imdsValCls.Labels   = labelsVal;
imdsTestCls.Labels  = labelsTest;

fprintf('Train : %d  (People: %d | Vehicles: %d)\n', numel(labelsTrain), sum(labelsTrain=="People"), sum(labelsTrain=="Vehicles"));
fprintf('Val   : %d  (People: %d | Vehicles: %d)\n', numel(labelsVal),   sum(labelsVal=="People"),   sum(labelsVal=="Vehicles"));
fprintf('Test  : %d  (People: %d | Vehicles: %d)\n', numel(labelsTest),  sum(labelsTest=="People"),  sum(labelsTest=="Vehicles"));

%% ---- 12. SqueezeNet Transfer Learning -------------------

fprintf('\n=== SqueezeNet (227x227) ===\n');
netSq    = squeezenet;
lgraphSq = layerGraph(netSq);

lgraphSq = replaceLayer(lgraphSq, 'conv10', ...
    convolution2dLayer(1, numDetClasses, ...
        'WeightLearnRateFactor', 10, 'BiasLearnRateFactor', 10, 'Name', 'new_conv'));
lgraphSq = replaceLayer(lgraphSq, 'ClassificationLayer_predictions', ...
    classificationLayer('Name', 'new_classoutput'));

% augmentedImageDatastore with Labels embedded reads as a labelled ds
inputSizeSq = [227 227 3];
augTrainSq  = augmentedImageDatastore(inputSizeSq, imdsTrainCls, 'ColorPreprocessing', 'gray2rgb');
augValSq    = augmentedImageDatastore(inputSizeSq, imdsValCls,   'ColorPreprocessing', 'gray2rgb');

optsSq = trainingOptions('sgdm', ...
    'InitialLearnRate',    0.001, ...
    'MaxEpochs',           10, ...
    'MiniBatchSize',       32, ...
    'Shuffle',             'every-epoch', ...
    'ValidationData',      augValSq, ...
    'ValidationFrequency', 50, ...
    'Verbose',             true, ...
    'Plots',               'training-progress');

[trainedSq, infoSq] = trainNetwork(augTrainSq, lgraphSq, optsSq);
save('squeezenet_thermal.mat', 'trainedSq', 'infoSq');
fprintf('SqueezeNet saved.\n');

%% ---- 13. GoogLeNet Transfer Learning --------------------

fprintf('\n=== GoogLeNet (224x224) ===\n');
netGoog    = googlenet;
lgraphGoog = layerGraph(netGoog);

lgraphGoog = replaceLayer(lgraphGoog, 'loss3-classifier', ...
    fullyConnectedLayer(numDetClasses, ...
        'WeightLearnRateFactor', 10, 'BiasLearnRateFactor', 10, 'Name', 'new_fc'));
lgraphGoog = replaceLayer(lgraphGoog, 'output', ...
    classificationLayer('Name', 'new_output'));

inputSizeGoog = [224 224 3];
augTrainGoog  = augmentedImageDatastore(inputSizeGoog, imdsTrainCls, 'ColorPreprocessing', 'gray2rgb');
augValGoog    = augmentedImageDatastore(inputSizeGoog, imdsValCls,   'ColorPreprocessing', 'gray2rgb');

optsGoog = trainingOptions('sgdm', ...
    'InitialLearnRate',    0.001, ...
    'MaxEpochs',           10, ...
    'MiniBatchSize',       32, ...
    'Shuffle',             'every-epoch', ...
    'ValidationData',      augValGoog, ...
    'ValidationFrequency', 50, ...
    'Verbose',             true, ...
    'Plots',               'training-progress');

[trainedGoog, infoGoog] = trainNetwork(augTrainGoog, lgraphGoog, optsGoog);
save('googlenet_thermal.mat', 'trainedGoog', 'infoGoog');
fprintf('GoogLeNet saved.\n');

%% ---- 14. Training Curves --------------------------------

figure('Name', 'Training Curves', 'Position', [100 100 1400 500]);

subplot(2,2,1); plot(infoSq.TrainingLoss,       'b-', 'LineWidth', 1.5); grid on;
xlabel('Iteration'); ylabel('Loss');         title('SqueezeNet - Training Loss');

subplot(2,2,2); plot(infoSq.TrainingAccuracy,   'b-', 'LineWidth', 1.5); grid on;
xlabel('Iteration'); ylabel('Accuracy (%)'); title('SqueezeNet - Training Accuracy');

subplot(2,2,3); plot(infoGoog.TrainingLoss,     'r-', 'LineWidth', 1.5); grid on;
xlabel('Iteration'); ylabel('Loss');         title('GoogLeNet - Training Loss');

subplot(2,2,4); plot(infoGoog.TrainingAccuracy, 'r-', 'LineWidth', 1.5); grid on;
xlabel('Iteration'); ylabel('Accuracy (%)'); title('GoogLeNet - Training Accuracy');

%% ---- 15. Evaluation on Validation Set -------------------

fprintf('\n=== Validation Evaluation ===\n');

predsSq   = classify(trainedSq,   augValSq);
predsGoog = classify(trainedGoog, augValGoog);

accSq   = mean(predsSq   == labelsVal) * 100;
accGoog = mean(predsGoog == labelsVal) * 100;

fprintf('SqueezeNet  Val Accuracy: %.2f%%\n', accSq);
fprintf('GoogLeNet   Val Accuracy: %.2f%%\n', accGoog);

figure('Name', 'SqueezeNet Confusion Matrix');
confusionchart(labelsVal, predsSq,   'Title', sprintf('SqueezeNet (%.2f%%)', accSq));

figure('Name', 'GoogLeNet Confusion Matrix');
confusionchart(labelsVal, predsGoog, 'Title', sprintf('GoogLeNet (%.2f%%)',  accGoog));

%% ---- 16. Precision & Recall per Class -------------------

for modelIdx = 1:2
    if modelIdx == 1, preds = predsSq;   mName = 'SqueezeNet';
    else,             preds = predsGoog; mName = 'GoogLeNet';
    end
    fprintf('\n--- %s ---\n', mName);
    for c = 1:numDetClasses
        cls  = categorical(detClassNames(c));
        TP   = sum(preds == cls & labelsVal == cls);
        FP   = sum(preds == cls & labelsVal ~= cls);
        FN   = sum(preds ~= cls & labelsVal == cls);
        prec = TP / (TP + FP + eps);
        rec  = TP / (TP + FN + eps);
        fprintf('  %-10s  Precision: %.2f%%  Recall: %.2f%%\n', ...
            detClassNames{c}, prec*100, rec*100);
    end
end

%% ---- 17. Baseline Comparison Summary --------------------

ModelName  = {'SqueezeNet'; 'GoogLeNet'};
Depth      = [18; 22];
SizeMB     = {'5.2 MB'; '27 MB'};
Parameters = {'1.24 M'; '7.0 M'};
InputSize  = {'227x227'; '224x224'};
ValAcc     = [accSq; accGoog];

CompTable = table(ModelName, Depth, SizeMB, Parameters, InputSize, ValAcc, ...
    'VariableNames', {'Model','Depth','Size','Parameters','InputSize','ValAcc_pct'});

fprintf('\n--- Baseline Comparison ---\n');
disp(CompTable);

[~, bestIdx] = max(ValAcc);
fprintf('Best baseline: %s (%.2f%% val accuracy)\n', ModelName{bestIdx}, ValAcc(bestIdx));

%% =========================================================
%  LOCAL FUNCTIONS  (must be at the end of the script)
%% =========================================================

function [imdsOut, labelsOut] = build_cls_ds(ds, clsNames)
% Assigns ONE label per image:
%   - Has people only    -> 'People'
%   - Has vehicles only  -> 'Vehicles'  
%   - Has BOTH           -> include TWICE (once per class)
%   - Has neither        -> skip

    allFiles   = ds.UnderlyingDatastores{1}.Files;
    nImages    = numel(allFiles);
    keptFiles  = {};
    keptLabels = {};

    reset(ds);
    for ii = 1:nImages
        data      = read(ds);
        nPeople   = size(data{2}, 1);
        nVehicles = size(data{3}, 1);

        if nPeople == 0 && nVehicles == 0
            continue;
        end

        if nPeople > 0
            keptFiles{end+1}  = allFiles{ii};   %#ok<AGROW>
            keptLabels{end+1} = clsNames{1};    %#ok<AGROW>  'People'
        end
        if nVehicles > 0
            keptFiles{end+1}  = allFiles{ii};   %#ok<AGROW>
            keptLabels{end+1} = clsNames{2};    %#ok<AGROW>  'Vehicles'
        end
    end

    imdsOut   = imageDatastore(keptFiles);
    labelsOut = categorical(keptLabels, clsNames);

    fprintf('  Entries: %d  (People: %d | Vehicles: %d)\n', ...
        numel(keptFiles), sum(labelsOut=="People"), sum(labelsOut=="Vehicles"));
end