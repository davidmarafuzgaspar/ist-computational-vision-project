%% =========================================================
%  BASELINE OBJECT DETECTION - YOLOv2 + SqueezeNet
%  Transfer Learning | 2 Classes: Person + Vehicle
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

classNames = {'person', 'vehicle'};

% Vehicle categories to merge into single 'vehicle' class
vehicleCategories = ["car", "motor", "bus", "train", "truck", "other vehicle"];

inputSize  = [416 416 3];
numAnchors = 5;
numEpochs  = 30;
batchSize  = 8;

% Create output folder if it doesn't exist
if ~exist('./Output', 'dir'); mkdir('./Output'); end

%% ── 2. PARSE ANNOTATIONS ─────────────────────────────────

fprintf('>> Loading annotations...\n');
trainData = parseCOCO(trainAnnFile, trainImgDir, vehicleCategories);
valData   = parseCOCO(valAnnFile,   valImgDir,   vehicleCategories);
testData  = parseCOCO(testAnnFile,  testImgDir,  vehicleCategories);

fprintf('   Train : %d | Val : %d | Test : %d\n', ...
        height(trainData), height(valData), height(testData));

% Verify class distribution
allLabels = vertcat(trainData.labels{:});
disp('Class distribution in training set:');
disp(countcats(allLabels));

%% ── 3. ESTIMATE ANCHOR BOXES ─────────────────────────────

fprintf('\n>> Estimating anchor boxes...\n');
blds = boxLabelDatastore(trainData(:, 2:3));
[anchors, meanIoU] = estimateAnchorBoxes(blds, numAnchors);
fprintf('   Mean IoU: %.4f\n', meanIoU);

%% ── 4. BUILD YOLOV2 + SQUEEZENET ─────────────────────────

fprintf('\n>> Building YOLOv2 with SqueezeNet backbone...\n');

baseNet      = squeezenet;
featureLayer = 'fire9-concat';

lgraph = yolov2Layers(inputSize, numel(classNames), anchors, ...
                      baseNet, featureLayer);

%% ── 5. CONVERT TO DATASTORES ─────────────────────────────

fprintf('\n>> Converting to datastores...\n');

% Transform: grayscale → 3-channel, keep boxes and labels
grayToRGB = @(data) {repmat(data{1}, [1 1 3]), data{2}, data{3}};

trainDS = combine(imageDatastore(trainData.imageFilename), ...
                  boxLabelDatastore(trainData(:, 2:3)));
trainDS = transform(trainDS, grayToRGB);

valDS   = combine(imageDatastore(valData.imageFilename), ...
                  boxLabelDatastore(valData(:, 2:3)));
valDS   = transform(valDS, grayToRGB);

testDS  = combine(imageDatastore(testData.imageFilename), ...
                  boxLabelDatastore(testData(:, 2:3)));
testDS  = transform(testDS, grayToRGB);

%% ── 6. TRAINING OPTIONS ──────────────────────────────────

options = trainingOptions('sgdm', ...
    'MiniBatchSize',        batchSize,  ...
    'MaxEpochs',            numEpochs,  ...
    'InitialLearnRate',     1e-3,       ...
    'ValidationData',       valDS,      ...
    'ValidationFrequency',  50,         ...
    'Verbose',              true,       ...
    'Plots',                'none',     ...
    'ExecutionEnvironment', 'auto');

%% ── 7. TRAIN ─────────────────────────────────────────────

fprintf('\n>> Training baseline (YOLOv2 + SqueezeNet)...\n');
[detector, trainInfo] = trainYOLOv2ObjectDetector(trainDS, lgraph, options);
save('./Output/detector_baseline.mat', 'detector', 'trainInfo');
fprintf('   Model saved to Output/detector_baseline.mat\n');

%% ── 8. EVALUATE ──────────────────────────────────────────

fprintf('\n>> Evaluating on test set...\n');
results = detect(detector, testDS, 'MiniBatchSize', 4, 'Threshold', 0.3);
[ap, recall, precision] = evaluateDetectionPrecision(results, testDS);
mAP = mean(ap);

% Results table
T_results = table(classNames', ap, ...
    'VariableNames', {'Class', 'AP'});
disp('Table: Average Precision per Class');
disp(T_results);
fprintf('mAP = %.4f\n', mAP);

