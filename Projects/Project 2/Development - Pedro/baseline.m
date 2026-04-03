%% =========================================================================
%% Computation Vision - Project 2
%% Topic A3: People and Vehicle Detection Using Thermal Imagery
%% Authors:
%%   David Marafuz Gaspar - 106541
%%   Pedro Gaspar Monico  - 106626
%% =========================================================================
%% BASELINE: Sliding Window + HOG + SVM
%% =========================================================================

clc; clear; close all;

%% =========================================================================
%% SECTION 2.1 - Dataset Overview
%% =========================================================================

%% Define Dataset Paths and Splits
datasetPaths = {'./Data/images_thermal_train', ...
                './Data/images_thermal_val',   ...
                './Data/video_thermal_test'};
splitNames   = {'Train', 'Validation', 'Test'};

%% Read Categories from the Training Dataset
cocoPath = fullfile(datasetPaths{1}, 'coco.json');
cocoData = jsondecode(fileread(cocoPath));

numClasses = length(cocoData.categories);
classNames = strings(1, numClasses);
classIDs   = zeros(1, numClasses);

for i = 1:numClasses
    classNames(i) = cocoData.categories(i).name;
    classIDs(i)   = cocoData.categories(i).id;
end

lowerClassNames = lower(classNames);
targetClass1    = "person";
% Actual vehicle names in this dataset (verified from coco.json):
targetClass2    = ["bike", "car", "motor", "bus", "train", "truck", "other vehicle"];

%% Count Images and Annotations per Split
numImagesPerSplit = zeros(1, length(datasetPaths));
countsPerSplit    = zeros(numClasses, length(datasetPaths));

for d = 1:length(datasetPaths)
    cocoPath = fullfile(datasetPaths{d}, 'coco.json');
    cocoData = jsondecode(fileread(cocoPath));

    numImagesPerSplit(d) = length(cocoData.images);

    annotations = cocoData.annotations;
    for i = 1:length(annotations)
        if iscell(annotations)
            ann = annotations{i};
        else
            ann = annotations(i);
        end
        idx = find(classIDs == ann.category_id);
        if ~isempty(idx)
            countsPerSplit(idx, d) = countsPerSplit(idx, d) + 1;
        end
    end
end

% Table 1: Image counts per split
totalImages = sum(numImagesPerSplit);
pcts = arrayfun(@(x) sprintf('%.2f%%', (x/totalImages)*100), ...
    numImagesPerSplit, 'UniformOutput', false);
T_splits = table(splitNames', numImagesPerSplit', pcts', ...
    'VariableNames', {'Split', 'N_Images', 'Percentage'});
disp('Table 1: Image Count and Percentage by Dataset Split');
disp(T_splits);

%% =========================================================================
%% SECTION 2.2 - Category Analysis
%% =========================================================================

validIdx = any(countsPerSplit > 0, 2);
T_categories = table(...
    classNames(validIdx)', ...
    classIDs(validIdx)', ...
    countsPerSplit(validIdx, 1), ...
    countsPerSplit(validIdx, 2), ...
    countsPerSplit(validIdx, 3), ...
    'VariableNames', {'Category', 'ID', 'Train', 'Val', 'Test'});
disp('Table 2: All Categories with Non-Zero Instance Counts');
disp(T_categories);

%% =========================================================================
%% SECTION 2.3 - Target Class Selection
%% =========================================================================

targetCategories = ["person", "car", "motorcycle", "bus", "train", "truck", "other vehicle"];

catLabels   = strings(length(targetCategories), 1);
trainCounts = zeros(length(targetCategories), 1);
valCounts   = zeros(length(targetCategories), 1);
testCounts  = zeros(length(targetCategories), 1);

for c = 1:length(targetCategories)
    idxCat = find(lowerClassNames == targetCategories(c));
    if ~isempty(idxCat)
        catLabels(c)   = classNames(idxCat);
        trainCounts(c) = countsPerSplit(idxCat, 1);
        valCounts(c)   = countsPerSplit(idxCat, 2);
        testCounts(c)  = countsPerSplit(idxCat, 3);
    end
end

T_target = table(catLabels, trainCounts, valCounts, testCounts, ...
    'VariableNames', {'Category', 'Train', 'Val', 'Test'});
disp('Table 3: Instance Counts for Target Categories');
disp(T_target);

%% =========================================================================
%% SECTION 2.4 - Data Preparation (10% Subsample)
%% =========================================================================

