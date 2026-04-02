%% =========================================================
%  BASELINE OBJECT DETECTION - Custom CNN from Scratch
%  YOLOv2 with custom backbone — FLIR ADAS Thermal
%  Intelligent Vision Systems - Topic A3
% ==========================================================

clc; clear; close all;

%% ── 1. CONFIGURATION ─────────────────────────────────────

datasetRoot  = fullfile('Data');
trainImgDir  = fullfile(datasetRoot, 'images_thermal_train', 'data');
valImgDir    = fullfile(datasetRoot, 'images_thermal_val',   'data');
testImgDir   = fullfile(datasetRoot, 'video_thermal_test',   'data');  % <-- real test set

trainAnnFile = fullfile(datasetRoot, 'images_thermal_train', 'coco.json');
valAnnFile   = fullfile(datasetRoot, 'images_thermal_val',   'coco.json');
testAnnFile  = fullfile(datasetRoot, 'video_thermal_test',   'coco.json');  % <-- real test annotations

classNames = {'person', 'car', 'motorcycle', 'bus', 'train', 'truck', 'other vehicle'};
inputSize  = [256 256 3];   % smaller input = faster training from scratch
numAnchors = 5;
numEpochs  = 40;
batchSize  = 16;

%% ── 2. PARSE COCO ANNOTATIONS ────────────────────────────

fprintf('>> Loading annotations...\n');
trainData = parseCOCO(trainAnnFile, trainImgDir, classNames);
valData   = parseCOCO(valAnnFile,   valImgDir,   classNames);
testData  = parseCOCO(testAnnFile,  testImgDir,  classNames);  % <-- real test set, no splitting needed

fprintf('   Train : %d | Val : %d | Test : %d\n', ...
        height(trainData), height(valData), height(testData));

allLabels = vertcat(trainData.labels{:});
disp(categories(allLabels));

%% ── 3. ESTIMATE ANCHOR BOXES ─────────────────────────────

fprintf('\n>> Estimating anchor boxes...\n');

% Convert training table to a boxLabelDatastore
blds = boxLabelDatastore(trainData(:, 2:3));  % columns: boxes + labels

[anchors, meanIoU] = estimateAnchorBoxes(blds, numAnchors);
fprintf('   Mean IoU: %.4f\n', meanIoU);

%% ── 4. BUILD CUSTOM CNN BACKBONE FROM SCRATCH ────────────
%
%   Architecture:
%   Input → [Conv → BN → ReLU → MaxPool] x4 → [Conv → BN → ReLU] x2
%
%   This is intentionally simple for a baseline.
%   Each conv block progressively increases filters: 32→64→128→256→512

fprintf('Number of classes: %d\n', numel(classNames));   % should print 7

fprintf('\n>> Building custom CNN backbone from scratch...\n');

layers = [
    % ── Input ──────────────────────────────────────────────
    imageInputLayer(inputSize, 'Name', 'input', ...
                    'Normalization', 'rescale-zero-one')

    % ── Block 1: 32 filters ────────────────────────────────
    convolution2dLayer(3, 32, 'Padding','same', 'Name','conv1')
    batchNormalizationLayer('Name','bn1')
    reluLayer('Name','relu1')
    maxPooling2dLayer(2, 'Stride',2, 'Name','pool1')   % 128x128

    % ── Block 2: 64 filters ────────────────────────────────
    convolution2dLayer(3, 64, 'Padding','same', 'Name','conv2')
    batchNormalizationLayer('Name','bn2')
    reluLayer('Name','relu2')
    maxPooling2dLayer(2, 'Stride',2, 'Name','pool2')   % 64x64

    % ── Block 3: 128 filters ───────────────────────────────
    convolution2dLayer(3, 128, 'Padding','same', 'Name','conv3')
    batchNormalizationLayer('Name','bn3')
    reluLayer('Name','relu3')
    maxPooling2dLayer(2, 'Stride',2, 'Name','pool3')   % 32x32

    % ── Block 4: 256 filters ───────────────────────────────
    convolution2dLayer(3, 256, 'Padding','same', 'Name','conv4')
    batchNormalizationLayer('Name','bn4')
    reluLayer('Name','relu4')
    maxPooling2dLayer(2, 'Stride',2, 'Name','pool4')   % 16x16

    % ── Block 5: 512 filters (no pooling — feature map) ────
    convolution2dLayer(3, 512, 'Padding','same', 'Name','conv5')
    batchNormalizationLayer('Name','bn5')
    reluLayer('Name','relu5')

    % ── Block 6: 512 filters (final feature layer) ─────────
    convolution2dLayer(3, 512, 'Padding','same', 'Name','conv6')
    batchNormalizationLayer('Name','bn6')
    reluLayer('Name','relu6')   % <-- YOLOv2 will attach here
];

% Convert to layer graph
lgraph = layerGraph(layers);

% Attach YOLOv2 detection head on top of the last ReLU
lgraph = yolov2Layers(inputSize, numel(classNames), anchors, ...
                      lgraph, 'relu6');

% Inspect the full network
%analyzeNetwork(lgraph);

%% ── 5. TRAINING OPTIONS ──────────────────────────────────

options = trainingOptions('adam', ...   % Adam works better training from scratch
    'MiniBatchSize',        batchSize,  ...
    'MaxEpochs',            numEpochs,  ...
    'InitialLearnRate',     1e-3,       ...
    'LearnRateSchedule',    'piecewise',...
    'LearnRateDropFactor',  0.5,        ...
    'LearnRateDropPeriod',  15,         ...
    'L2Regularization',     5e-4,       ...
    'ValidationData',       valData,    ...
    'ValidationFrequency',  50,         ...
    'Shuffle',              'every-epoch', ...
    'Verbose',              true,       ...
    'Plots',                'training-progress', ...
    'ExecutionEnvironment', 'auto');