% Save AP results to CSV
writetable(T_results, './Output/ap_results.csv');
fprintf('   AP results saved to Output/ap_results.csv\n');

%% ── 9. SAVE PRECISION-RECALL DATA ────────────────────────

fprintf('\n>> Saving Precision-Recall data...\n');
for i = 1:numel(classNames)
    T_pr = table(recall{i}, precision{i}, ...
        'VariableNames', {'Recall', 'Precision'});
    fname = sprintf('./Output/pr_curve_%s.csv', classNames{i});
    writetable(T_pr, fname);
    fprintf('   Saved: %s\n', fname);
end

%% ── 10. SAVE TRAINING INFO ───────────────────────────────

fprintf('\n>> Saving training history...\n');

fields = fieldnames(trainInfo);
disp('Available trainInfo fields:');
disp(fields);

% Save each numeric field as its own CSV
for i = 1:numel(fields)
    val = trainInfo.(fields{i});
    if isnumeric(val) && ~isempty(val)
        T_field = table(val(:), 'VariableNames', {fields{i}});
        fname   = sprintf('./Output/training_%s.csv', fields{i});
        writetable(T_field, fname);
        fprintf('   Saved: %s (%d values)\n', fname, numel(val));
    end
end

fprintf('   Training history saved.\n');

%% ── 11. SAVE RESULTS SUMMARY ─────────────────────────────

fprintf('\n>> Saving results summary...\n');

summary.mAP        = mAP;
summary.AP_person  = ap(strcmp(classNames, 'person'));
summary.AP_vehicle = ap(strcmp(classNames, 'vehicle'));
summary.numEpochs  = numEpochs;
summary.batchSize  = batchSize;
summary.backbone   = 'squeezenet';
summary.inputSize  = inputSize;
summary.numAnchors = numAnchors;

fid = fopen('./Output/results_summary.json', 'w');
fprintf(fid, '%s', jsonencode(summary));
fclose(fid);
fprintf('   Summary saved to Output/results_summary.json\n');

%% ── 12. SAVE SAMPLE DETECTION DATA ──────────────────────

fprintf('\n>> Saving sample detection results...\n');
numShow    = min(6, height(testData));
detResults = struct();

for i = 1:numShow
    img = imread(testData.imageFilename{i});
    if size(img, 3) == 1
        img = repmat(img, [1 1 3]);
    end
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

fid = fopen('./Output/sample_detections.json', 'w');
fprintf(fid, '%s', jsonencode(detResults));
fclose(fid);
fprintf('   Sample detections saved to Output/sample_detections.json\n');

fprintf('\n>> Done!\n');


%% =========================================================
%  LOCAL FUNCTION — Parse COCO JSON → MATLAB table
%  Merges vehicle subcategories into single 'vehicle' class
% ==========================================================
function T = parseCOCO(jsonPath, imgDir, vehicleCategories)

    classNames = {'person', 'vehicle'};

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

    % ── category_id → 'person' or 'vehicle' ───────────────
    catMap = containers.Map('KeyType','double','ValueType','char');
    for i = 1:numel(coco.categories)
        if iscell(coco.categories)
            cat = coco.categories{i};
        else
            cat = coco.categories(i);
        end
        name = lower(cat.name);
        if strcmp(name, 'person')
            catMap(double(cat.id)) = 'person';
        elseif any(strcmp(name, vehicleCategories))
            catMap(double(cat.id)) = 'vehicle';
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

        b      = ann.bbox;
        box    = [b(1)+1, b(2)+1, max(b(3),1), max(b(4),1)];
        lbl    = categorical({catMap(double(ann.category_id))}, classNames);
        id     = double(ann.image_id);

        if isKey(boxMap, id)
            boxMap(id)   = [boxMap(id);   box];
            labelMap(id) = [labelMap(id); lbl'];
        else
            boxMap(id)   = box;
            labelMap(id) = lbl';
        end
    end

    % ── build and validate table ───────────────────────────
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

    % Remove invalid rows
    validRows = true(height(T), 1);
    for i = 1:height(T)
        if size(T.boxes{i}, 1) ~= numel(T.labels{i})
            validRows(i) = false;
        end
    end
    T = T(validRows, :);
    fprintf('   Kept %d / %d valid rows\n', sum(validRows), numel(validRows));
end