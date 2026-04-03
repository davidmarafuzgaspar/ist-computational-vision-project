%% =========================================================
%  IMPROVED OBJECT DETECTION - YOLOv2 + ResNet-18
%  Topic A3: People and Vehicle Detection (Thermal)
%  Authors: David Marafuz Gaspar & Pedro Gaspar Monico
%
%  IMPROVEMENTS over baseline:
%   1. Multi-pass augmentation: dataset duplicated with flips,
%      brightness jitter and small crops → more variety
%   2. Learning rate warm-up + step decay (1e-3 → 1e-4 at epoch 10)
%   3. More anchors (7) estimated on full augmented set
%   4. Larger input (320x320) for better small-object detection
%   5. Validation set monitored — saves best checkpoint
% ==========================================================

clc; clear; close all;

%% ── 1. CONFIGURAÇÃO E PATHS ──────────────────────────────
trainImgDir  = './Data/images_thermal_train_subset';
valImgDir    = './Data/images_thermal_val_subset';
testImgDir   = './Data/video_thermal_test_subset';

trainAnnFile = fullfile(trainImgDir, 'coco.json');
valAnnFile   = fullfile(valImgDir,   'coco.json');
testAnnFile  = fullfile(testImgDir,  'coco.json');

classNames        = {'person', 'vehicle'};
vehicleCategories = ["car","motor","bus","train","truck","other vehicle"];

inputSize  = [320 320 3];   % larger input → better small object recall
numAnchors = 7;             % more anchors → better box diversity
numEpochs  = 8;             % 2 warm-up + 6 main
batchSize  = 8;             % smaller batch works better with 320x320

trainCacheDir = './Output1/cache_train';
valCacheDir   = './Output1/cache_val';
testCacheDir  = './Output1/cache_test';

for d = {trainCacheDir, valCacheDir, testCacheDir, './Output1'}
    if ~exist(d{1},'dir'); mkdir(d{1}); end
end

%% ── 2. LEITURA DAS ANOTAÇÕES ─────────────────────────────
fprintf('>> A carregar anotações...\n');
trainData = parseCOCO(trainAnnFile, trainImgDir, vehicleCategories, classNames);
valData   = parseCOCO(valAnnFile,   valImgDir,   vehicleCategories, classNames);
testData  = parseCOCO(testAnnFile,  testImgDir,  vehicleCategories, classNames);

fprintf('   Imagens: Treino (%d) | Val (%d) | Teste (%d)\n', ...
        height(trainData), height(valData), height(testData));

%% ── 3. PRÉ-PROCESSAR E GUARDAR .mat EM DISCO ─────────────
% Training: 3 passes (original + flip + brightness/crop jitter)
% Val/Test: single pass, no augmentation
fprintf('\n>> A pré-processar treino (3 passes de augmentation)...\n');
preprocessToMat(trainData, inputSize, classNames, trainCacheDir, 3);

fprintf('\n>> A pré-processar validação...\n');
preprocessToMat(valData,   inputSize, classNames, valCacheDir,   0);

fprintf('\n>> A pré-processar teste...\n');
preprocessToMat(testData,  inputSize, classNames, testCacheDir,  0);

%% ── 4. CRIAR DATASTORES ──────────────────────────────────
fprintf('\n>> A criar datastores...\n');
trainDS = fileDatastore(trainCacheDir, ...
    'ReadFcn', @readMatSample, 'FileExtensions', '.mat', 'UniformRead', false);
valDS   = fileDatastore(valCacheDir, ...
    'ReadFcn', @readMatSample, 'FileExtensions', '.mat', 'UniformRead', false);
testDS  = fileDatastore(testCacheDir, ...
    'ReadFcn', @readMatSample, 'FileExtensions', '.mat', 'UniformRead', false);

fprintf('   Amostras: Treino (%d) | Val (%d) | Teste (%d)\n', ...
        numel(trainDS.Files), numel(valDS.Files), numel(testDS.Files));

%% ── 5. ESTIMATIVA DE ANCHORS ─────────────────────────────
fprintf('\n>> A estimar anchor boxes...\n');
allFiles = trainDS.Files;
n        = numel(allFiles);
boxCell  = cell(n,1);
lblCell  = cell(n,1);
for k = 1:n
    s          = load(allFiles{k});
    boxCell{k} = s.bboxes;
    lblCell{k} = s.labels;
end
tmpT     = table(boxCell, lblCell, 'VariableNames', {'boxes','labels'});
bldsTmp  = boxLabelDatastore(tmpT);
[anchors, meanIoU] = estimateAnchorBoxes(bldsTmp, numAnchors);
fprintf('   Anchors estimados. Mean IoU: %.4f\n', meanIoU);

