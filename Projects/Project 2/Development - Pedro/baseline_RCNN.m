%% =========================================================================
%% Computation Vision - Project 2
%% Topic A3: People and Vehicle Detection Using Thermal Imagery
%% Authors:
%%   David Marafuz Gaspar - 106541
%%   Pedro Gaspar Monico  - 106626
%%
%% CONTENTS:
%%   Section 2   - Dataset Analysis & Preparation
%%   Section 3   - Build Datastores
%%   Section 4   - DL Baseline: Faster R-CNN (ResNet-50)
%%
%% REQUIREMENTS:
%%   - Computer Vision Toolbox
%%   - Deep Learning Toolbox
%%   - Deep Learning Toolbox Model for ResNet-50
%%   - NVIDIA GPU recommended
%% =========================================================================

clc; clear; close all;

%% =========================================================================
%% SECTION 2.1 - Dataset Overview
%% =========================================================================

datasetPaths = {'./Data/images_thermal_train', ...
                './Data/images_thermal_val',   ...
                './Data/video_thermal_test'};
splitNames   = {'Train', 'Validation', 'Test'};

%% Read categories from training JSON
cocoPath = fullfile(datasetPaths{1}, 'coco.json');
cocoData = jsondecode(fileread(cocoPath));

numCats    = length(cocoData.categories);
classNames = strings(1, numCats);
classIDs   = zeros(1,  numCats);
for i = 1:numCats
    classNames(i) = cocoData.categories(i).name;
    classIDs(i)   = cocoData.categories(i).id;
end
lowerClassNames = lower(classNames);

%% Target classes (verified names from this dataset)
targetClass1 = "person";
targetClass2 = ["bike","car","motor","bus","train","truck","other vehicle"];

%% Count images and annotations per split
numImagesPerSplit = zeros(1, 3);
countsPerSplit    = zeros(numCats, 3);

for d = 1:3
    coco = jsondecode(fileread(fullfile(datasetPaths{d}, 'coco.json')));
    numImagesPerSplit(d) = length(coco.images);
    anns = coco.annotations;
    for i = 1:length(anns)
        if iscell(anns), ann = anns{i}; else, ann = anns(i); end
        idx = find(classIDs == ann.category_id);
        if ~isempty(idx)
            countsPerSplit(idx,d) = countsPerSplit(idx,d) + 1;
        end
    end
end

totalImages = sum(numImagesPerSplit);
pcts = arrayfun(@(x) sprintf('%.2f%%',(x/totalImages)*100), ...
    numImagesPerSplit,'UniformOutput',false);
T_splits = table(splitNames', numImagesPerSplit', pcts', ...
    'VariableNames',{'Split','N_Images','Percentage'});
fprintf('\n=== Table 1: Image Count per Split ===\n');
disp(T_splits);

%% =========================================================================
%% SECTION 2.2 - Category Analysis
%% =========================================================================

validIdx = any(countsPerSplit > 0, 2);
T_categories = table(classNames(validIdx)', classIDs(validIdx)', ...
    countsPerSplit(validIdx,1), countsPerSplit(validIdx,2), countsPerSplit(validIdx,3), ...
    'VariableNames',{'Category','ID','Train','Val','Test'});
fprintf('\n=== Table 2: All Categories ===\n');
disp(T_categories);

%% =========================================================================
%% SECTION 2.3 - Target Class Selection
%% =========================================================================

targetCats  = [targetClass1, targetClass2];
catLabels   = strings(length(targetCats),1);
trainCounts = zeros(length(targetCats),1);
valCounts   = zeros(length(targetCats),1);
testCounts  = zeros(length(targetCats),1);

for c = 1:length(targetCats)
    idx = find(lowerClassNames == targetCats(c));
    if ~isempty(idx)
        catLabels(c)   = classNames(idx);
        trainCounts(c) = countsPerSplit(idx,1);
        valCounts(c)   = countsPerSplit(idx,2);
        testCounts(c)  = countsPerSplit(idx,3);
    end
end

T_target = table(catLabels, trainCounts, valCounts, testCounts, ...
    'VariableNames',{'Category','Train','Val','Test'});
fprintf('\n=== Table 3: Target Class Counts ===\n');
disp(T_target);

%% =========================================================================
%% SECTION 2.4 - Dataset Visualisation
%% =========================================================================