subsetFraction = 0.05;
rngSeed        = 42;

subsetPaths = cell(size(datasetPaths));
for d = 1:numel(datasetPaths)
    subsetPaths{d} = aux_subsampleDataset(datasetPaths{d}, subsetFraction, rngSeed);
    fprintf('Subset created: %s\n', subsetPaths{d});
end

% Table 4: Full vs subset counts
fullCounts   = numImagesPerSplit';
subsetCounts = zeros(3, 1);
for d = 1:3
    subCoco         = jsondecode(fileread(fullfile(subsetPaths{d}, 'coco.json')));
    subsetCounts(d) = numel(subCoco.images);
end
retained = arrayfun(@(a,b) sprintf('%.1f%%', 100*a/b), ...
    subsetCounts, fullCounts, 'UniformOutput', false);
T_subset = table(splitNames', fullCounts, subsetCounts, retained, ...
    'VariableNames', {'Split', 'Full_Dataset', 'Subset', 'Retained'});
disp('Table 4: Full Dataset vs. Subset Size per Split');
disp(T_subset);

%% =========================================================================
%% SECTION 3.1 - Data Storage (Datastores)
%% =========================================================================

% Category IDs for each target class
% Verified from coco.json: person=1, bike=2, car=3, motor=4,
%                          bus=6, train=7, truck=8, other vehicle=79
class1_IDs = classIDs(lowerClassNames == "person");
class2_IDs = classIDs(ismember(lowerClassNames, ...
    ["bike", "car", "motor", "bus", "train", "truck", "other vehicle"]));

% If matching failed, fall back to hardcoded IDs
if isempty(class1_IDs)
    class1_IDs = 1;
    fprintf('WARNING: person ID not found by name, using hardcoded ID=1\n');
end
if isempty(class2_IDs)
    class2_IDs = [2, 3, 4, 6, 7, 8, 79];
    fprintf('WARNING: vehicle IDs not found by name, using hardcoded IDs\n');
end

% Diagnostic
fprintf('\n--- Category ID Lookup ---\n');
fprintf('class1_IDs (People):   '); fprintf('%d ', class1_IDs);  fprintf('\n');
fprintf('class2_IDs (Vehicles): '); fprintf('%d ', class2_IDs);  fprintf('\n\n');

detClassNames = {'People', 'Vehicles'};

combinedDatastores = cell(1, 3);

for d = 1:3

    cocoData = jsondecode(fileread(fullfile(subsetPaths{d}, 'coco.json')));
    numImgs  = length(cocoData.images);

    filenames    = cell(numImgs, 1);
    peopleBoxes  = cell(numImgs, 1);
    vehicleBoxes = cell(numImgs, 1);

    imgID_to_idx = containers.Map('KeyType', 'int32', 'ValueType', 'int32');
    for i = 1:numImgs
        img = cocoData.images(i);
        if iscell(img), img = img{1}; end
        filenames{i}                = fullfile(subsetPaths{d}, img.file_name);
        imgID_to_idx(int32(img.id)) = int32(i);
        peopleBoxes{i}              = zeros(0, 4);
        vehicleBoxes{i}             = zeros(0, 4);
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
        'VariableNames', {'Filename', 'People', 'Vehicles'});

    imds = imageDatastore(gtTable.Filename);
    blds = boxLabelDatastore(gtTable(:, 2:3));
    combinedDatastores{d} = combine(imds, blds);

    fprintf('Datastore ready for %-12s: %d images\n', splitNames{d}, numImgs);
end

dsTrain = combinedDatastores{1};
dsVal   = combinedDatastores{2};
dsTest  = combinedDatastores{3};

fprintf('\nData preparation complete.\n');
fprintf('Classes: %s, %s\n', detClassNames{1}, detClassNames{2});

%% =========================================================================
%% SECTION 3.2 - Baseline: Sliding Window + HOG + SVM
%% =========================================================================

%% --- Detection Parameters ---
windowSize        = [64 64];          % patch size fed to HOG+SVM
stepSize          = 16;               % sliding step in pixels
scales            = [1.0, 0.75, 0.5]; % image scales for multi-scale detection
hogCellSize       = [8 8];            % HOG cell size
numOrient         = 9;                % HOG orientation bins
nmsThreshold      = 0.3;              % IoU threshold for NMS
scoreThreshold    = 0.6;              % minimum SVM score to keep detection

