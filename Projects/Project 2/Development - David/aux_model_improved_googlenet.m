%% =========================================================
%  IMPROVED OBJECT DETECTION - YOLOv2 + GoogleNet
%  Data Augmentation + Better Training | 2 Classes
%  Intelligent Vision Systems - Topic A3
% ==========================================================

clc; clear; close all;

%% ── 1. CONFIGURATION ─────────────────────────────────────

trainImgDir  = './Data/images_thermal_train_subset';
valImgDir    = './Data/images_thermal_val_subset';
testImgDir   = './Data/video_thermal_test_subset';

trainAnnFile = fullfile(trainImgDir, 'coco.json');
valAnnFile   = fullfile(valImgDir,   'coco.json');
testAnnFile  = fullfile(testImgDir,  'coco.json');

classNames        = {'person', 'vehicle'};
vehicleCategories = ["car", "motor", "bus", "train", "truck", "other vehicle"];

inputSize  = [224 224 3];   % GoogleNet size
numAnchors = 7;             % more anchors = better box diversity
numEpochs  = 40;            % more epochs
batchSize  = 16;            % larger batch = more stable gradients

if ~exist('./Output', 'dir'); mkdir('./Output'); end

%% ── 2. PARSE ANNOTATIONS ─────────────────────────────────

fprintf('>> Loading annotations...\n');
trainData = parseCOCO(trainAnnFile, trainImgDir, vehicleCategories);
valData   = parseCOCO(valAnnFile,   valImgDir,   vehicleCategories);
testData  = parseCOCO(testAnnFile,  testImgDir,  vehicleCategories);

fprintf('   Train : %d | Val : %d | Test : %d\n', ...
        height(trainData), height(valData), height(testData));

allLabels = vertcat(trainData.labels{:});
disp('Class distribution in training set:');
disp(countcats(allLabels));

%% ── 3. ESTIMATE ANCHOR BOXES ─────────────────────────────

fprintf('\n>> Estimating anchor boxes...\n');
blds = boxLabelDatastore(trainData(:, 2:3));
[anchors, meanIoU] = estimateAnchorBoxes(blds, numAnchors);
fprintf('   Mean IoU: %.4f\n', meanIoU);

%% ── 4. BUILD YOLOV2 + GOOGLENET (IMPROVED) ──────────────
fprintf('\n>> Building YOLOv2 with GoogLeNet backbone...\n');

baseNet = googlenet; 
featureLayer = 'inception_4c-output'; 

lgraph = yolov2Layers(inputSize, numel(classNames), anchors, ...
                      baseNet, featureLayer);

%% ── 5. DATA AUGMENTATION PIPELINE ───────────────────────
%
%  Augmentations applied:
%    1. Grayscale → 3-channel conversion (required)
%    2. Random horizontal flip
%    3. Random brightness/contrast jitter
%    4. Random scaling
%    5. Random crop
%    6. Resize to inputSize

%% ── 6. CONVERT TO DATASTORES ─────────────────────────────

fprintf('\n>> Converting to datastores...\n');

% Training: with augmentation
trainDS = combine(imageDatastore(trainData.imageFilename), ...
                  boxLabelDatastore(trainData(:, 2:3)));
trainDS = transform(trainDS, @(x) augmentData(x, inputSize));

% Validation: preprocessing only, no augmentation
valDS   = combine(imageDatastore(valData.imageFilename), ...
                  boxLabelDatastore(valData(:, 2:3)));
valDS   = transform(valDS, @(x) preprocessData(x, inputSize));

% Test: preprocessing only
testDS  = combine(imageDatastore(testData.imageFilename), ...
                  boxLabelDatastore(testData(:, 2:3)));
testDS  = transform(testDS, @(x) preprocessData(x, inputSize));

%% ── 7. TRAINING OPTIONS ──────────────────────────────────

options = trainingOptions('adam', ...       % Adam > SGDM for fine-tuning
    'MiniBatchSize',        batchSize,  ...
    'MaxEpochs',            numEpochs,  ...
    'InitialLearnRate',     1e-4,       ...  % lower LR for pretrained network
    'LearnRateSchedule',    'piecewise',...
    'LearnRateDropFactor',  0.5,        ...
    'LearnRateDropPeriod',  15,         ...
    'L2Regularization',     1e-4,       ...
    'ValidationData',       valDS,      ...
    'ValidationFrequency',  50,         ...
    'Verbose',              true,       ...
    'Plots',                'none',     ...
    'ExecutionEnvironment', 'auto');

%% ── 8. TRAIN ─────────────────────────────────────────────