%% Figure 1: Class distribution
figure('Name','Class Distribution','NumberTitle','off');
subplot(1,2,1);
bar(trainCounts,'FaceColor',[0.2 0.5 0.8]);
xticks(1:length(targetCats));
xticklabels(cellstr(catLabels));
xtickangle(35);
ylabel('Annotations'); title('Training Set — Class Distribution'); grid on;

subplot(1,2,2);
mergedCounts = [sum(trainCounts(1)),  sum(trainCounts(2:end)); ...
                sum(valCounts(1)),    sum(valCounts(2:end));   ...
                sum(testCounts(1)),   sum(testCounts(2:end))];
bar(mergedCounts,'grouped');
xticklabels({'Train','Val','Test'});
legend({'People','Vehicles'},'Location','northwest');
ylabel('Annotations'); title('People vs Vehicles per Split'); grid on;
saveas(gcf,'fig1_class_distribution.png');
fprintf('Figure 1 saved.\n');

%% =========================================================================
%% SECTION 2.5 - Data Preparation (10% Subsample)
%% =========================================================================

subsetFraction = 0.10;
rngSeed        = 42;
subsetPaths    = cell(size(datasetPaths));

for d = 1:numel(datasetPaths)
    subsetPaths{d} = aux_subsampleDataset(datasetPaths{d}, subsetFraction, rngSeed);
    fprintf('Subset created: %s\n', subsetPaths{d});
end

fullCounts   = numImagesPerSplit';
subsetCounts = zeros(3,1);
for d = 1:3
    sc = jsondecode(fileread(fullfile(subsetPaths{d},'coco.json')));
    subsetCounts(d) = numel(sc.images);
end
retained = arrayfun(@(a,b) sprintf('%.1f%%',100*a/b), ...
    subsetCounts, fullCounts,'UniformOutput',false);
T_subset = table(splitNames', fullCounts, subsetCounts, retained, ...
    'VariableNames',{'Split','Full_Dataset','Subset','Retained'});
fprintf('\n=== Table 4: Full vs Subset ===\n');
disp(T_subset);

%% =========================================================================
%% SECTION 3 - Build Datastores
%% =========================================================================

fprintf('\nBuilding datastores...\n');

%% Class IDs — verified from coco.json
class1_IDs = classIDs(lowerClassNames == "person");
class2_IDs = classIDs(ismember(lowerClassNames, targetClass2));
if isempty(class1_IDs), class1_IDs = 1; end
if isempty(class2_IDs), class2_IDs = [2,3,4,6,7,8,79]; end

fprintf('class1_IDs (People):   '); fprintf('%d ', class1_IDs); fprintf('\n');
fprintf('class2_IDs (Vehicles): '); fprintf('%d ', class2_IDs); fprintf('\n\n');

detClassNames = {'People','Vehicles'};

combinedDatastores = cell(1,3);
for d = 1:3
    coco    = jsondecode(fileread(fullfile(subsetPaths{d},'coco.json')));
    numImgs = length(coco.images);

    filenames    = cell(numImgs,1);
    peopleBoxes  = cell(numImgs,1);
    vehicleBoxes = cell(numImgs,1);

    imgID_to_idx = containers.Map('KeyType','int32','ValueType','int32');
    for i = 1:numImgs
        img = coco.images(i);
        if iscell(img), img = img{1}; end
        filenames{i}                = fullfile(subsetPaths{d}, img.file_name);
        imgID_to_idx(int32(img.id)) = int32(i);
        peopleBoxes{i}              = zeros(0,4);
        vehicleBoxes{i}             = zeros(0,4);
    end

    anns = coco.annotations;
    for i = 1:length(anns)
        ann = anns(i);
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
        'VariableNames',{'Filename','People','Vehicles'});
    imds = imageDatastore(gtTable.Filename);
    blds = boxLabelDatastore(gtTable(:,2:3));
    combinedDatastores{d} = combine(imds, blds);

    fprintf('Datastore ready: %-12s — %d images\n', splitNames{d}, numImgs);
end

dsTrain = combinedDatastores{1};
dsVal   = combinedDatastores{2};
dsTest  = combinedDatastores{3};