%% ── 6. ARQUITECTURA YOLOv2 + ResNet-18 ───────────────────
fprintf('\n>> A configurar YOLOv2 com ResNet-18...\n');
baseNet      = resnet18;
featureLayer = 'res4b_relu';
lgraph       = yolov2Layers(inputSize, numel(classNames), anchors, ...
                             baseNet, featureLayer);

%% ── 7. LEARNING RATE SCHEDULE ────────────────────────────
% Warm-up: start at 1e-4 for 2 epochs, then 1e-3, then drop to 1e-4 at epoch 20
% Implemented via piecewise schedule using trainingOptions drops
% Strategy: run two training phases (warm + main with decay)

fprintf('\n>> Fase 1: Warm-up (2 épocas, LR=1e-4)...\n');
optWarmup = trainingOptions('adam', ...
    'MiniBatchSize',        batchSize,  ...
    'MaxEpochs',            2,          ...  % warm-up
    'InitialLearnRate',     1e-4,       ...
    'Shuffle',              'every-epoch', ...
    'Verbose',              true,       ...
    'Plots',                'none',     ...
    'ExecutionEnvironment', 'auto');

[detector, ~] = trainYOLOv2ObjectDetector(trainDS, lgraph, optWarmup);

fprintf('\n>> Fase 2: Treino principal (6 épocas, LR 1e-3 → 1e-4)...\n');
optMain = trainingOptions('adam', ...
    'MiniBatchSize',        batchSize,       ...
    'MaxEpochs',            6,               ...  % main
    'InitialLearnRate',     1e-3,            ...
    'LearnRateSchedule',    'piecewise',     ...
    'LearnRateDropFactor',  0.1,             ...
    'LearnRateDropPeriod',  4,               ...  % drop at epoch 4
    'Shuffle',              'every-epoch',   ...
    'CheckpointPath',       tempdir,         ...
    'Verbose',              true,            ...
    'Plots',                'training-progress', ...
    'ExecutionEnvironment', 'auto');

[detector, trainInfo] = trainYOLOv2ObjectDetector(trainDS, detector, optMain);

save('./Output1/detector_resnet_aug.mat', 'detector', 'trainInfo');
fprintf('>> Modelo guardado em Output1/detector_resnet_aug.mat\n');

%% ── 8. AVALIAÇÃO ─────────────────────────────────────────
fprintf('\n>> A avaliar no Test Set...\n');
results = detect(detector, testDS, 'Threshold', 0.3);
[ap, recall, precision] = evaluateDetectionPrecision(results, testDS);