%% ── 6. TRAIN ─────────────────────────────────────────────

fprintf('\n>> Training from scratch...\n');
[detector, trainInfo] = trainYOLOv2ObjectDetector(trainData, lgraph, options);
save('detector_baseline_scratch.mat', 'detector', 'trainInfo');
fprintf('   Model saved.\n');

%% ── 7. EVALUATE ──────────────────────────────────────────

fprintf('\n>> Evaluating on test set...\n');
results = detect(detector, testData, 'MiniBatchSize',4, 'Threshold',0.3);
[ap, recall, precision] = evaluateDetectionPrecision(results, testData(:,2:3));
mAP = mean(ap);

fprintf('\n========== RESULTS ==========\n');
for i = 1:numel(classNames)
    fprintf('  %-10s  AP = %.4f\n', classNames{i}, ap(i));
end
fprintf('  ----------------------------\n');
fprintf('  mAP = %.4f\n', mAP);
fprintf('==============================\n');

%% ── 8. PRECISION-RECALL CURVES ───────────────────────────

figure('Name','Precision-Recall Curves');
colors = lines(numel(classNames));
for i = 1:numel(classNames)
    plot(recall{i}, precision{i}, 'LineWidth',2, 'Color',colors(i,:));
    hold on;
end
legend(classNames, 'Location','southwest');
xlabel('Recall'); ylabel('Precision');
title(sprintf('Precision-Recall — Baseline from Scratch | mAP = %.4f', mAP));
grid on;
saveas(gcf, 'pr_curve_baseline_scratch.png');

%% ── 9. VISUALISE DETECTIONS ──────────────────────────────

figure('Name','Detections');
numShow = min(6, height(testData));
for i = 1:numShow
    img = imread(testData.imageFilename{i});
    if size(img,3) == 1; img = repmat(img,[1 1 3]); end

    [bboxes, scores, labels] = detect(detector, img, 'Threshold',0.4);
    if ~isempty(bboxes)
        annLabels = strcat(cellstr(labels), {' '}, ...
            arrayfun(@(s) sprintf('%.2f',s), scores,'UniformOutput',false));
        img = insertObjectAnnotation(img,'rectangle',bboxes,annLabels,'LineWidth',2);
    end
    subplot(2,3,i); imshow(img); title(['Test ' num2str(i)]);
end
sgtitle('Baseline (Scratch) Detections');
saveas(gcf, 'detections_baseline_scratch.png');

fprintf('\n>> Done!\n');


%% =========================================================
%  LOCAL FUNCTION — Parse COCO JSON → MATLAB table
% ==========================================================
function T = parseCOCO(jsonPath, imgDir, classNames)
    raw  = fileread(jsonPath);
    coco = jsondecode(raw);

    % ── image_id → metadata ────────────────────────────────
    imgMap = containers.Map('KeyType','double','ValueType','any');
    for i = 1:numel(coco.images)
        if iscell(coco.images)
            img = coco.images{i};
        else
            img = coco.images(i);
        end
        imgMap(double(img.id)) = img;
    end

    % ── category_id → index within classNames ──────────────
    catMap = containers.Map('KeyType','double','ValueType','int32');
    for i = 1:numel(coco.categories)
        if iscell(coco.categories)
            cat = coco.categories{i};
        else
            cat = coco.categories(i);
        end
        idx = find(strcmpi(classNames, lower(cat.name)));
        if ~isempty(idx)
            catMap(double(cat.id)) = idx;
        end
    end

    % ── accumulate boxes per image ─────────────────────────
    boxMap   = containers.Map('KeyType','double','ValueType','any');
    labelMap = containers.Map('KeyType','double','ValueType','any');

    for k = 1:numel(coco.annotations)
        if iscell(coco.annotations)
            ann = coco.annotations{k};
        else
            ann = coco.annotations(k);
        end

        if ~isKey(catMap, double(ann.category_id)); continue; end

        b   = ann.bbox;
        box = [b(1)+1, b(2)+1, max(b(3),1), max(b(4),1)];  % 1-based, min size 1
        lbl = categorical({classNames{catMap(double(ann.category_id))}}, classNames);
        id  = double(ann.image_id);

        if isKey(boxMap, id)
            boxMap(id)   = [boxMap(id);   box];
            labelMap(id) = [labelMap(id); lbl'];  % column vector
        else
            boxMap(id)   = box;
            labelMap(id) = lbl';                  % column vector
        end
    end

    % ── build table ────────────────────────────────────────
    ids       = keys(boxMap);
    filePaths = cell(numel(ids),1);
    allBoxes  = cell(numel(ids),1);
    allLabels = cell(numel(ids),1);

    for i = 1:numel(ids)
        id           = ids{i};
        meta         = imgMap(id);
        filePaths{i} = fullfile(imgDir, meta.file_name);
        allBoxes{i}  = boxMap(id);
        allLabels{i} = labelMap(id);
    end

    T = table(filePaths, allBoxes, allLabels, ...
              'VariableNames',{'imageFilename','boxes','labels'});

    % ── remove invalid rows (box count ≠ label count) ──────
    validRows = true(height(T), 1);
    for i = 1:height(T)
        nBoxes  = size(T.boxes{i}, 1);
        nLabels = numel(T.labels{i});
        if nBoxes ~= nLabels
            validRows(i) = false;
        end
    end
    T = T(validRows, :);
    fprintf('   Kept %d / %d valid rows\n', sum(validRows), numel(validRows));
end