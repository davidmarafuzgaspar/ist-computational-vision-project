%% =========================================================================
%% Computation Vision - Project 2
%% Topic A3: People and Vehicle Detection Using Thermal Imagery
%% Authors:
%%   David Marafuz Gaspar - 106541
%%   Pedro Gaspar Monico  - 106626
%%
%%  BASELINE MODEL - Simples, sem augmentation
%% =========================================================================

clc; clear; close all;

%% ── 1. PATHS ─────────────────────────────────────────────
trainImgDir = './Data/images_thermal_train_subset';
valImgDir   = './Data/images_thermal_val_subset';
testImgDir  = './Data/video_thermal_test_subset';

trainAnnFile = fullfile(trainImgDir, 'coco.json');
valAnnFile   = fullfile(valImgDir,   'coco.json');
testAnnFile  = fullfile(testImgDir,  'coco.json');

classNames        = {'person', 'vehicle'};
vehicleCategories = ["car","motor","bus","train","truck","other vehicle"];

inputSize  = [224 224 3];
numAnchors = 6;
batchSize  = 8;
numEpochs  = 10;

cacheDir = './Output_baseline';
trainCacheDir = fullfile(cacheDir, 'train');
valCacheDir   = fullfile(cacheDir, 'val');
testCacheDir  = fullfile(cacheDir, 'test');
for d = {cacheDir, trainCacheDir, valCacheDir, testCacheDir}
    if ~exist(d{1},'dir'); mkdir(d{1}); end
end

%% ── 2. CARREGAR ANOTAÇÕES ────────────────────────────────
fprintf('>> A carregar anotações...\n');
trainData = parseCOCO(trainAnnFile, trainImgDir, vehicleCategories, classNames);
valData   = parseCOCO(valAnnFile,   valImgDir,   vehicleCategories, classNames);
testData  = parseCOCO(testAnnFile,  testImgDir,  vehicleCategories, classNames);
fprintf('   Treino: %d | Val: %d | Teste: %d imagens\n', ...
    height(trainData), height(valData), height(testData));

%% ── 3. PRÉ-PROCESSAR PARA .mat ───────────────────────────
fprintf('\n>> A pré-processar imagens...\n');
preprocessToMat(trainData, inputSize, trainCacheDir);
preprocessToMat(valData,   inputSize, valCacheDir);
preprocessToMat(testData,  inputSize, testCacheDir);

%% ── 4. DATASTORES ────────────────────────────────────────
fprintf('\n>> A criar datastores...\n');
trainDS = fileDatastore(trainCacheDir, 'ReadFcn', @readMatSample, ...
    'FileExtensions', '.mat', 'UniformRead', false);
valDS   = fileDatastore(valCacheDir,   'ReadFcn', @readMatSample, ...
    'FileExtensions', '.mat', 'UniformRead', false);
testDS  = fileDatastore(testCacheDir,  'ReadFcn', @readMatSample, ...
    'FileExtensions', '.mat', 'UniformRead', false);
fprintf('   Treino: %d | Val: %d | Teste: %d amostras\n', ...
    numel(trainDS.Files), numel(valDS.Files), numel(testDS.Files));

%% ── 5. ANCHOR BOXES ──────────────────────────────────────
fprintf('\n>> A estimar anchor boxes...\n');
allFiles = trainDS.Files;
boxCell  = cell(numel(allFiles), 1);
lblCell  = cell(numel(allFiles), 1);
for k = 1:numel(allFiles)
    s = load(allFiles{k});
    boxCell{k} = s.bboxes;
    lblCell{k} = s.labels;
end
tmpT    = table(boxCell, lblCell, 'VariableNames', {'boxes','labels'});
bldsTmp = boxLabelDatastore(tmpT);
[anchors, meanIoU] = estimateAnchorBoxes(bldsTmp, numAnchors);
% remover anchors inválidas
anchors = anchors(all(anchors > 0, 2), :);
fprintf('   Mean IoU: %.4f | Anchors válidas: %d\n', meanIoU, size(anchors,1));

%% ── 6. REDE YOLOv2 + ResNet-18 ──────────────────────────
fprintf('\n>> A criar rede YOLOv2 + ResNet-18...\n');
baseNet = resnet18;  % carrega o objeto da rede
lgraph  = yolov2Layers(inputSize, numel(classNames), anchors, ...
    baseNet, 'res4b_relu');
fprintf('   Rede criada.\n');

%% ── 7. TREINO ────────────────────────────────────────────
fprintf('\n>> A treinar...\n');
options = trainingOptions('sgdm',                    ...
    'InitialLearnRate',    1e-3,                     ...
    'LearnRateSchedule',   'piecewise',              ...
    'LearnRateDropFactor', 0.1,                      ...
    'LearnRateDropPeriod', 5,                        ...
    'Momentum',            0.9,                      ...
    'L2Regularization',    0.0005,                   ...
    'MaxEpochs',           numEpochs,                ...
    'MiniBatchSize',       batchSize,                ...
    'Shuffle',             'every-epoch',            ...
    'ValidationData',      valDS,                    ...
    'ValidationFrequency', 50,                       ...
    'ValidationPatience',  3,                        ...
    'Verbose',             true,                     ...
    'VerboseFrequency',    20,                       ...
    'Plots',               'training-progress',      ...
    'ExecutionEnvironment','auto');

