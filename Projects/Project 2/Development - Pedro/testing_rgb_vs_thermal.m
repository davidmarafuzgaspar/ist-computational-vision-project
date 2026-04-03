%% =========================================================
%  MODEL EVALUATION - RGB & THERMAL TEST SETS
% ==========================================================
clc; clear; close all;

%% ── 1. SETUP PATHS & LOAD MODEL ──────────────────────────
modelPath = './Output/improved_squeezenet/detector_improved.mat';
if ~exist(modelPath, 'file')
    error('Trained model not found at %s. Please train the model first.', modelPath);
end
load(modelPath); % Loads 'detector' and 'trainInfo'

% Define your test directories
testSets = struct(...
    'Name', {'Thermal', 'RGB'}, ...
    'ImgDir', {'./Data/video_thermal_test', './Data/video_rgb_test'}, ...
    'AnnFile', {'./Data/video_thermal_test/coco.json', './Data/video_rgb_test/coco.json'} ...
);

classNames = {'person', 'vehicle'};
vehicleCategories = ["car", "motor", "bus", "train", "truck", "other vehicle"];
inputSize = detector.TrainingImageSize;

%% ── 2. LOOP THROUGH EACH MODALITY ────────────────────────
for s = 1:numel(testSets)
    fprintf('\n>> Evaluating modality: %s\n', testSets(s).Name);
    
    if ~exist(testSets(s).AnnFile, 'file')
        fprintf('   Warning: Annotation file for %s not found. Skipping.\n', testSets(s).Name);
        continue;
    end
    
    % Parse annotations
    testData = parseCOCO(testSets(s).AnnFile, testSets(s).ImgDir, vehicleCategories);
    
    % Convert to datastore
    testDS = combine(imageDatastore(testData.imageFilename), ...
                     boxLabelDatastore(testData(:, 2:3)));
    testDS = transform(testDS, @(x) preprocessData(x, inputSize));
    
    % Run Detection
    fprintf('   Running detection on %d images...\n', height(testData));
    results = detect(detector, testDS, 'MiniBatchSize', 8, 'Threshold', 0.3);
    
    % Evaluate Metrics
    [ap, recall, precision] = evaluateDetectionPrecision(results, testDS);
    mAP = mean(ap);
    
    % Display Results
    T_res = table(classNames', ap, 'VariableNames', {'Class', 'AP'});
    fprintf('   Results for %s:\n', testSets(s).Name);
    disp(T_res);
    fprintf('   Mean AP: %.4f\n', mAP);
    
    % Plot Precision-Recall Curves
    figure('Name', ['PR Curve - ' testSets(s).Name]);
    for i = 1:numel(classNames)
        subplot(1, 2, i);
        plot(recall{i}, precision{i}, 'LineWidth', 2);
        xlabel('Recall'); ylabel('Precision');
        grid on; title(sprintf('%s: %s (AP: %.2f)', testSets(s).Name, classNames{i}, ap(i)));
    end
end

fprintf('\n>> Cross-modality testing complete.\n');

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