%% --- Training Sample Limits ---
maxPosPeople  = 2000;
maxPosVehicle = 2000;
maxNegSamples = 4000;

%% =========================================================================
%% STEP 1 - Compute HOG Feature Length
%% =========================================================================

dummyImg   = zeros(windowSize, 'uint8');
dummyFeats = extractHOGFeatures(dummyImg, ...
    'CellSize', hogCellSize, 'NumBins', numOrient);
featLen    = length(dummyFeats);
fprintf('\nHOG feature vector length: %d\n', featLen);

%% =========================================================================
%% STEP 2 - Extract HOG Features + Labels from Training Set
%% =========================================================================

fprintf('Extracting HOG features from training images...\n');

allFeatures = zeros(0, featLen);
allLabels   = categorical([]);

posPeople  = 0;
posVehicle = 0;
negCount   = 0;
imgIdx     = 0;

reset(dsTrain);

while hasdata(dsTrain)

    data   = read(dsTrain);
    img    = data{1};

    % combine(imds,blds) returns: data{2}=all boxes [Nx4], data{3}=labels [Nx1 categorical]
    allBboxes  = unpackBoxes(data{2});
    allBbLabels = data{3};
    if iscell(allBbLabels), allBbLabels = allBbLabels{1}; end

    % Split into People and Vehicle boxes by label
    pBoxes = allBboxes(allBbLabels == 'People',   :);
    vBoxes = allBboxes(allBbLabels == 'Vehicles', :);

    imgIdx = imgIdx + 1;

    % Ensure grayscale uint8
    if size(img, 3) == 3
        img = rgb2gray(img);
    end
    img = im2uint8(img);
    [H, W] = size(img);

    %% Positive patches - People
    for b = 1:size(pBoxes, 1)
        if posPeople >= maxPosPeople, break; end
        patch = extractPatch(img, pBoxes(b,:), windowSize);
        if isempty(patch), continue; end
        feats       = extractHOGFeatures(patch, ...
            'CellSize', hogCellSize, 'NumBins', numOrient);
        allFeatures = [allFeatures; feats];          %#ok<AGROW>
        allLabels   = [allLabels; categorical({'People'})]; %#ok<AGROW>
        posPeople   = posPeople + 1;
    end

    %% Positive patches - Vehicles
    for b = 1:size(vBoxes, 1)
        if posVehicle >= maxPosVehicle, break; end
        patch = extractPatch(img, vBoxes(b,:), windowSize);
        if isempty(patch), continue; end
        feats       = extractHOGFeatures(patch, ...
            'CellSize', hogCellSize, 'NumBins', numOrient);
        allFeatures = [allFeatures; feats];             %#ok<AGROW>
        allLabels   = [allLabels; categorical({'Vehicles'})]; %#ok<AGROW>
        posVehicle  = posVehicle + 1;
    end

    %% Negative patches - random background windows
    if negCount < maxNegSamples
        allBoxes = [pBoxes; vBoxes];
        for attempt = 1:20
            rx      = randi([1, max(1, W - windowSize(2))]);
            ry      = randi([1, max(1, H - windowSize(1))]);
            randBox = [rx, ry, windowSize(2), windowSize(1)];

            % Skip if overlaps GT box
            if ~isempty(allBoxes)
                iouVals = bboxOverlapRatio(randBox, allBoxes, 'Min');
                if max(iouVals) > 0.3, continue; end
            end

            patch = extractPatch(img, randBox, windowSize);
            if isempty(patch), continue; end
            feats       = extractHOGFeatures(patch, ...
                'CellSize', hogCellSize, 'NumBins', numOrient);
            allFeatures = [allFeatures; feats];                  %#ok<AGROW>
            allLabels   = [allLabels; categorical({'Background'})]; %#ok<AGROW>
            negCount    = negCount + 1;
            break;
        end
    end

    if mod(imgIdx, 50) == 0
        fprintf('  [%d imgs] People: %d | Vehicles: %d | Background: %d\n', ...
            imgIdx, posPeople, posVehicle, negCount);
    end

    % Stop early if all caps reached
    if posPeople >= maxPosPeople && posVehicle >= maxPosVehicle && negCount >= maxNegSamples
        break;
    end
end

fprintf('\nTotal training samples: %d\n', length(allLabels));
fprintf('  People:     %d\n', sum(allLabels == 'People'));
fprintf('  Vehicles:   %d\n', sum(allLabels == 'Vehicles'));
fprintf('  Background: %d\n', sum(allLabels == 'Background'));