[detector, trainInfo] = trainYOLOv2ObjectDetector(trainDS, lgraph, options);
save(fullfile(cacheDir, 'detector_baseline.mat'), 'detector', 'trainInfo');
fprintf('>> Modelo guardado.\n');

%% ── 8. AVALIAÇÃO ─────────────────────────────────────────
fprintf('\n>> A avaliar no teste...\n');
results = detect(detector, testDS, 'Threshold', 0.3);
[ap, ~, ~] = evaluateDetectionPrecision(results, testDS);
mAP = mean(ap);
T_ap = table(classNames', ap, 'VariableNames', {'Classe','AP'});
disp(T_ap);
fprintf('mAP: %.4f\n', mAP);

%% ── 9. VISUALIZAÇÃO ──────────────────────────────────────
reset(testDS);
sample = read(testDS);
img    = sample{1};
[bboxes, ~, labels] = detect(detector, img, 'Threshold', 0.3);
figure;
if ~isempty(bboxes)
    imshow(insertObjectAnnotation(img,'rectangle',bboxes,cellstr(labels)));
else
    imshow(img);
end
title('Baseline - Deteção Térmica');

%% ── 10. LOSS CURVE ───────────────────────────────────────
figure;
plot(trainInfo.TrainingLoss, 'LineWidth', 1.5);
grid on; xlabel('Iteração'); ylabel('Loss');
title('Curva de Loss - Baseline YOLOv2');
saveas(gcf, fullfile(cacheDir, 'loss_curve_baseline.png'));

%% ==========================================================
%%  FUNÇÕES AUXILIARES
%% ==========================================================

function out = readMatSample(filename)
    s   = load(filename);
    out = {s.img, s.bboxes, s.labels};
end

function preprocessToMat(T, inputSize, outDir)
% Sem augmentation — só resize e conversão para 3 canais
    oldFiles = dir(fullfile(outDir,'*.mat'));
    for f = 1:numel(oldFiles)
        delete(fullfile(outDir, oldFiles(f).name));
    end
    imgH = inputSize(1); imgW = inputSize(2);
    nSaved = 0;
    for i = 1:height(T)
        try; img = imread(T.imageFilename{i}); catch; continue; end
        bboxes = T.boxes{i};
        labels = T.labels{i};

        % Garantir 3 canais uint8
        if size(img,3) == 1,  img = repmat(img,[1 1 3]); end
        if size(img,3) == 4,  img = img(:,:,1:3); end
        if ~isa(img,'uint8')
            if max(img(:)) <= 1, img = uint8(double(img)*255);
            else, img = uint8(img); end
        end

        % Resize e escalar boxes
        origH = size(img,1); origW = size(img,2);
        img   = imresize(img, inputSize(1:2));
        bboxes(:,1) = bboxes(:,1) * (imgW/origW);
        bboxes(:,2) = bboxes(:,2) * (imgH/origH);
        bboxes(:,3) = bboxes(:,3) * (imgW/origW);
        bboxes(:,4) = bboxes(:,4) * (imgH/origH);
        bboxes = round(bboxes);

        % Remover boxes inválidas
        bad = bboxes(:,3)<=0 | bboxes(:,4)<=0 | bboxes(:,1)<1 | bboxes(:,2)<1;
        bboxes(bad,:) = []; labels(bad,:) = [];
        if isempty(bboxes), continue; end

        nSaved  = nSaved + 1;
        matPath = fullfile(outDir, sprintf('sample_%06d.mat', nSaved));
        save(matPath, 'img', 'bboxes', 'labels');
    end
    fprintf('   %d amostras guardadas em %s\n', nSaved, outDir);
end

function T = parseCOCO(jsonPath, imgDir, vehicleCategories, classNames)
    coco = jsondecode(fileread(jsonPath));

    imgMap = containers.Map('KeyType','double','ValueType','any');
    for i = 1:numel(coco.images)
        imgMap(double(coco.images(i).id)) = coco.images(i);
    end

    catMap = containers.Map('KeyType','double','ValueType','char');
    for i = 1:numel(coco.categories)
        cat  = coco.categories(i);
        name = lower(strtrim(cat.name));
        if strcmp(name,'person')
            catMap(double(cat.id)) = 'person';
        elseif any(strcmp(name, vehicleCategories))
            catMap(double(cat.id)) = 'vehicle';
        end
    end

    boxMap   = containers.Map('KeyType','double','ValueType','any');
    labelMap = containers.Map('KeyType','double','ValueType','any');
    for k = 1:numel(coco.annotations)
        ann = coco.annotations(k);
        if ~isKey(catMap, double(ann.category_id)), continue; end
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

    ids    = keys(boxMap);
    fPaths = cell(numel(ids),1);
    bxs    = cell(numel(ids),1);
    lbs    = cell(numel(ids),1);
    for i = 1:numel(ids)
        id        = ids{i};
        meta      = imgMap(id);
        fPaths{i} = fullfile(imgDir, meta.file_name);
        bxs{i}    = boxMap(id);
        lbs{i}    = labelMap(id);
    end

    T = table(fPaths, bxs, lbs, 'VariableNames', {'imageFilename','boxes','labels'});
    exists = cellfun(@(p) isfile(p), T.imageFilename);
    if sum(~exists) > 0
        fprintf('   Aviso: %d imagens não encontradas — removidas.\n', sum(~exists));
    end
    T = T(exists,:);
end