%% Quick sanity check
reset(dsTrain);
tmp = read(dsTrain);
tmpBoxes  = unpackBoxes(tmp{2});
tmpLabels = tmp{3};
if iscell(tmpLabels), tmpLabels = tmpLabels{1}; end
fprintf('Sanity check — first image: People=%d | Vehicles=%d\n', ...
    sum(tmpLabels=='People'), sum(tmpLabels=='Vehicles'));
reset(dsTrain);

%% =========================================================================
%% SECTION 4 - DL Baseline: Faster R-CNN
%% =========================================================================

fprintf('\n=================================================\n');
fprintf(' SECTION 4: DL Baseline — Faster R-CNN\n');
fprintf('=================================================\n');

%% --- 4.1: Build Training Table for Faster R-CNN ---
% Using a table is more stable than a transformed datastore
% Table format: imageFilename | People [Nx4] | Vehicles [Nx4]
fprintf('Building training table for Faster R-CNN...\n');

inputSize = [224 224 3];

[trainTable] = buildFRCNNTable(subsetPaths{1}, class1_IDs, class2_IDs, inputSize);
[testTable]  = buildFRCNNTable(subsetPaths{3}, class1_IDs, class2_IDs, inputSize);

fprintf('Train table: %d images\n', height(trainTable));
fprintf('Test  table: %d images\n', height(testTable));

% Quick validation check
fprintf('Validating train table boxes...\n');
badRows = false(height(trainTable),1);
for i = 1:height(trainTable)
    pb = trainTable.People{i};
    vb = trainTable.Vehicles{i};
    allB = [pb; vb];
    if ~isempty(allB)
        bad = allB(:,3)<=0 | allB(:,4)<=0 | ...
              allB(:,1)<1  | allB(:,2)<1  | ...
              allB(:,1)+allB(:,3)-1 > inputSize(2) | ...
              allB(:,2)+allB(:,4)-1 > inputSize(1);
        if any(bad), badRows(i) = true; end
    end
end
fprintf('Removed %d rows with invalid boxes.\n', sum(badRows));
trainTable = trainTable(~badRows,:);
fprintf('Final train table: %d images\n', height(trainTable));

% Anchor boxes tuned for thermal pedestrians and vehicles
% [height width] — mix of small (people) and large (vehicles)
%% --- 4.2: Define Anchor Boxes manually ---
% estimateAnchorBoxes requires a datastore; since we use a table,
% we define anchor boxes manually based on typical object sizes
% in thermal ADAS images at 224x224 resolution
% Format: [height width]
anchorBoxes = [ 16  16;   % very small / distant person
                32  16;   % tall narrow person
                32  32;   % small person / cyclist
                64  32;   % standing person
                64  64;   % medium vehicle / person
               128  64;   % car / small vehicle
               128 128];  % large vehicle / bus

fprintf('Anchor boxes defined manually (%d anchors):\n', size(anchorBoxes,1));
disp(anchorBoxes);

%% --- 4.3: Build Faster R-CNN network ---
fprintf('Building Faster R-CNN network with ResNet-50...\n');

featureExtractionNetwork = resnet50;
featureLayer             = 'activation_40_relu';

lgraph = fasterRCNNLayers(inputSize, numel(detClassNames), anchorBoxes, ...
    featureExtractionNetwork, featureLayer);

fprintf('Network built.\n');
fprintf('  Backbone:  ResNet-50\n');
fprintf('  Layer:     %s\n', featureLayer);
fprintf('  Anchors:   %d\n', size(anchorBoxes,1));
fprintf('  Classes:   %s, %s\n', detClassNames{1}, detClassNames{2});

%% --- 4.4: Training Options ---
numEpochs     = 10;
miniBatchSize = 2;
initialLR     = 1e-3;

optionsFRCNN = trainingOptions('sgdm', ...
    'MaxEpochs',            numEpochs, ...
    'MiniBatchSize',        miniBatchSize, ...
    'InitialLearnRate',     initialLR, ...
    'LearnRateSchedule',    'piecewise', ...
    'LearnRateDropFactor',  0.1, ...
    'LearnRateDropPeriod',  8, ...
    'Momentum',             0.9, ...
    'L2Regularization',     1e-4, ...
    'VerboseFrequency',     50, ...
    'CheckpointPath',       tempdir, ...
    'ExecutionEnvironment', 'auto', ...
    'Plots',                'training-progress');

