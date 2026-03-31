%% =========================================================
%  FLIR ADAS Thermal - Object Detection Pipeline
%  Topic A3: People and Vehicle Detection
%  Covers: A3.3 (baseline) and A3.4 (improved model)
%% =========================================================

clc; clear; close all;

%% =========================================================
%  0. CONFIGURATION
%% =========================================================

% Paths - adjust if your folder structure differs
dataRoot   = '../Data';
trainDir   = fullfile(dataRoot, 'images_thermal_train');
valDir     = fullfile(dataRoot, 'images_thermal_val');
testDir    = fullfile(dataRoot, 'video_thermal_test');

% NOTE: Run Section 1 first and check the printed COCO category names.
% Update this list to EXACTLY match what is printed (case-sensitive).
targetClasses = ["person", "car", "bicycle"];

% Detection threshold for inference
detectionThreshold = 0.4;
nmsThreshold       = 0.5;

% Training config
numAnchorsBaseline = 6;   % YOLOv2
numAnchorsImproved = 9;   % YOLOv4
inputSize          = [224 224 3];

fprintf('=== FLIR Thermal Object Detection Pipeline ===\n\n');


%% =========================================================
%  1. DATASET CHARACTERISATION
%  *** CHECK PRINTED CLASS NAMES AND UPDATE targetClasses IF NEEDED ***
%% =========================================================

fprintf('--- 1. Dataset Characterisation ---\n');

datasets     = {trainDir, valDir, testDir};
datasetNames = {'Treino', 'Validacao', 'Teste'};

% Read class info from training COCO JSON
cocoTrain     = loadCOCO(fullfile(trainDir, 'coco.json'));
categories    = cocoTrain.categories;
numAllClasses = length(categories);
allClassNames = strings(1, numAllClasses);
allClassIDs   = zeros(1, numAllClasses);

fprintf('All classes in training JSON:\n');
for i = 1:numAllClasses
    allClassNames(i) = categories(i).name;
    allClassIDs(i)   = categories(i).id;
    fprintf('  ID %3d : "%s"\n', allClassIDs(i), allClassNames(i));
end
fprintf('\n');

% Count images and instances per dataset
numImagesPerDataset = zeros(1, 3);
countsPerDataset    = zeros(numAllClasses, 3);

for d = 1:3
    coco = loadCOCO(fullfile(datasets{d}, 'coco.json'));
    numImagesPerDataset(d) = length(coco.images);
    anns = coco.annotations;
    for i = 1:length(anns)
        if iscell(anns), ann = anns{i}; else ann = anns(i); end
        idx = find(allClassIDs == ann.category_id);
        if ~isempty(idx)
            countsPerDataset(idx, d) = countsPerDataset(idx, d) + 1;
        end
    end
end

fprintf('=== Nr de Imagens por Dataset ===\n');
fprintf('%-12s | Nr Imagens\n', 'Dataset');
fprintf('-------------------------\n');
for d = 1:3
    fprintf('%-12s | %d\n', datasetNames{d}, numImagesPerDataset(d));
end

idxNonZero   = any(countsPerDataset > 0, 2);
classNamesNZ = allClassNames(idxNonZero);
countsNZ     = countsPerDataset(idxNonZero, :);
fprintf('\n=== Nr de Instancias por Classe ===\n');
fprintf('%-20s | %-8s | %-8s | %-8s\n', 'Classe', 'Treino', 'Val', 'Teste');
fprintf('-------------------------------------------------------\n');
for i = 1:length(classNamesNZ)
    fprintf('%-20s | %-8d | %-8d | %-8d\n', ...
        classNamesNZ(i), countsNZ(i,1), countsNZ(i,2), countsNZ(i,3));
end
fprintf('\n');
fprintf('*** Update targetClasses in Section 0 if names differ from expected ***\n\n');


%% =========================================================
%  2. BUILD DATASTORES
%% =========================================================

fprintf('--- 2. Building Datastores ---\n');

