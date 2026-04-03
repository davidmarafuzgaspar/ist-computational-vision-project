%% =========================================================
%  IMPROVED OBJECT DETECTION - YOLOv2 + ResNet-18
%  Topic A3: People and Vehicle Detection (Thermal)
%  Authors: David Marafuz Gaspar & Pedro Gaspar Monico
%
%  FIX: Pre-processes all images to .mat files on disk.
%  A fileDatastore + custom read function returns exactly
%  the 1x3 cell {img, boxes, labels} that MATLAB requires.
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

inputSize  = [224 224 3];
numAnchors = 5;
numEpochs  = 15;
batchSize  = 16;

trainCacheDir = './Output/cache_train';
testCacheDir  = './Output/cache_test';

if ~exist('./Output','dir');     mkdir('./Output');     end
if ~exist(trainCacheDir,'dir'); mkdir(trainCacheDir); end
if ~exist(testCacheDir,'dir');  mkdir(testCacheDir);  end

%% ── 2. LEITURA DAS ANOTAÇÕES (COCO -> Table) ─────────────
fprintf('>> A carregar anotações...\n');
trainData = parseCOCO(trainAnnFile, trainImgDir, vehicleCategories, classNames);
valData   = parseCOCO(valAnnFile,   valImgDir,   vehicleCategories, classNames);
testData  = parseCOCO(testAnnFile,  testImgDir,  vehicleCategories, classNames);

fprintf('   Imagens: Treino (%d) | Val (%d) | Teste (%d)\n', ...
        height(trainData), height(valData), height(testData));

%% ── 3. PRÉ-PROCESSAR E GUARDAR .mat EM DISCO ─────────────
% Each .mat file contains: img (uint8 HxWx3), boxes (Nx4), labels (Nx1 categorical)
% The fileDatastore reads these and returns exactly {img, boxes, labels}.
fprintf('\n>> A pré-processar e guardar treino em disco...\n');
preprocessToMat(trainData, inputSize, classNames, trainCacheDir, true);

fprintf('\n>> A pré-processar e guardar teste em disco...\n');
preprocessToMat(testData,  inputSize, classNames, testCacheDir,  false);

%% ── 4. CRIAR DATASTORES A PARTIR DOS .mat ────────────────
fprintf('\n>> A criar datastores...\n');
trainDS = fileDatastore(trainCacheDir, ...
    'ReadFcn',    @readMatSample, ...
    'FileExtensions', '.mat', ...
    'UniformRead', false);

testDS = fileDatastore(testCacheDir, ...
    'ReadFcn',    @readMatSample, ...
    'FileExtensions', '.mat', ...
    'UniformRead', false);

fprintf('   Amostras: Treino (%d) | Teste (%d)\n', ...
        numel(trainDS.Files), numel(testDS.Files));

%% ── 5. ESTIMATIVA DE ANCHORS ─────────────────────────────
fprintf('\n>> A estimar anchor boxes...\n');
allFiles = trainDS.Files;
n        = numel(allFiles);
boxCell  = cell(n,1);
lblCell  = cell(n,1);
for k = 1:n
    s         = load(allFiles{k});
    boxCell{k} = s.bboxes;
    lblCell{k} = s.labels;
end
tmpT     = table(boxCell, lblCell, 'VariableNames', {'boxes','labels'});
bldsTmp  = boxLabelDatastore(tmpT);
[anchors, ~] = estimateAnchorBoxes(bldsTmp, numAnchors);
fprintf('   Anchors estimados.\n');

%% ── 6. ARQUITECTURA YOLOv2 + ResNet-18 ───────────────────
fprintf('\n>> A configurar YOLOv2 com ResNet-18...\n');
baseNet      = resnet18;
featureLayer = 'res4b_relu';
lgraph       = yolov2Layers(inputSize, numel(classNames), anchors, ...
                             baseNet, featureLayer);

%% ── 7. OPÇÕES DE TREINO ──────────────────────────────────
options = trainingOptions('adam', ...
    'MiniBatchSize',        batchSize,           ...
    'MaxEpochs',            numEpochs,           ...
    'InitialLearnRate',     1e-3,                ...
    'Shuffle',              'every-epoch',       ...
    'CheckpointPath',       tempdir,             ...
    'Verbose',              true,                ...
    'Plots',                'training-progress', ...
    'ExecutionEnvironment', 'auto');

%% ── 8. TREINO ────────────────────────────────────────────
fprintf('\n>> A iniciar treino...\n');
[detector, trainInfo] = trainYOLOv2ObjectDetector(trainDS, lgraph, options);

save('./Output/detector_resnet_aug.mat', 'detector', 'trainInfo');
fprintf('>> Modelo guardado em Output/detector_resnet_aug.mat\n');

%% ── 9. AVALIAÇÃO ─────────────────────────────────────────
fprintf('\n>> A avaliar no Test Set...\n');
results = detect(detector, testDS, 'Threshold', 0.3);
[ap, recall, precision] = evaluateDetectionPrecision(results, testDS);