%% =========================================================================
%% STEP 3 - Train Multiclass SVM
%% =========================================================================

fprintf('\nTraining SVM (this may take a few minutes)...\n');
tic;

svmModel = fitcecoc(allFeatures, allLabels, ...
    'Learners', templateSVM( ...
        'KernelFunction', 'linear', ...
        'Standardize',    true), ...
    'Coding', 'onevsall');

trainTime = toc;
fprintf('SVM training complete in %.1f seconds.\n', trainTime);

% Training accuracy
trainPred = predict(svmModel, allFeatures);
trainAcc  = mean(trainPred == allLabels) * 100;
fprintf('Training accuracy: %.2f%%\n', trainAcc);

% Save model
save('hog_svm_model.mat', 'svmModel', 'hogCellSize', 'numOrient', 'windowSize');
fprintf('Model saved to hog_svm_model.mat\n');

%% =========================================================================
%% STEP 4 - Run Detection on Test Set
%% =========================================================================

fprintf('\nRunning sliding window detection on test set...\n');
fprintf('(This is slow by design — it is the baseline)\n\n');

reset(dsTest);

detBoxes_all  = {};
detScores_all = {};
detLabels_all = {};
gtBoxes_all   = {};
gtLabels_all  = {};

imgIdx   = 0;
ticTotal = tic;

while hasdata(dsTest)
    data       = read(dsTest);
    img        = data{1};
    allBboxes  = unpackBoxes(data{2});
    allBbLabels = data{3};
    if iscell(allBbLabels), allBbLabels = allBbLabels{1}; end
    gtPeople   = allBboxes(allBbLabels == 'People',   :);
    gtVehicles = allBboxes(allBbLabels == 'Vehicles', :);

    imgIdx = imgIdx + 1;

    %% Run sliding window detection
    dets = slidingWindowDetect(img, svmModel, ...
        windowSize, stepSize, scales, ...
        hogCellSize, numOrient, scoreThreshold);

    %% Apply NMS per class
    [nmsBoxes, nmsScores, nmsLabels] = applyNMS( ...
        dets.boxes, dets.scores, dets.labels, nmsThreshold);

    %% Store detections
    detBoxes_all{end+1}  = nmsBoxes;   %#ok<AGROW>
    detScores_all{end+1} = nmsScores;  %#ok<AGROW>
    detLabels_all{end+1} = nmsLabels;  %#ok<AGROW>

    %% Store ground truth
    gtB = [gtPeople; gtVehicles];
    gtL = [repmat(categorical({'People'}),   size(gtPeople,1),   1); ...
           repmat(categorical({'Vehicles'}), size(gtVehicles,1), 1)];
    gtBoxes_all{end+1}  = gtB;   %#ok<AGROW>
    gtLabels_all{end+1} = gtL;   %#ok<AGROW>

    if mod(imgIdx, 10) == 0
        elapsed = toc(ticTotal);
        fprintf('  Tested %d images | %.1fs elapsed\n', imgIdx, elapsed);
    end
end

fprintf('\nDetection complete: %d test images processed.\n', imgIdx);

%% =========================================================================
%% STEP 5 - Evaluate: mAP, Precision, Recall (manual implementation)
%% =========================================================================

fprintf('\nEvaluating detections...\n');

evalClasses  = {'People', 'Vehicles'};
iouThreshold = 0.5;
AP           = zeros(1, 2);
allPrec      = cell(1, 2);
allRec       = cell(1, 2);