[trainingData, numTrain] = buildDatastore(trainDir, targetClasses, allClassIDs, allClassNames);
[valData,      numVal  ] = buildDatastore(valDir,   targetClasses, allClassIDs, allClassNames);
[testData,     numTest ] = buildDatastore(testDir,  targetClasses, allClassIDs, allClassNames);

fprintf('\nTreino: %d | Validacao: %d | Teste: %d imagens com anotacoes alvo\n\n', ...
    numTrain, numVal, numTest);

% Separate sub-datastores needed for evaluation
imdsVal      = trainingData.UnderlyingDatastores{1};
bldsVal      = trainingData.UnderlyingDatastores{2};
imdsTest     = testData.UnderlyingDatastores{1};
bldsTest     = testData.UnderlyingDatastores{2};
bldsTrain    = trainingData.UnderlyingDatastores{2};


%% =========================================================
%  3. VISUALISE SAMPLE
%% =========================================================

fprintf('--- 3. Visualising Sample ---\n');

data   = preview(trainingData);
img    = data{1};
bboxes = data{2};
labels = data{3};

figure('Name', 'Sample Training Image');
imshow(img); hold on;
edgeColors = {'red','green','blue','yellow','cyan'};
for i = 1:size(bboxes,1)
    cIdx = find(targetClasses == string(labels(i)), 1);
    if isempty(cIdx), cIdx = 1; end
    rectangle('Position', bboxes(i,:), 'EdgeColor', edgeColors{cIdx}, 'LineWidth', 2);
    text(bboxes(i,1), max(bboxes(i,2)-5,1), string(labels(i)), ...
        'Color','yellow','FontSize',9,'FontWeight','bold','BackgroundColor','black');
end
title('Amostra de Treino - Thermal'); hold off;
fprintf('Imagem de amostra visualizada.\n\n');


%% =========================================================
%  4. BASELINE MODEL: YOLOv2 (A3.3)
%% =========================================================

fprintf('--- 4. Baseline: YOLOv2 com ResNet-18 ---\n');

fprintf('Estimando anchor boxes...\n');
[anchorsBaseline, meanIoUBaseline] = estimateAnchorBoxes(bldsTrain, numAnchorsBaseline);
fprintf('Mean IoU dos anchors (baseline): %.4f\n', meanIoUBaseline);

baseNetV2  = resnet18;
detectorV2 = yolov2ObjectDetector(baseNetV2, targetClasses, anchorsBaseline, ...
                 'InputSize', inputSize);

optionsV2 = trainingOptions('sgdm', ...
    'InitialLearnRate',    1e-3, ...
    'MaxEpochs',           30, ...
    'MiniBatchSize',       16, ...
    'Momentum',            0.9, ...
    'L2Regularization',    5e-4, ...
    'LearnRateSchedule',   'piecewise', ...
    'LearnRateDropFactor',  0.1, ...
    'LearnRateDropPeriod',  20, ...
    'ValidationData',      valData, ...
    'ValidationFrequency', 5, ...
    'Shuffle',             'every-epoch', ...
    'Verbose',             true, ...
    'Plots',               'training-progress');

fprintf('Treinando YOLOv2...\n');
[detectorV2, infoV2] = trainYOLOv2ObjectDetector(trainingData, detectorV2, optionsV2); %#ok<ASGLU>
save('detectorV2_baseline.mat', 'detectorV2');
fprintf('Modelo baseline guardado.\n\n');


%% =========================================================
%  5. EVALUATE BASELINE (A3.3)
%% =========================================================

fprintf('--- 5. Avaliacao Baseline (YOLOv2) ---\n');

resultsV2 = detect(detectorV2, imdsVal, ...
    'Threshold', detectionThreshold, 'SelectStrongest', true);
metricsV2 = evaluateObjectDetection(resultsV2, bldsVal, 'IoUThreshold', 0.5);

printMetrics('YOLOv2 Baseline', metricsV2, targetClasses);