fprintf('\nTraining options:\n');
fprintf('  Epochs:         %d\n',   numEpochs);
fprintf('  Batch size:     %d\n',   miniBatchSize);
fprintf('  Learning rate:  %.0e\n', initialLR);
fprintf('  Optimiser:      SGD with momentum\n');
fprintf('  Device:         auto (GPU if available)\n');

%% --- 4.5: Train ---
fprintf('\nTraining Faster R-CNN...\n');
fprintf('(Expected time: 10-30 min on GPU)\n\n');

tic;
[detector_frcnn, trainingInfo] = trainFasterRCNNObjectDetector( ...
    trainTable, ...
    lgraph, ...
    optionsFRCNN, ...
    'NegativeOverlapRange', [0 0.3], ...
    'PositiveOverlapRange', [0.6 1], ...
    'NumStrongestRegions',  2000,    ...
    'TrainingMethod',       'end-to-end');
trainTime = toc;
fprintf('\nTraining complete in %.1f minutes.\n', trainTime/60);

save('fasterrcnn_detector.mat','detector_frcnn','trainingInfo');
fprintf('Model saved: fasterrcnn_detector.mat\n');

%% --- 4.5: Detect on Test Set ---
fprintf('\nDetecting on test set...\n');

frcnnDetBoxes  = {}; frcnnDetScores = {}; frcnnDetLabels = {};
frcnnGTBoxes   = {}; frcnnGTLabels  = {};
ticTotal = tic;

for i = 1:height(testTable)
    img        = imread(testTable.imageFilename{i});
    if size(img,3)==1, img = repmat(img,[1 1 3]); end
    if ~isa(img,'uint8'), img = im2uint8(img); end
    img = imresize(img, [inputSize(1) inputSize(2)]);

    gtPeople   = testTable.People{i};
    gtVehicles = testTable.Vehicles{i};

    [bboxes, scores, labels] = detect(detector_frcnn, img, ...
        'Threshold', 0.5, 'SelectStrongest', true);

    frcnnDetBoxes{end+1}  = bboxes;  %#ok<AGROW>
    frcnnDetScores{end+1} = scores;  %#ok<AGROW>
    frcnnDetLabels{end+1} = labels;  %#ok<AGROW>

    gtB = [gtPeople; gtVehicles];
    gtL = [repmat(categorical({'People'}),   size(gtPeople,1),   1); ...
           repmat(categorical({'Vehicles'}), size(gtVehicles,1), 1)];
    frcnnGTBoxes{end+1}  = gtB; %#ok<AGROW>
    frcnnGTLabels{end+1} = gtL; %#ok<AGROW>

    if mod(i,20)==0
        fprintf('  Tested %d/%d images | %.1fs\n', i, height(testTable), toc(ticTotal));
    end
end
fprintf('Detection complete: %d test images.\n', height(testTable));

%% --- 4.6: Evaluate ---
fprintf('\nEvaluating...\n');

[frcnnAP, frcnnAllPrec, frcnnAllRec, frcnnMAP] = evaluateDetections( ...
    frcnnDetBoxes, frcnnDetScores, frcnnDetLabels, ...
    frcnnGTBoxes,  frcnnGTLabels,  0.5);

fprintf('\n========================================\n');
fprintf('   DL BASELINE: Faster R-CNN\n');
fprintf('========================================\n');
fprintf('mAP  (VOC @ IoU=0.5):  %.4f\n', frcnnMAP);
fprintf('AP   [People]:         %.4f\n', frcnnAP(1));
fprintf('AP   [Vehicles]:       %.4f\n', frcnnAP(2));
fprintf('========================================\n\n');

%% =========================================================================
%% SECTION 5 - Figures & Results
%% =========================================================================

%% Figure 2: Training Loss
% trainingInfo is a 1x4 struct array (4 stages of Faster R-CNN training)
figure('Name','Training Loss','NumberTitle','off','Position',[100 100 1000 400]);
stageNames = {'Stage 1 - RPN','Stage 2 - Detector',...
              'Stage 3 - RPN fine','Stage 4 - Detector fine'};
colors     = {'b','r','g','m'};
for s = 1:length(trainingInfo)
    if isfield(trainingInfo(s),'TrainingLoss') && ...
            ~isempty(trainingInfo(s).TrainingLoss)
        subplot(1,4,s);
        plot(trainingInfo(s).TrainingLoss, colors{s}, 'LineWidth',1.5);
        xlabel('Iteration'); ylabel('Loss');
        title(stageNames{s},'FontSize',9); grid on;
    end