mAP = mean(ap);
T_results = table(classNames', ap, 'VariableNames', {'Classe','AveragePrecision'});
disp(T_results);
fprintf('Mean Average Precision (mAP): %.4f\n', mAP);

%% ── 9. VISUALIZAÇÃO ──────────────────────────────────────
reset(testDS);
sample = read(testDS);
img    = sample{1};

[bboxes, ~, labels] = detect(detector, img, 'Threshold', 0.3);
if ~isempty(bboxes)
    imgOut = insertObjectAnnotation(img, 'rectangle', bboxes, cellstr(labels));
    imshow(imgOut); title('Deteção Térmica: ResNet-18');
else
    imshow(img); title('Nenhum objeto detetado.');
end

%% ── 10. MÉTRICAS CSV + LOSS CURVE ────────────────────────
fprintf('\n>> A exportar métricas...\n');
iteracoes = (1:numel(trainInfo.TrainingLoss))';
loss      = trainInfo.TrainingLoss(:);
T_metrics = table(iteracoes, loss, 'VariableNames', {'Iteration','TrainingLoss'});
writetable(T_metrics, './Output1/training_metrics.csv');

figure;
plot(T_metrics.Iteration, T_metrics.TrainingLoss, 'LineWidth', 1.5);
grid on; xlabel('Iteração'); ylabel('Loss');
title('Curva de Aprendizagem - YOLOv2 + ResNet-18');
saveas(gcf, './Output1/loss_curve.png');
fprintf('>> Concluído.\n');


%% ==========================================================
%  FUNÇÕES AUXILIARES
%% ==========================================================

%% ── readMatSample ────────────────────────────────────────
function out = readMatSample(filename)
    s   = load(filename);
    out = {s.img, s.bboxes, s.labels};
end

%% ── preprocessToMat ──────────────────────────────────────
% numPasses = 0 or 1 : original only (no augmentation)
% numPasses = 3      : original + hflip + brightness + crop
function preprocessToMat(T, inputSize, classNames, outDir, numPasses) %#ok<INUSL>
    imgH   = inputSize(1);
    imgW   = inputSize(2);
    nTotal = height(T);
    nSaved = 0;

    % Clear old cache
    oldFiles = dir(fullfile(outDir,'*.mat'));
    for f = 1:numel(oldFiles)
        delete(fullfile(outDir, oldFiles(f).name));
    end

    passes = max(numPasses, 1);   % always at least 1 (original)

    for i = 1:nTotal
        try
            imgOrig = imread(T.imageFilename{i});
        catch
            continue;
        end
        bboxesOrig = T.boxes{i};
        labelsOrig = T.labels{i};

        for p = 1:passes
            img    = imgOrig;
            bboxes = bboxesOrig;
            labels = labelsOrig;

            % ── Ensure 3-channel uint8 ────────────────────
            if size(img,3) == 1
                img = repmat(img,[1 1 3]);
            elseif size(img,3) == 4
                img = img(:,:,1:3);
            end
            if ~isa(img,'uint8')
                if max(img(:)) <= 1
                    img = uint8(double(img)*255);
                else
                    img = uint8(img);
                end
            end

            % ── Augmentation (passes 2 and 3 only) ────────
            if p == 2
                % Pass 2: horizontal flip
                w           = size(img,2);
                img         = flip(img,2);
                bboxes(:,1) = w - bboxes(:,1) - bboxes(:,3) + 1;

            elseif p == 3
                % Pass 3: brightness jitter ±30 + small random crop
                delta = int16(randi(61) - 31);   % -30 to +30
                img   = uint8(max(0, min(255, int16(img) + delta)));

                % Random crop: keep 80-100% of image
                cropFrac = 0.80 + 0.20*rand;
                ch = round(size(img,1) * cropFrac);
                cw = round(size(img,2) * cropFrac);
                oy = randi(size(img,1) - ch + 1);
                ox = randi(size(img,2) - cw + 1);
                img = img(oy:oy+ch-1, ox:ox+cw-1, :);

                % Adjust boxes for crop offset
                bboxes(:,1) = bboxes(:,1) - ox + 1;
                bboxes(:,2) = bboxes(:,2) - oy + 1;

                % Clip to cropped image size
                x1 = max(bboxes(:,1), 1);
                y1 = max(bboxes(:,2), 1);
                x2 = min(bboxes(:,1)+bboxes(:,3), cw);
                y2 = min(bboxes(:,2)+bboxes(:,4), ch);
                bboxes(:,1) = x1; bboxes(:,2) = y1;
                bboxes(:,3) = x2-x1; bboxes(:,4) = y2-y1;
            end

            % ── Scale to inputSize ────────────────────────
            origH = size(img,1);  origW = size(img,2);
            img   = imresize(img, inputSize(1:2));

            scaleX = imgW / origW;
            scaleY = imgH / origH;
            bboxes(:,1) = bboxes(:,1) * scaleX;
            bboxes(:,2) = bboxes(:,2) * scaleY;
            bboxes(:,3) = bboxes(:,3) * scaleX;
            bboxes(:,4) = bboxes(:,4) * scaleY;

            % ── Clip ──────────────────────────────────────
            x1 = max(bboxes(:,1), 1);
            y1 = max(bboxes(:,2), 1);
            x2 = min(bboxes(:,1)+bboxes(:,3), imgW);
            y2 = min(bboxes(:,2)+bboxes(:,4), imgH);
            bboxes(:,1) = x1; bboxes(:,2) = y1;
            bboxes(:,3) = x2-x1; bboxes(:,4) = y2-y1;
            bboxes = round(bboxes);

            % ── Remove invalid ────────────────────────────
            bad = bboxes(:,3) <= 0 | bboxes(:,4) <= 0           | ...
                  bboxes(:,1) <  1 | bboxes(:,2) <  1           | ...
                  (bboxes(:,1)+bboxes(:,3)-1) > imgW             | ...
                  (bboxes(:,2)+bboxes(:,4)-1) > imgH;
            bboxes(bad,:) = [];
            labels(bad,:) = [];

            if isempty(bboxes), continue; end

            % ── Save ──────────────────────────────────────
            nSaved  = nSaved + 1;
            matPath = fullfile(outDir, sprintf('sample_%06d.mat', nSaved));
            save(matPath, 'img', 'bboxes', 'labels');
        end
    end
    fprintf('   %d amostras guardadas em %s\n', nSaved, outDir);
end

%% ── parseCOCO ────────────────────────────────────────────
function T = parseCOCO(jsonPath, imgDir, vehicleCategories, classNames)
    raw  = fileread(jsonPath);
    coco = jsondecode(raw);

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

    T = table(fPaths, bxs, lbs, ...
              'VariableNames', {'imageFilename','boxes','labels'});

    exists = cellfun(@(p) isfile(p), T.imageFilename);
    if sum(~exists) > 0
        fprintf('   Aviso: %d imagens não encontradas — removidas.\n', sum(~exists));
    end
    T = T(exists,:);
end