mAP = mean(ap);
T_results = table(classNames', ap, 'VariableNames', {'Classe','AveragePrecision'});
disp(T_results);
fprintf('Mean Average Precision (mAP): %.4f\n', mAP);

%% ── 10. VISUALIZAÇÃO ─────────────────────────────────────
reset(testDS);
sample = read(testDS);      % returns {img, boxes, labels}
img    = sample{1};

[bboxes, ~, labels] = detect(detector, img, 'Threshold', 0.4);
if ~isempty(bboxes)
    imgOut = insertObjectAnnotation(img, 'rectangle', bboxes, cellstr(labels));
    imshow(imgOut); title('Deteção Térmica: ResNet-18');
else
    imshow(img); title('Nenhum objeto detetado.');
end

%% ── 11. MÉTRICAS CSV + LOSS CURVE ────────────────────────
fprintf('\n>> A exportar métricas...\n');
iteracoes = (1:numel(trainInfo.TrainingLoss))';
loss      = trainInfo.TrainingLoss(:);
T_metrics = table(iteracoes, loss, 'VariableNames', {'Iteration','TrainingLoss'});
writetable(T_metrics, './Output/training_metrics.csv');

figure;
plot(T_metrics.Iteration, T_metrics.TrainingLoss, 'LineWidth', 1.5);
grid on; xlabel('Iteração'); ylabel('Loss');
title('Curva de Aprendizagem - YOLOv2 + ResNet-18');
saveas(gcf, './Output/loss_curve.png');
fprintf('>> Concluído.\n');


%% ==========================================================
%  FUNÇÕES AUXILIARES
%% ==========================================================

%% ── readMatSample ────────────────────────────────────────
% ReadFcn for fileDatastore.
% Returns exactly {img, boxes, labels} — a 1x3 cell row.
function out = readMatSample(filename)
    s   = load(filename);          % loads img, boxes, labels
    out = {s.img, s.bboxes, s.labels};
end

%% ── preprocessToMat ──────────────────────────────────────
% Processes every image in table T, validates boxes, and
% saves each valid sample as an individual .mat file.
function preprocessToMat(T, inputSize, classNames, outDir, doAugment) %#ok<INUSL>
    imgH = inputSize(1);
    imgW = inputSize(2);
    nTotal  = height(T);
    nSaved  = 0;

    % Clear old cache to avoid stale samples
    oldFiles = dir(fullfile(outDir,'*.mat'));
    for f = 1:numel(oldFiles)
        delete(fullfile(outDir, oldFiles(f).name));
    end

    for i = 1:nTotal
        try
            img = imread(T.imageFilename{i});
        catch
            continue;
        end
        bboxes = T.boxes{i};
        labels = T.labels{i};

        % ── Ensure 3-channel uint8 ────────────────────────
        if size(img,3) == 1
            img = repmat(img,[1 1 3]);
        elseif size(img,3) == 4
            img = img(:,:,1:3);
        end
        if ~isa(img,'uint8')
            if max(img(:)) <= 1
                img = uint8(double(img) * 255);
            else
                img = uint8(img);
            end
        end

        % ── Random horizontal flip (train only) ───────────
        if doAugment && rand > 0.5
            w           = size(img,2);
            img         = flip(img,2);
            bboxes(:,1) = w - bboxes(:,1) - bboxes(:,3) + 1;
        end

        % ── Scale boxes ───────────────────────────────────
        origH = size(img,1);
        origW = size(img,2);
        img   = imresize(img, inputSize(1:2));

        scaleX = imgW / origW;
        scaleY = imgH / origH;
        bboxes(:,1) = bboxes(:,1) * scaleX;
        bboxes(:,2) = bboxes(:,2) * scaleY;
        bboxes(:,3) = bboxes(:,3) * scaleX;
        bboxes(:,4) = bboxes(:,4) * scaleY;

        % ── Clip (corner representation) ──────────────────
        x1 = bboxes(:,1);  y1 = bboxes(:,2);
        x2 = x1 + bboxes(:,3);
        y2 = y1 + bboxes(:,4);

        x1 = max(x1, 1);    y1 = max(y1, 1);
        x2 = min(x2, imgW); y2 = min(y2, imgH);

        bboxes(:,1) = x1;       bboxes(:,2) = y1;
        bboxes(:,3) = x2 - x1; bboxes(:,4) = y2 - y1;

        % ── Round to integers ─────────────────────────────
        bboxes = round(bboxes);

        % ── Remove invalid boxes ──────────────────────────
        bad = bboxes(:,3) <= 0 | bboxes(:,4) <= 0           | ...
              bboxes(:,1) <  1 | bboxes(:,2) <  1           | ...
              (bboxes(:,1) + bboxes(:,3) - 1) > imgW        | ...
              (bboxes(:,2) + bboxes(:,4) - 1) > imgH;
        bboxes(bad,:) = [];
        labels(bad,:) = [];

        if isempty(bboxes), continue; end

        % ── Save to .mat ───────────────────────────────────
        nSaved  = nSaved + 1;
        matPath = fullfile(outDir, sprintf('sample_%05d.mat', nSaved));
        save(matPath, 'img', 'bboxes', 'labels');
    end

    fprintf('   %d / %d amostras válidas guardadas em %s\n', nSaved, nTotal, outDir);
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