end
sgtitle('Faster R-CNN — Training Loss per Stage','FontSize',12);
saveas(gcf,'fig2_frcnn_training_loss.png');
fprintf('Figure 2 saved.\n');

%% Figure 3: Precision-Recall Curves
figure('Name','PR Curve - Faster R-CNN','NumberTitle','off');
plotPRCurves(frcnnAllPrec, frcnnAllRec, frcnnAP, detClassNames, ...
    sprintf('PR Curve — Faster R-CNN  (mAP=%.3f)', frcnnMAP));
saveas(gcf,'fig3_frcnn_pr_curve.png');
fprintf('Figure 3 saved.\n');

%% Figure 4: Sample Detections on Test Images
fprintf('\nGenerating sample detections figure...\n');
numVisual = 6;
visCount  = 0;

figure('Name','Faster R-CNN Detections','NumberTitle','off', ...
    'Position',[100 100 1400 900]);

for i = 1:height(testTable)
    if visCount >= numVisual, break; end

    gtPeople   = testTable.People{i};
    gtVehicles = testTable.Vehicles{i};
    if size(gtPeople,1)+size(gtVehicles,1) == 0, continue; end

    img = imread(testTable.imageFilename{i});
    if size(img,3)==1, img = repmat(img,[1 1 3]); end
    if ~isa(img,'uint8'), img = im2uint8(img); end
    img = imresize(img,[inputSize(1) inputSize(2)]);

    [bboxes, scores, labels] = detect(detector_frcnn, img, ...
        'Threshold', 0.5, 'SelectStrongest', true);

    visCount = visCount + 1;
    subplot(2,3,visCount);
    imshow(img(:,:,1),[]); hold on;

    % Ground truth
    for b = 1:size(gtPeople,1)
        drawBox(gtPeople(b,:),   'g', '--', 'Person GT');
    end
    for b = 1:size(gtVehicles,1)
        drawBox(gtVehicles(b,:), 'c', '--', 'Vehicle GT');
    end

    % Detections
    for b = 1:size(bboxes,1)
        lbl = char(labels(b));
        if strcmp(lbl,'People')
            drawBox(bboxes(b,:), 'r', '-', sprintf('P %.2f', scores(b)));
        else
            drawBox(bboxes(b,:), 'm', '-', sprintf('V %.2f', scores(b)));
        end
    end

    title(sprintf('Image %d | Detections: %d', visCount, size(bboxes,1)), ...
        'FontSize',9);
    hold off;
end

annotation('textbox',[0.01 0.01 0.98 0.04], ...
    'String', ['Green-- = GT Person  |  Cyan-- = GT Vehicle  |  ' ...
               'Red = Det Person  |  Magenta = Det Vehicle'], ...
    'EdgeColor','none','HorizontalAlignment','center','FontSize',9);
sgtitle('Faster R-CNN — Sample Detections vs Ground Truth','FontSize',13);
saveas(gcf,'fig4_frcnn_sample_detections.png');
fprintf('Figure 4 saved.\n');

fprintf('\n=== ALL DONE ===\n');
fprintf('mAP: %.4f | AP People: %.4f | AP Vehicles: %.4f\n', ...
    frcnnMAP, frcnnAP(1), frcnnAP(2));

%% =========================================================================
%% LOCAL FUNCTIONS
%% =========================================================================

function boxes = unpackBoxes(raw)
%UNPACKBOXES  Safely convert datastore bbox output to Nx4 double.
    if iscell(raw), raw = raw{1}; end
    if isempty(raw)
        boxes = zeros(0,4);
    else
        boxes = double(raw);
        if size(boxes,2) ~= 4, boxes = zeros(0,4); end
    end
end

% -------------------------------------------------------------------------