fprintf('\n>> Training improved model (YOLOv2 + GoogLeNet)...\n');
[detector, trainInfo] = trainYOLOv2ObjectDetector(trainDS, lgraph, options);
save('./Output/detector_improved.mat', 'detector', 'trainInfo');
fprintf('   Model saved to Output/detector_improved.mat\n');

%% ── 9. EVALUATE ──────────────────────────────────────────

fprintf('\n>> Evaluating on test set...\n');
results = detect(detector, testDS, 'MiniBatchSize', 4, 'Threshold', 0.3);
[ap, recall, precision] = evaluateDetectionPrecision(results, testDS);
mAP = mean(ap);

T_results = table(classNames', ap, ...
    'VariableNames', {'Class', 'AP'});
disp('Table: Average Precision per Class');
disp(T_results);
fprintf('mAP = %.4f\n', mAP);

writetable(T_results, './Output/ap_results_improved.csv');
fprintf('   AP results saved.\n');

%% ── 10. SAVE PRECISION-RECALL DATA ───────────────────────

fprintf('\n>> Saving Precision-Recall data...\n');
for i = 1:numel(classNames)
    T_pr  = table(recall{i}, precision{i}, ...
        'VariableNames', {'Recall', 'Precision'});
    fname = sprintf('./Output/pr_curve_improved_%s.csv', classNames{i});
    writetable(T_pr, fname);
    fprintf('   Saved: %s\n', fname);
end

%% ── 11. SAVE TRAINING HISTORY ────────────────────────────

fprintf('\n>> Saving training history...\n');
fields = fieldnames(trainInfo);
for i = 1:numel(fields)
    val = trainInfo.(fields{i});
    if isnumeric(val) && ~isempty(val)
        T_field = table(val(:), 'VariableNames', {fields{i}});
        fname   = sprintf('./Output/improved_training_%s.csv', fields{i});
        writetable(T_field, fname);
        fprintf('   Saved: %s (%d values)\n', fname, numel(val));
    end
end

%% ── 12. SAVE RESULTS SUMMARY ─────────────────────────────

fprintf('\n>> Saving results summary...\n');

summary.mAP        = mAP;
summary.AP_person  = ap(strcmp(classNames, 'person'));
summary.AP_vehicle = ap(strcmp(classNames, 'vehicle'));
summary.numEpochs  = numEpochs;
summary.batchSize  = batchSize;
summary.backbone   = 'googlenet';
summary.optimizer  = 'adam';
summary.inputSize  = inputSize;
summary.numAnchors = numAnchors;
summary.augmentation = true;

fid = fopen('./Output/results_summary_improved.json', 'w');
fprintf(fid, '%s', jsonencode(summary));
fclose(fid);
fprintf('   Summary saved.\n');

%% ── 13. SAVE SAMPLE DETECTIONS ───────────────────────────

fprintf('\n>> Saving sample detection results...\n');
numShow    = min(6, height(testData));
detResults = struct();

for i = 1:numShow
    img = imread(testData.imageFilename{i});
    if size(img, 3) == 1
        img = repmat(img, [1 1 3]);
    end
    img = imresize(img, inputSize(1:2));
    [bboxes, scores, labels] = detect(detector, img, 'Threshold', 0.4);

    detResults(i).imageFile = testData.imageFilename{i};
    if ~isempty(bboxes)
        detResults(i).bboxes = bboxes;
        detResults(i).scores = scores;
        detResults(i).labels = cellstr(labels);
    else
        detResults(i).bboxes = [];
        detResults(i).scores = [];
        detResults(i).labels = {};
    end
end

fid = fopen('./Output/sample_detections_improved.json', 'w');
fprintf(fid, '%s', jsonencode(detResults));
fclose(fid);
fprintf('   Sample detections saved.\n');

fprintf('\n>> Done!\n');