figure('Name', 'YOLOv2 - Precision-Recall');
for i = 1:length(targetClasses)
    subplot(1, length(targetClasses), i);
    plot(metricsV2.ClassMetrics.Recall{i}, ...
         metricsV2.ClassMetrics.Precision{i}, 'b-', 'LineWidth', 2);
    xlabel('Recall'); ylabel('Precision');
    title(sprintf('%s | AP=%.3f', targetClasses(i), metricsV2.ClassMetrics.AP(i)));
    grid on; ylim([0 1]); xlim([0 1]);
end
sgtitle('YOLOv2 Baseline - Precision-Recall por Classe');


%% =========================================================
%  6. IMPROVED MODEL: YOLOv4 + Augmentation (A3.4)
%% =========================================================

fprintf('--- 6. Modelo Melhorado: YOLOv4 + Augmentation ---\n');

augTrainingData = transform(trainingData, @augmentThermal);

[anchorsImproved, meanIoUImproved] = estimateAnchorBoxes(bldsTrain, numAnchorsImproved);
fprintf('Mean IoU dos anchors (melhorado): %.4f\n', meanIoUImproved);

baseNetV4  = resnet50;
detectorV4 = yolov4ObjectDetector(baseNetV4, targetClasses, anchorsImproved, ...
                 'InputSize', inputSize);

optionsV4 = trainingOptions('adam', ...
    'InitialLearnRate',    1e-4, ...
    'MaxEpochs',           50, ...
    'MiniBatchSize',       8, ...
    'GradientThreshold',   1, ...
    'LearnRateSchedule',   'piecewise', ...
    'LearnRateDropFactor',  0.1, ...
    'LearnRateDropPeriod',  35, ...
    'ValidationData',      valData, ...
    'ValidationFrequency', 5, ...
    'Shuffle',             'every-epoch', ...
    'Verbose',             true, ...
    'Plots',               'training-progress');

fprintf('Treinando YOLOv4...\n');
[detectorV4, infoV4] = trainYOLOv4ObjectDetector(augTrainingData, detectorV4, optionsV4); %#ok<ASGLU>
save('detectorV4_improved.mat', 'detectorV4');
fprintf('Modelo melhorado guardado.\n\n');


%% =========================================================
%  7. EVALUATE IMPROVED MODEL (A3.4)
%% =========================================================

fprintf('--- 7. Avaliacao Modelo Melhorado (YOLOv4) ---\n');

resultsV4 = detect(detectorV4, imdsVal, ...
    'Threshold', detectionThreshold, 'SelectStrongest', true);
metricsV4 = evaluateObjectDetection(resultsV4, bldsVal, 'IoUThreshold', 0.5);

printMetrics('YOLOv4 Improved', metricsV4, targetClasses);

figure('Name', 'YOLOv4 - Precision-Recall');
for i = 1:length(targetClasses)
    subplot(1, length(targetClasses), i);
    plot(metricsV4.ClassMetrics.Recall{i}, ...
         metricsV4.ClassMetrics.Precision{i}, 'r-', 'LineWidth', 2);
    xlabel('Recall'); ylabel('Precision');
    title(sprintf('%s | AP=%.3f', targetClasses(i), metricsV4.ClassMetrics.AP(i)));
    grid on; ylim([0 1]); xlim([0 1]);
end
sgtitle('YOLOv4 Improved - Precision-Recall por Classe');


%% =========================================================
%  8. MODEL COMPARISON
%% =========================================================

fprintf('--- 8. Comparacao de Modelos ---\n\n');

% Print table
header = sprintf('%-25s | %-8s', 'Modelo', 'mAP');
for i = 1:length(targetClasses)
    header = [header sprintf(' | AP_%-10s', targetClasses(i))]; %#ok<AGROW>
end
fprintf('%s\n%s\n', header, repmat('-',1,length(header)));