function dataOut = preprocessForResNet(data)
%PREPROCESSFORRESNET  Grayscale→3ch + resize to 224x224 + scale/validate boxes.
    img    = data{1};
    boxes  = data{2};
    labels = data{3};

    % Convert to uint8
    if ~isa(img,'uint8'), img = im2uint8(img); end

    % Grayscale → 3 channel
    if size(img,3) == 1, img = repmat(img,[1 1 3]); end

    % Get original size before resize
    origH = size(img,1);
    origW = size(img,2);

    % Resize image
    img    = imresize(img,[224 224]);
    scaleX = 224 / origW;
    scaleY = 224 / origH;

    % Scale boxes
    if ~isempty(boxes) && size(boxes,2) == 4
        boxes = double(boxes);
        boxes(:,1) = boxes(:,1) * scaleX;   % x
        boxes(:,2) = boxes(:,2) * scaleY;   % y
        boxes(:,3) = boxes(:,3) * scaleX;   % w
        boxes(:,4) = boxes(:,4) * scaleY;   % h

        % Clip to image bounds [1, 224]
        boxes(:,1) = max(1, boxes(:,1));
        boxes(:,2) = max(1, boxes(:,2));
        boxes(:,3) = min(boxes(:,3), 224 - boxes(:,1) + 1);
        boxes(:,4) = min(boxes(:,4), 224 - boxes(:,2) + 1);

        % Remove boxes with zero or negative width/height
        validMask = boxes(:,3) > 0 & boxes(:,4) > 0;

        % Also remove boxes that go outside image
        validMask = validMask & ...
            (boxes(:,1) >= 1) & ...
            (boxes(:,2) >= 1) & ...
            (boxes(:,1) + boxes(:,3) - 1 <= 224) & ...
            (boxes(:,2) + boxes(:,4) - 1 <= 224);

        boxes  = boxes(validMask, :);
        if iscell(labels)
            labels = labels{1};
        end
        labels = labels(validMask);
    end

    % If no valid boxes remain, insert a dummy 1x1 background box
    % (trainFasterRCNN requires at least 1 box per image)
    if isempty(boxes)
        boxes  = [1 1 1 1];
        labels = categorical({'People'}, {'People','Vehicles'});
    end

    % Ensure labels have correct categories
    if iscategorical(labels)
        labels = categorical(cellstr(labels), {'People','Vehicles'});
    end

    dataOut = {img, boxes, labels};
end

% -------------------------------------------------------------------------

function [AP, allPrec, allRec, mAP] = evaluateDetections( ...
        detBoxes, detScores, detLabels, gtBoxes, gtLabels, iouThresh)
%EVALUATEDETECTIONS  Manual PASCAL VOC mAP (11-point interpolation).
    evalClasses = {'People','Vehicles'};
    AP=zeros(1,2); allPrec=cell(1,2); allRec=cell(1,2);

    for c = 1:2
        cls        = categorical({evalClasses{c}});
        detEntries = [];
        totalGT    = 0;

        for i = 1:length(detBoxes)
            gtB = gtBoxes{i}; gtL = gtLabels{i};
            dB  = detBoxes{i}; dS  = detScores{i}; dL = detLabels{i};

            gtIdx  = find(gtL == cls);
            gtBcls = gtB(gtIdx,:);
            totalGT = totalGT + size(gtBcls,1);

            detIdx  = find(dL == cls);
            detBcls = dB(detIdx,:);
            detScls = dS(detIdx);

            matched = false(size(gtBcls,1),1);
            if ~isempty(detScls)
                [detScls, ord] = sort(detScls,'descend');
                detBcls = detBcls(ord,:);
            end

            for d = 1:size(detBcls,1)
                tp = 0;
                if ~isempty(gtBcls)
                    iouV = bboxOverlapRatio(detBcls(d,:), gtBcls, 'Union');
                    [mx, mi] = max(iouV);
                    if mx >= iouThresh && ~matched(mi)
                        tp = 1; matched(mi) = true;
                    end
                end
                detEntries = [detEntries; i, detScls(d), tp, 1-tp]; %#ok<AGROW>
            end
        end

        if isempty(detEntries) || totalGT == 0
            AP(c)=0; allPrec{c}=[1;0]; allRec{c}=[0;1]; continue;
        end

        [~, ord]   = sort(detEntries(:,2),'descend');
        detEntries  = detEntries(ord,:);
        cumTP       = cumsum(detEntries(:,3));
        cumFP       = cumsum(detEntries(:,4));
        prec        = [1; cumTP ./ (cumTP + cumFP)];
        rec         = [0; cumTP ./ totalGT];

        ap = 0;
        for thr = 0:0.1:1
            p = prec(rec >= thr);
            if ~isempty(p), ap = ap + max(p)/11; end
        end
        AP(c)=ap; allPrec{c}=prec; allRec{c}=rec;
    end
    mAP = mean(AP);