for c = 1:2
    cls = categorical({evalClasses{c}});

    % Collect all detections for this class across all images
    % Each entry: [imageIdx, score, tp, fp]
    detEntries = [];

    totalGT = 0;

    for i = 1:length(detBoxes_all)
        gtB = gtBoxes_all{i};
        gtL = gtLabels_all{i};
        dB  = detBoxes_all{i};
        dS  = detScores_all{i};
        dL  = detLabels_all{i};

        % GT boxes for this class in this image
        gtIdx  = find(gtL == cls);
        gtBcls = gtB(gtIdx, :);
        totalGT = totalGT + size(gtBcls, 1);

        % Detection boxes for this class in this image
        detIdx  = find(dL == cls);
        detBcls = dB(detIdx, :);
        detScls = dS(detIdx);

        % Match detections to GT (greedy by score)
        matched = false(size(gtBcls, 1), 1);

        % Sort detections by score descending
        if ~isempty(detScls)
            [detScls, sortOrd] = sort(detScls, 'descend');
            detBcls = detBcls(sortOrd, :);
        end

        for d = 1:size(detBcls, 1)
            tp = 0;
            if ~isempty(gtBcls)
                iouVals = bboxOverlapRatio(detBcls(d,:), gtBcls, 'Union');
                [maxIoU, maxIdx] = max(iouVals);
                if maxIoU >= iouThreshold && ~matched(maxIdx)
                    tp = 1;
                    matched(maxIdx) = true;
                end
            end
            fp = 1 - tp;
            detEntries = [detEntries; i, detScls(d), tp, fp]; %#ok<AGROW>
        end
    end

    % Sort all detections by score descending
    if isempty(detEntries)
        AP(c) = 0;
        allPrec{c} = 0;
        allRec{c}  = 0;
        continue;
    end

    [~, ord]  = sort(detEntries(:,2), 'descend');
    detEntries = detEntries(ord, :);

    cumTP = cumsum(detEntries(:,3));
    cumFP = cumsum(detEntries(:,4));

    precision = cumTP ./ (cumTP + cumFP);
    recall    = cumTP ./ totalGT;

    % Append sentinel
    precision = [1; precision]; %#ok<AGROW>
    recall    = [0; recall];    %#ok<AGROW>

    % 11-point interpolated AP (PASCAL VOC style)
    ap = 0;
    for thr = 0:0.1:1
        prec_at_rec = precision(recall >= thr);
        if ~isempty(prec_at_rec)
            ap = ap + max(prec_at_rec) / 11;
        end
    end

    AP(c)       = ap;
    allPrec{c}  = precision;
    allRec{c}   = recall;
end

mAP = mean(AP);

fprintf('\n========================================\n');
fprintf('   BASELINE RESULTS: HOG + SVM\n');
fprintf('========================================\n');
fprintf('mAP  (VOC @ IoU=0.5):  %.4f\n', mAP);
fprintf('AP   [People]:         %.4f\n', AP(1));
fprintf('AP   [Vehicles]:       %.4f\n', AP(2));
fprintf('========================================\n\n');

%% =========================================================================
%% STEP 6 - Visualize Results
%% =========================================================================

%% --- Figure 1: Precision-Recall Curves ---
colors = {'b', 'r'};
figure('Name', 'PR Curves - HOG+SVM Baseline', 'NumberTitle', 'off');
hold on;
for c = 1:2
    prec = allPrec{c};
    rec  = allRec{c};
    plot(rec, prec, 'Color', colors{c}, 'LineWidth', 2, ...
        'DisplayName', sprintf('%s (AP=%.3f)', detClassNames{c}, AP(c)));
end
xlabel('Recall',    'FontSize', 12);
ylabel('Precision', 'FontSize', 12);
title('Precision-Recall Curve — HOG+SVM Baseline', 'FontSize', 13);
legend('Location', 'northeast', 'FontSize', 11);
grid on;
xlim([0 1]); ylim([0 1]);
saveas(gcf, 'PR_curve_baseline.png');
fprintf('PR curve saved.\n');

%% --- Figure 2: Sample Detections on Test Images ---
fprintf('\nVisualizing sample detections...\n');

reset(dsTest);
numVisual = 6;  % number of images to visualize
visCount  = 0;

figure('Name', 'Sample Detections - HOG+SVM', ...
    'NumberTitle', 'off', 'Position', [100 100 1400 900]);