rowV2 = sprintf('%-25s | %-8.4f', 'YOLOv2 Baseline', metricsV2.mAP);
rowV4 = sprintf('%-25s | %-8.4f', 'YOLOv4 Improved', metricsV4.mAP);
for i = 1:length(targetClasses)
    rowV2 = [rowV2 sprintf(' | %-14.4f', metricsV2.ClassMetrics.AP(i))]; %#ok<AGROW>
    rowV4 = [rowV4 sprintf(' | %-14.4f', metricsV4.ClassMetrics.AP(i))]; %#ok<AGROW>
end
fprintf('%s\n%s\n\n', rowV2, rowV4);

% Bar chart
figure('Name', 'mAP Comparison');
mAPValues = [metricsV2.mAP, metricsV4.mAP];
b = bar(mAPValues, 0.5);
b.FaceColor = 'flat';
b.CData = [0.2 0.4 0.8; 0.8 0.2 0.2];
set(gca,'XTickLabel',{'YOLOv2 Baseline','YOLOv4 Improved'});
ylabel('mAP @ IoU=0.5'); ylim([0 1]);
title('Comparacao de mAP entre Modelos'); grid on;
for i = 1:length(mAPValues)
    text(i, mAPValues(i)+0.02, sprintf('%.4f', mAPValues(i)), ...
        'HorizontalAlignment','center','FontWeight','bold','FontSize',11);
end


%% =========================================================
%  9. FINAL TEST SET EVALUATION
%% =========================================================

fprintf('--- 9. Avaliacao Final no Conjunto de Teste (YOLOv4) ---\n');

resultsTest = detect(detectorV4, imdsTest, ...
    'Threshold', detectionThreshold, 'SelectStrongest', true);
metricsTest = evaluateObjectDetection(resultsTest, bldsTest, 'IoUThreshold', 0.5);

printMetrics('YOLOv4 - Test Set', metricsTest, targetClasses);


%% =========================================================
%  10. QUALITATIVE RESULTS
%% =========================================================

fprintf('--- 10. Visualizacao de Detecoes no Teste ---\n');

numShow       = min(6, numTest);
imdsTestReset = reset(copy(imdsTest));
colorMap      = containers.Map(cellstr(targetClasses), {'red','green','blue'});

figure('Name','Detections on Test Images');
for k = 1:numShow
    img = read(imdsTestReset);
    if size(img,3) == 1, img = repmat(img,[1 1 3]); end

    [bboxes, scores, labels] = detect(detectorV4, img, ...
        'Threshold', detectionThreshold, 'SelectStrongest', true);

    subplot(2,3,k);
    imshow(img); hold on;
    for j = 1:size(bboxes,1)
        lbl = char(labels(j));
        c   = 'yellow';
        if isKey(colorMap, lbl), c = colorMap(lbl); end
        rectangle('Position', bboxes(j,:), 'EdgeColor', c, 'LineWidth', 2);
        text(bboxes(j,1), max(bboxes(j,2)-8,1), ...
            sprintf('%s %.2f', lbl, scores(j)), ...
            'Color','yellow','FontSize',8,'FontWeight','bold','BackgroundColor','black');
    end
    title(sprintf('Teste %d', k)); hold off;
end
sgtitle('Detecoes YOLOv4 - Conjunto de Teste');

fprintf('\n=== Pipeline Completo! ===\n');


%% =========================================================
%  LOCAL FUNCTIONS
%% =========================================================