end

% -------------------------------------------------------------------------

function plotPRCurves(allPrec, allRec, AP, classNames, titleStr)
%PLOTPRCURVES  Plot precision-recall curves for both classes.
    colors = {'b','r'};
    hold on;
    for c = 1:2
        plot(allRec{c}, allPrec{c}, 'Color',colors{c}, 'LineWidth',2, ...
            'DisplayName', sprintf('%s (AP=%.3f)', classNames{c}, AP(c)));
    end
    xlabel('Recall','FontSize',11);
    ylabel('Precision','FontSize',11);
    title(titleStr,'FontSize',12);
    legend('Location','northeast','FontSize',10);
    xlim([0 1]); ylim([0 1]); grid on;
end

% -------------------------------------------------------------------------

function drawBox(bbox, color, style, label)
%DRAWBOX  Draw a bounding box with label on the current axes.
    if isempty(bbox) || numel(bbox) < 4, return; end
    rectangle('Position',[bbox(1) bbox(2) bbox(3) bbox(4)], ...
        'EdgeColor',color,'LineStyle',style,'LineWidth',1.5);
    text(bbox(1), max(1,bbox(2)-3), label, ...
        'Color',color,'FontSize',7,'FontWeight','bold','BackgroundColor','k');
end

% -------------------------------------------------------------------------

function T = buildFRCNNTable(dataPath, class1_IDs, class2_IDs, inputSize)
%BUILDFRCNNTABLE  Build a table with resized images and scaled boxes.
%   Reads coco.json, resizes all images to inputSize, scales boxes,
%   removes invalid boxes, returns table ready for trainFasterRCNNObjectDetector.

    targetH = inputSize(1);
    targetW = inputSize(2);

    coco    = jsondecode(fileread(fullfile(dataPath,'coco.json')));
    numImgs = length(coco.images);

    filenames    = cell(numImgs,1);
    peopleBoxes  = cell(numImgs,1);
    vehicleBoxes = cell(numImgs,1);

    % Map image_id → index
    imgID_to_idx = containers.Map('KeyType','int32','ValueType','int32');
    origSizes    = zeros(numImgs,2);  % [H W]

    for i = 1:numImgs
        img = coco.images(i);
        if iscell(img), img = img{1}; end
        filenames{i}                = fullfile(dataPath, img.file_name);
        imgID_to_idx(int32(img.id)) = int32(i);
        origSizes(i,:)              = [img.height, img.width];
        peopleBoxes{i}              = zeros(0,4);
        vehicleBoxes{i}             = zeros(0,4);
    end

    % Fill boxes
    anns = coco.annotations;
    for i = 1:length(anns)
        ann = anns(i);
        if iscell(ann), ann = ann{1}; end
        imgID = int32(ann.image_id);
        catID = ann.category_id;
        if ~isKey(imgID_to_idx, imgID), continue; end
        idx    = imgID_to_idx(imgID);
        bbox   = double(ann.bbox(:)');  % [x y w h]
        origH  = origSizes(idx,1);
        origW  = origSizes(idx,2);
        scaleX = targetW / origW;
        scaleY = targetH / origH;

        % Scale box
        bbox(1) = bbox(1) * scaleX;
        bbox(2) = bbox(2) * scaleY;
        bbox(3) = bbox(3) * scaleX;
        bbox(4) = bbox(4) * scaleY;

        % Clamp to image
        bbox(1) = max(1, bbox(1));
        bbox(2) = max(1, bbox(2));
        bbox(3) = min(bbox(3), targetW - bbox(1) + 1);
        bbox(4) = min(bbox(4), targetH - bbox(2) + 1);

        % Skip invalid
        if bbox(3) <= 0 || bbox(4) <= 0, continue; end
        if bbox(1)+bbox(3)-1 > targetW,  continue; end
        if bbox(2)+bbox(4)-1 > targetH,  continue; end

        if ismember(catID, class1_IDs)
            peopleBoxes{idx}  = [peopleBoxes{idx};  bbox];
        elseif ismember(catID, class2_IDs)
            vehicleBoxes{idx} = [vehicleBoxes{idx}; bbox];
        end
    end

    % Build table — imageFilename must be a cell array of char
    T = table(filenames, peopleBoxes, vehicleBoxes, ...
        'VariableNames', {'imageFilename','People','Vehicles'});
end