imgIdx = 0;
while hasdata(dsTest) && visCount < numVisual
    data       = read(dsTest);
    img        = data{1};
    allBboxes  = unpackBoxes(data{2});
    allBbLabels = data{3};
    if iscell(allBbLabels), allBbLabels = allBbLabels{1}; end
    gtPeople   = allBboxes(allBbLabels == 'People',   :);
    gtVehicles = allBboxes(allBbLabels == 'Vehicles', :);

    imgIdx = imgIdx + 1;

    % Only show images that have at least one GT object
    if size(gtPeople,1) + size(gtVehicles,1) == 0
        continue;
    end

    % Run detection
    dets = slidingWindowDetect(img, svmModel, ...
        windowSize, stepSize, scales, ...
        hogCellSize, numOrient, scoreThreshold);
    [nmsBoxes, nmsScores, nmsLabels] = applyNMS( ...
        dets.boxes, dets.scores, dets.labels, nmsThreshold);

    visCount = visCount + 1;
    subplot(2, 3, visCount);

    % Display image (handle grayscale)
    if size(img, 3) == 1
        imshow(img, []);
    else
        imshow(img);
    end
    hold on;

    % Draw GT boxes (green dashed)
    for b = 1:size(gtPeople,1)
        drawBox(gtPeople(b,:),  'g--', 'Person (GT)');
    end
    for b = 1:size(gtVehicles,1)
        drawBox(gtVehicles(b,:), 'c--', 'Vehicle (GT)');
    end

    % Draw detections (solid)
    for b = 1:size(nmsBoxes,1)
        lbl = char(nmsLabels(b));
        if strcmp(lbl, 'People')
            col = 'r-';
        else
            col = 'm-';
        end
        drawBox(nmsBoxes(b,:), col, sprintf('%s %.2f', lbl, nmsScores(b)));
    end

    title(sprintf('Image %d', imgIdx), 'FontSize', 9);
    hold off;
end