function cocoData = loadCOCO(cocoPath)
    fid = fopen(cocoPath);
    if fid == -1
        error('Cannot open: %s', cocoPath);
    end
    raw = fread(fid, inf);
    str = char(raw');
    fclose(fid);
    cocoData = jsondecode(str);
end

% ------------------------------------------------------------------
function [combinedDS, numImages] = buildDatastore(datasetDir, targetClasses, allClassIDs, allClassNames) %#ok<INUSD>
% Build combined imageDatastore + boxLabelDatastore from a COCO JSON.
% Full debug output is printed to help diagnose path and class issues.

    fprintf('\n  [buildDatastore] %s\n', datasetDir);

    %% Resolve image folder
    imageDir = fullfile(datasetDir, 'data');
    if ~isfolder(imageDir)
        imageDir = datasetDir;          % fallback: images in root
    end
    fprintf('  Image folder : %s  [exists=%d]\n', imageDir, isfolder(imageDir));

    %% Load COCO JSON
    coco = loadCOCO(fullfile(datasetDir, 'coco.json'));

    %% Build category map
    catMap = containers.Map('KeyType','int32','ValueType','char');
    cocoNameList = {};
    for i = 1:length(coco.categories)
        catMap(coco.categories(i).id) = coco.categories(i).name;
        cocoNameList{end+1} = coco.categories(i).name; %#ok<AGROW>
    end
    fprintf('  COCO categories : %s\n', strjoin(cocoNameList,', '));

    % Check name overlap
    matched = intersect(targetClasses, string(cocoNameList));
    if isempty(matched)
        fprintf('\n  *** NO MATCH between targetClasses and COCO names! ***\n');
        fprintf('  targetClasses = [%s]\n', join(targetClasses,', '));
        fprintf('  COCO names    = [%s]\n', strjoin(cocoNameList,', '));
        fprintf('  --> Edit targetClasses in Section 0 to use the COCO names above.\n\n');
    else
        fprintf('  Matched       : %s\n', join(matched,', '));
    end

    %% Build image map
    imgMap = containers.Map('KeyType','int32','ValueType','char');
    for i = 1:length(coco.images)
        imgMap(coco.images(i).id) = coco.images(i).file_name;
    end
    fprintf('  Images in JSON: %d\n', length(coco.images));

    %% Detect whether filenames need basename-only lookup
    useBasenameOnly = false;
    if ~isempty(keys(imgMap))
        sid  = keys(imgMap); sid = sid{1};
        sfn  = imgMap(sid);
        sfull = fullfile(imageDir, sfn);
        [~,bn,ex] = fileparts(sfn);
        salt  = fullfile(imageDir, [bn ex]);
        fprintf('  Sample file in JSON : "%s"\n', sfn);
        fprintf('  Full path           : "%s"  [exists=%d]\n', sfull, isfile(sfull));
        if ~isfile(sfull) && isfile(salt)
            fprintf('  Basename path       : "%s"  [exists=%d]  <-- using this\n', salt, isfile(salt));
            useBasenameOnly = true;
        end
    end

    %% Group annotations by image_id
    annotsByImage = containers.Map('KeyType','int32','ValueType','any');
    anns = coco.annotations;
    matchCount = 0;
    for i = 1:length(anns)
        if iscell(anns), ann = anns{i}; else ann = anns(i); end
        if isKey(catMap, ann.category_id) && ...
           ismember(catMap(ann.category_id), targetClasses)
            matchCount = matchCount + 1;
        end
        key = ann.image_id;
        if ~isKey(annotsByImage, key)
            annotsByImage(key) = {ann};          % first: store as cell
        else
            existing = annotsByImage(key);
            if ~iscell(existing), existing = {existing}; end
            annotsByImage(key) = [existing, {ann}];
        end
    end
    fprintf('  Target annotations  : %d / %d total\n', matchCount, length(anns));

    %% Build entries
    imageFiles   = {};
    boxCells     = {};
    labelCells   = {};
    missingFiles = 0;
    noBoxes      = 0;

    imgIDs = keys(imgMap);
    for i = 1:length(imgIDs)
        imgID = imgIDs{i};
        fn    = imgMap(imgID);

        if useBasenameOnly
            [~,bn,ex] = fileparts(fn);
            fname = fullfile(imageDir, [bn ex]);
        else
            fname = fullfile(imageDir, fn);
        end

        if ~isfile(fname)
            missingFiles = missingFiles + 1;
            if missingFiles <= 3
                fprintf('  MISSING FILE: %s\n', fname);
            end
            continue;
        end

        boxes  = zeros(0,4);
        labels = {};

        if isKey(annotsByImage, imgID)
            annList = annotsByImage(imgID);   % retrieve once as local variable
            if ~iscell(annList)
                annList = {annList};          % wrap struct in cell if needed
            end
            for j = 1:length(annList)
                ann = annList{j};
                if ~isKey(catMap, ann.category_id), continue; end
                catName = catMap(ann.category_id);
                if ~ismember(catName, targetClasses), continue; end
                bbox = ann.bbox;              % [x y w h] COCO format
                boxes  = [boxes;  bbox(1), bbox(2), max(bbox(3),1), max(bbox(4),1)]; %#ok<AGROW>
                labels = [labels; {catName}]; %#ok<AGROW>
            end
        end

        if isempty(boxes), noBoxes = noBoxes + 1; continue; end

        imageFiles{end+1} = fname; %#ok<AGROW>
        boxCells{end+1}   = boxes; %#ok<AGROW>
        labelCells{end+1} = categorical(labels, cellstr(targetClasses)); %#ok<AGROW>
    end

    fprintf('  Missing files : %d | No-target : %d | Valid : %d\n', ...
        missingFiles, noBoxes, length(imageFiles));

    if isempty(boxCells)
        error(['buildDatastore failed for "%s".\n' ...
               'See debug output above. Most likely causes:\n' ...
               '  1. targetClasses names do not match COCO category names\n' ...
               '  2. Image files not found at expected path\n' ...
               '  3. Image folder is not "data/" - check what folder your images are in'], ...
               datasetDir);
    end

    numImages  = length(imageFiles);
    imds       = imageDatastore(imageFiles, 'ReadFcn', @readThermalImage);
    blds       = boxLabelDatastore(table(boxCells', labelCells', ...
                     'VariableNames', {'Boxes','Labels'}));
    combinedDS = combine(imds, blds);
    fprintf('  Datastore built successfully: %d images.\n', numImages);
end

% ------------------------------------------------------------------
function img = readThermalImage(filename)
    img = imread(filename);
    if size(img,3) == 1
        img = repmat(img,[1 1 3]);
    elseif size(img,3) == 4
        img = img(:,:,1:3);
    end
    if ~isa(img,'uint8')
        img = im2uint8(img);
    end
    % CLAHE per channel
    for c = 1:3
        img(:,:,c) = adapthisteq(img(:,:,c));
    end
end

% ------------------------------------------------------------------
function dataOut = augmentThermal(data)
    img    = data{1};
    boxes  = data{2};
    labels = data{3};

    % Horizontal flip
    if rand > 0.5
        imgW       = size(img,2);
        img        = fliplr(img);
        boxes(:,1) = max(imgW - boxes(:,1) - boxes(:,3), 0);
    end

    % Brightness jitter
    delta = int16(img) + int16(randi([-20 20]));
    img   = uint8(max(0, min(255, delta)));

    % Scale jitter
    sf   = 0.9 + 0.2*rand;
    newH = max(round(size(img,1)*sf), 32);
    newW = max(round(size(img,2)*sf), 32);
    img  = imresize(img, [newH newW]);

    boxes(:,1) = max(boxes(:,1)*sf, 0);
    boxes(:,2) = max(boxes(:,2)*sf, 0);
    boxes(:,3) = min(boxes(:,3)*sf, newW - boxes(:,1));
    boxes(:,4) = min(boxes(:,4)*sf, newH - boxes(:,2));

    valid  = boxes(:,3) > 2 & boxes(:,4) > 2;
    boxes  = boxes(valid,:);
    labels = labels(valid);

    dataOut = {img, boxes, labels};
end

% ------------------------------------------------------------------
function printMetrics(modelName, metrics, targetClasses)
    fprintf('\n  === %s ===\n', modelName);
    fprintf('  mAP @ IoU=0.5 : %.4f\n', metrics.mAP);
    for i = 1:length(targetClasses)
        fprintf('  AP  %-12s: %.4f\n', targetClasses(i), metrics.ClassMetrics.AP(i));
    end
    fprintf('\n');
end