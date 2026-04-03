%% Computation Vision - Project 2
%% Topic A3: People and Vehicle Detection Using Thermal Imagery
%% Authors:
%%   David Marafuz Gaspar - 106541
%%   Pedro Gaspar Monico  - 106626

%% =========================================================================
%% SECTION 2.1 - Dataset Overview
%% =========================================================================

%% Define Dataset Paths and Splits
datasetPaths = {'./Data/images_thermal_train', './Data/images_thermal_val', './Data/video_thermal_test'};
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
targetClass2    = ["car", "motorcycle", "bus", "train", "truck", "other vehicle"];

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
pcts = arrayfun(@(x) sprintf('%.2f%%', (x/totalImages)*100), numImagesPerSplit, 'UniformOutput', false);
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

targetCategories = ["person", "car", "motor", "bus", "train", "truck", "other vehicle"];

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

subsetFraction = 0.10;  % 10% of each split
rngSeed        = 42;    % for reproducibility

subsetPaths = cell(size(datasetPaths));
for d = 1:numel(datasetPaths)
    subsetPaths{d} = aux_subsampleDataset(datasetPaths{d}, subsetFraction, rngSeed);
    fprintf('Subset created: %s\n', subsetPaths{d});
end

% Table 4: Full vs subset counts
fullCounts   = numImagesPerSplit';
subsetCounts = zeros(3, 1);
for d = 1:3
    subCoco        = jsondecode(fileread(fullfile(subsetPaths{d}, 'coco.json')));
    subsetCounts(d) = numel(subCoco.images);
end
retained = arrayfun(@(a,b) sprintf('%.1f%%', 100*a/b), subsetCounts, fullCounts, 'UniformOutput', false);
T_subset = table(splitNames', fullCounts, subsetCounts, retained, ...
    'VariableNames', {'Split', 'Full_Dataset', 'Subset', 'Retained'});
disp('Table 4: Full Dataset vs. Subset Size per Split');
disp(T_subset);

%% =========================================================================
%% SECTION 3.1 - Data Storage (Datastores for YOLO)
%% =========================================================================

% Category IDs for each target class
class1_IDs = classIDs(lowerClassNames == targetClass1);
class2_IDs = classIDs(ismember(lowerClassNames, targetClass2));

classNames = {'People', 'Vehicles'};  % class names YOLO will use

combinedDatastores = cell(1, 3);

for d = 1:3

    cocoData = jsondecode(fileread(fullfile(subsetPaths{d}, 'coco.json')));
    numImgs  = length(cocoData.images);

    filenames    = cell(numImgs, 1);
    peopleBoxes  = cell(numImgs, 1);
    vehicleBoxes = cell(numImgs, 1);

    % Map image_id -> array index
    imgID_to_idx = containers.Map('KeyType', 'int32', 'ValueType', 'int32');
    for i = 1:numImgs
        img = cocoData.images(i);
        if iscell(img), img = img{1}; end
        filenames{i}               = fullfile(subsetPaths{d}, img.file_name);
        imgID_to_idx(int32(img.id)) = int32(i);
        peopleBoxes{i}             = zeros(0, 4);
        vehicleBoxes{i}            = zeros(0, 4);
    end

    % Fill bounding boxes
    annotations = cocoData.annotations;
    for i = 1:length(annotations)
        ann = annotations(i);
        if iscell(ann), ann = ann{1}; end

        imgID = int32(ann.image_id);
        catID = ann.category_id;

        if isKey(imgID_to_idx, imgID)
            idx  = imgID_to_idx(imgID);
            bbox = ann.bbox(:)';  % [x, y, w, h]

            if ismember(catID, class1_IDs)
                peopleBoxes{idx}  = [peopleBoxes{idx};  bbox];
            elseif ismember(catID, class2_IDs)
                vehicleBoxes{idx} = [vehicleBoxes{idx}; bbox];
            end
        end
    end

    % Ground truth table
    gtTable = table(filenames, peopleBoxes, vehicleBoxes, ...
        'VariableNames', {'Filename', 'People', 'Vehicles'});

    % Build combined datastore
    imds = imageDatastore(gtTable.Filename);
    blds = boxLabelDatastore(gtTable(:, 2:3));
    combinedDatastores{d} = combine(imds, blds);

    fprintf('Datastore ready for %-12s: %d images\n', splitNames{d}, numImgs);
end

dsTrain = combinedDatastores{1};
dsVal   = combinedDatastores{2};
dsTest  = combinedDatastores{3};

fprintf('\nData preparation complete.\n');
fprintf('Classes: %s, %s\n', classNames{1}, classNames{2});