% Legend patch
annotation('textbox', [0.01 0.01 0.98 0.04], ...
    'String', ['Green dashed = GT Person  |  Cyan dashed = GT Vehicle  |  ' ...
               'Red = Det Person  |  Magenta = Det Vehicle'], ...
    'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'FontSize', 9);

sgtitle('HOG + SVM — Sample Detections vs Ground Truth', 'FontSize', 13);
saveas(gcf, 'sample_detections_baseline.png');
fprintf('Sample detections figure saved.\n');

%% --- Figure 3: Class Distribution of Training Samples ---
figure('Name', 'Training Sample Distribution', 'NumberTitle', 'off');
classCounts = [sum(allLabels=='People'), sum(allLabels=='Vehicles'), sum(allLabels=='Background')];
bar(classCounts, 'FaceColor', [0.3 0.6 0.9]);
xticklabels({'People', 'Vehicles', 'Background'});
ylabel('Number of patches');
title('HOG Training Sample Distribution');
grid on;
for i = 1:3
    text(i, classCounts(i) + 20, num2str(classCounts(i)), ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end
saveas(gcf, 'training_distribution.png');

%% --- Figure 4: HOG Visualization on a sample patch ---
reset(dsTrain);
sampleData = read(dsTrain);
sampleImg  = sampleData{1};
sampleBoxes = sampleData{2};
if size(sampleBoxes, 1) > 0
    samplePatch = extractPatch(im2uint8(sampleImg), sampleBoxes(1,:), windowSize);
    if ~isempty(samplePatch)
        [~, hogVis] = extractHOGFeatures(samplePatch, ...
            'CellSize', hogCellSize, 'NumBins', numOrient);
        figure('Name', 'HOG Feature Visualization', 'NumberTitle', 'off');
        subplot(1,2,1); imshow(samplePatch, []); title('Sample Patch (Person)');
        subplot(1,2,2); plot(hogVis); title('HOG Features');
        saveas(gcf, 'hog_visualization.png');
        fprintf('HOG visualization saved.\n');
    end
end

fprintf('\nAll done! Baseline evaluation complete.\n');

%% =========================================================================
%% LOCAL FUNCTIONS
%% =========================================================================

function boxes = unpackBoxes(raw)
%UNPACKBOXES  Robustly convert any bbox format from datastore to Nx4 double.
%
%  The combined datastore (imds + blds) can return bounding boxes in
%  several formats depending on MATLAB version:
%    - double matrix  [Nx4]        → already correct
%    - cell array     {[Nx4]}      → unwrap with {1}
%    - 0x4 empty      []           → return zeros(0,4)

    if iscell(raw)
        raw = raw{1};
    end

    if isempty(raw)
        boxes = zeros(0, 4);
    else
        boxes = double(raw);
        % Ensure it is Nx4
        if size(boxes, 2) ~= 4
            boxes = zeros(0, 4);
        end
    end
end

% -------------------------------------------------------------------------

function patch = extractPatch(img, bbox, targetSize)
%EXTRACTPATCH  Crop a bounding box from img and resize to targetSize.
%   bbox = [x y w h]  (COCO format, 1-indexed)

    % Force to plain double row vector (handles cell, table, or numeric input)
    if iscell(bbox)
        bbox = bbox{1};
    end
    bbox = double(bbox(:)');   % ensure [1x4] double

    x = max(1, round(bbox(1)));
    y = max(1, round(bbox(2)));
    w = max(1, round(bbox(3)));
    h = max(1, round(bbox(4)));

    [H, W] = size(img(:,:,1));
    x2 = min(W, x + w - 1);
    y2 = min(H, y + h - 1);

    if x2 <= x || y2 <= y
        patch = [];
        return;
    end

    patch = imresize(img(y:y2, x:x2), targetSize);
end

% -------------------------------------------------------------------------

function detections = slidingWindowDetect(img, svmModel, ...
        windowSize, stepSize, scales, hogCellSize, numOrient, scoreThresh)
%SLIDINGWINDOWDETECT  Multi-scale sliding window + HOG + SVM detector.
%
%   Returns struct with fields:
%       .boxes  [Nx4] in original image coords  [x y w h]
%       .scores [Nx1] SVM confidence score
%       .labels [Nx1] categorical  ('People' | 'Vehicles')

    if size(img, 3) == 3
        img = rgb2gray(img);
    end
    img = im2uint8(img);

    allBoxes  = zeros(0, 4);
    allScores = zeros(0, 1);
    allLabels = categorical([]);

    wH = windowSize(1);
    wW = windowSize(2);

    for s = 1:length(scales)
        scale      = scales(s);
        imgScaled  = imresize(img, scale);
        [H, W]     = size(imgScaled);

        if H < wH || W < wW, continue; end

        for y = 1:stepSize:(H - wH + 1)
            for x = 1:stepSize:(W - wW + 1)

                patch = imgScaled(y:y+wH-1, x:x+wW-1);
                feats = extractHOGFeatures(patch, ...
                    'CellSize', hogCellSize, 'NumBins', numOrient);

                [label, ~, scores] = predict(svmModel, feats);

                % Reject background
                if label == categorical({'Background'}), continue; end

                % Score = max posterior probability
                score = max(scores);
                if score < scoreThresh, continue; end

                % Map window back to original image coordinates
                origBox = round([x/scale, y/scale, wW/scale, wH/scale]);

                allBoxes  = [allBoxes;  origBox]; %#ok<AGROW>
                allScores = [allScores; score];   %#ok<AGROW>
                allLabels = [allLabels; label];   %#ok<AGROW>
            end
        end
    end

    detections.boxes  = allBoxes;
    detections.scores = allScores;
    detections.labels = allLabels;
end

% -------------------------------------------------------------------------

function [finalBoxes, finalScores, finalLabels] = applyNMS( ...
        boxes, scores, labels, threshold)
%APPLYNMS  Per-class Non-Maximum Suppression using selectStrongestBbox.

    finalBoxes  = zeros(0, 4);
    finalScores = zeros(0, 1);
    finalLabels = categorical([]);

    if isempty(boxes), return; end

    uniqueLabels = unique(labels);

    for c = 1:length(uniqueLabels)
        cls     = uniqueLabels(c);
        idx     = labels == cls;
        cBoxes  = boxes(idx, :);
        cScores = scores(idx);

        if isempty(cBoxes), continue; end

        [selBoxes, selScores] = selectStrongestBbox(cBoxes, cScores, ...
            'RatioType',       'Min', ...
            'OverlapThreshold', threshold);

        finalBoxes  = [finalBoxes;  selBoxes];                        %#ok<AGROW>
        finalScores = [finalScores; selScores];                       %#ok<AGROW>
        finalLabels = [finalLabels; repmat(cls, size(selBoxes,1), 1)]; %#ok<AGROW>
    end
end

% -------------------------------------------------------------------------

function drawBox(bbox, style, label)
%DRAWBOX  Draw a single bounding box with label on the current axes.
%   bbox = [x y w h]

    if isempty(bbox) || size(bbox,2) < 4, return; end

    x = bbox(1); y = bbox(2); w = bbox(3); h = bbox(4);

    % Parse color from style string (first char)
    colChar = style(1);
    lineStyle = style(2:end);

    rectangle('Position', [x y w h], ...
        'EdgeColor', colChar, ...
        'LineStyle',  lineStyle, ...
        'LineWidth',  1.5);

    text(x, max(1, y-3), label, ...
        'Color',    colChar, ...
        'FontSize', 7, ...
        'FontWeight', 'bold', ...
        'BackgroundColor', 'k');
end