%% =========================================================
%  LOCAL FUNCTION — Parse COCO JSON → MATLAB table
% ==========================================================
function T = parseCOCO(jsonPath, imgDir, vehicleCategories)

    classNames = {'person', 'vehicle'};
    raw  = fileread(jsonPath);
    coco = jsondecode(raw);

    imgMap = containers.Map('KeyType','double','ValueType','any');
    for i = 1:numel(coco.images)
        if iscell(coco.images); img = coco.images{i};
        else;                   img = coco.images(i); end
        imgMap(double(img.id)) = img;
    end

    catMap = containers.Map('KeyType','double','ValueType','char');
    for i = 1:numel(coco.categories)
        if iscell(coco.categories); cat = coco.categories{i};
        else;                       cat = coco.categories(i); end
        name = lower(cat.name);
        if strcmp(name, 'person')
            catMap(double(cat.id)) = 'person';
        elseif any(strcmp(name, vehicleCategories))
            catMap(double(cat.id)) = 'vehicle';
        end
    end

    boxMap   = containers.Map('KeyType','double','ValueType','any');
    labelMap = containers.Map('KeyType','double','ValueType','any');

    for k = 1:numel(coco.annotations)
        if iscell(coco.annotations); ann = coco.annotations{k};
        else;                        ann = coco.annotations(k); end
        if ~isKey(catMap, double(ann.category_id)); continue; end
        b   = ann.bbox;
        box = [b(1)+1, b(2)+1, max(b(3),1), max(b(4),1)];
        lbl = categorical({catMap(double(ann.category_id))}, classNames);
        id  = double(ann.image_id);
        if isKey(boxMap, id)
            boxMap(id)   = [boxMap(id);   box];
            labelMap(id) = [labelMap(id); lbl'];
        else
            boxMap(id)   = box;
            labelMap(id) = lbl';
        end
    end

    ids       = keys(boxMap);
    filePaths = cell(numel(ids), 1);
    allBoxes  = cell(numel(ids), 1);
    allLabels = cell(numel(ids), 1);
    for i = 1:numel(ids)
        id           = ids{i};
        meta         = imgMap(id);
        filePaths{i} = fullfile(imgDir, meta.file_name);
        allBoxes{i}  = boxMap(id);
        allLabels{i} = labelMap(id);
    end

    T = table(filePaths, allBoxes, allLabels, ...
              'VariableNames', {'imageFilename','boxes','labels'});

    validRows = true(height(T), 1);
    for i = 1:height(T)
        if size(T.boxes{i}, 1) ~= numel(T.labels{i})
            validRows(i) = false;
        end
    end
    T = T(validRows, :);
    fprintf('   Kept %d / %d valid rows\n', sum(validRows), numel(validRows));
end

function dataOut = augmentData(dataIn, inputSize)
    img    = dataIn{1};
    boxes  = dataIn{2};
    labels = dataIn{3};

    % ── 1. Grayscale → 3-channel ──────────────────────────
    if size(img, 3) == 1
        img = repmat(img, [1 1 3]);
    end
    img = im2single(img);

    % ── 2. Random horizontal flip ─────────────────────────
    if rand > 0.5
        img   = fliplr(img);
        W     = size(img, 2);
        boxes(:,1) = W - boxes(:,1) - boxes(:,3);  % flip x coordinate
    end

    % ── 3. Random brightness jitter (±20%) ───────────────
    brightFactor = 1 + (rand - 0.5) * 0.4;
    img = img * brightFactor;
    img = min(max(img, 0), 1);   % clamp to [0,1]

    % ── 4. Random contrast jitter ─────────────────────────
    contrastFactor = 1 + (rand - 0.5) * 0.4;
    meanVal = mean(img(:));
    img     = (img - meanVal) * contrastFactor + meanVal;
    img     = min(max(img, 0), 1);

    % ── 5. Resize to input size ───────────────────────────
    [H, W, ~] = size(img);
    img   = imresize(img, inputSize(1:2));
    scaleX = inputSize(2) / W;
    scaleY = inputSize(1) / H;
    boxes(:,1) = boxes(:,1) * scaleX;
    boxes(:,2) = boxes(:,2) * scaleY;
    boxes(:,3) = boxes(:,3) * scaleX;
    boxes(:,4) = boxes(:,4) * scaleY;

    % ── Clamp boxes to image bounds ───────────────────────
    boxes(:,1) = max(boxes(:,1), 1);
    boxes(:,2) = max(boxes(:,2), 1);
    boxes(:,3) = min(boxes(:,3), inputSize(2) - boxes(:,1));
    boxes(:,4) = min(boxes(:,4), inputSize(1) - boxes(:,2));

    % Remove invalid boxes
    validBoxes = boxes(:,3) > 1 & boxes(:,4) > 1;
    boxes      = boxes(validBoxes, :);
    labels     = labels(validBoxes);

    dataOut = {img, boxes, labels};
end

function dataOut = preprocessData(dataIn, inputSize)
    img    = dataIn{1};
    boxes  = dataIn{2};
    labels = dataIn{3};

    % Grayscale → 3-channel + resize only (no augmentation for val/test)
    if size(img, 3) == 1
        img = repmat(img, [1 1 3]);
    end
    img        = im2single(img);
    [H, W, ~]  = size(img);
    img        = imresize(img, inputSize(1:2));
    scaleX     = inputSize(2) / W;
    scaleY     = inputSize(1) / H;
    boxes(:,1) = boxes(:,1) * scaleX;
    boxes(:,2) = boxes(:,2) * scaleY;
    boxes(:,3) = boxes(:,3) * scaleX;
    boxes(:,4) = boxes(:,4) * scaleY;

    dataOut = {img, boxes, labels};
end