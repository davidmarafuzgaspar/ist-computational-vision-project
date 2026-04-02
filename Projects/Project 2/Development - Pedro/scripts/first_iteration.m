%% =========================================================
%  People & Vehicle Detection - Thermal Imagery
%  Topic A3 | Computation Vision - Project 2
%  Data Analysis, Storage and Augmentation Pipeline
%  Authors: David Marafuz Gaspar (106541)
%           Pedro Gaspar Monico (106626)
%% =========================================================

%% ---- 1. Define Dataset Paths and Splits -----------------

datasetPaths = {
    '../../Data/images_thermal_train', ...
    '../../Data/images_thermal_val',   ...
    '../../Data/video_thermal_test'
};
splitNames = {'Train', 'Validation', 'Test'};

%% ---- 2. Read Categories from the Training Dataset -------

cocoPath = fullfile(datasetPaths{1}, 'coco.json');
cocoData = jsondecode(fileread(cocoPath));

numClasses = length(cocoData.categories);
classNames = strings(1, numClasses);
classIDs   = zeros(1,  numClasses);

for i = 1:numClasses
    classNames(i) = cocoData.categories(i).name;
    classIDs(i)   = cocoData.categories(i).id;
end

lowerClassNames = lower(classNames);

%% ---- 3. Define Target Classes ---------------------------

targetClass1 = "person";
targetClass2 = ["car", "motorcycle", "bus", "train", "truck", "other vehicle"];

% Identify which Category IDs belong to each target class
class1_IDs = classIDs(lowerClassNames == targetClass1);
class2_IDs = classIDs(ismember(lowerClassNames, targetClass2));

%% ---- 4. Dataset Distribution Analysis -------------------

numImagesPerSplit = zeros(1, length(datasetPaths));
countsPerSplit    = zeros(numClasses, length(datasetPaths));

% Variables to store bounding boxes for the training split (used later for visualisation)
filenames_train   = [];
peopleBoxes_train = [];
vehicleBoxes_train= [];

for d = 1:length(datasetPaths)
    cocoPath = fullfile(datasetPaths{d}, 'coco.json');
    cocoData = jsondecode(fileread(cocoPath));

    numImgsD = length(cocoData.images);
    numImagesPerSplit(d) = numImgsD;

    % For the training split, also collect bounding boxes for visualisation
    if d == 1
        filenames_train    = cell(numImgsD, 1);
        peopleBoxes_train  = cell(numImgsD, 1);
        vehicleBoxes_train = cell(numImgsD, 1);
        imageIDList        = zeros(numImgsD, 1);

        for k = 1:numImgsD
            filenames_train{k} = fullfile(datasetPaths{1}, cocoData.images(k).file_name);
            imageIDList(k)     = cocoData.images(k).id;
        end
    end

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

        % Store bounding boxes for training split visualisation
        if d == 1
            catName = lower(classNames(idx));
            imgIdx  = find(imageIDList == ann.image_id, 1);
            bbox    = ann.bbox; % [x, y, w, h]

            if catName == targetClass1
                peopleBoxes_train{imgIdx} = [peopleBoxes_train{imgIdx}; bbox];
            elseif any(catName == targetClass2)
                vehicleBoxes_train{imgIdx} = [vehicleBoxes_train{imgIdx}; bbox];
            end
        end
    end
end

%% ---- 5. Print Image Counts per Split --------------------

totalImages = sum(numImagesPerSplit);
fprintf('\nImage Count and Percentage by Dataset Split\n');
fprintf('%-12s | %-10s | %-11s\n', 'Dataset', 'N Images', 'Percentage');
fprintf('------------------------------------------\n');
for d = 1:length(datasetPaths)
    pct = (numImagesPerSplit(d) / totalImages) * 100;
    fprintf('%-12s | %-10d | %.2f%%\n', splitNames{d}, numImagesPerSplit(d), pct);
end

%% ---- 6. Print Per-Category Instance Counts --------------

targetCategories = [targetClass1, targetClass2];

fprintf('\nNumber of Instances for Relevant Categories\n');
fprintf('%-15s | %-7s | %-7s | %-7s\n', 'Category', 'Train', 'Val', 'Test');
fprintf('---------------------------------------------------\n');
for c = 1:length(targetCategories)
    idxCat = find(lowerClassNames == targetCategories(c));
    if ~isempty(idxCat)
        fprintf('%-15s | %-7d | %-7d | %-7d\n', ...
            classNames(idxCat), ...
            countsPerSplit(idxCat, 1), ...
            countsPerSplit(idxCat, 2), ...
            countsPerSplit(idxCat, 3));
    end
end

%% ---- 7. Print Grouped Class Counts ----------------------

countsClass1 = zeros(1, 3);
countsClass2 = zeros(1, 3);

idxPerson = find(lowerClassNames == targetClass1);
if ~isempty(idxPerson)
    countsClass1 = countsPerSplit(idxPerson, :);
end

for v = 1:length(targetClass2)
    idxVeh = find(lowerClassNames == targetClass2(v));
    if ~isempty(idxVeh)
        countsClass2 = countsClass2 + countsPerSplit(idxVeh, :);
    end
end

fprintf('\nGrouped Instance Counts\n');
fprintf('%-20s | %-7s | %-7s | %-7s\n', 'Class', 'Train', 'Val', 'Test');
fprintf('------------------------------------------------------\n');
fprintf('%-20s | %-7d | %-7d | %-7d\n', 'Class 1 (People)',   countsClass1(1), countsClass1(2), countsClass1(3));
fprintf('%-20s | %-7d | %-7d | %-7d\n', 'Class 2 (Vehicles)', countsClass2(1), countsClass2(2), countsClass2(3));

%% ---- 8. Visualise Training Samples with Grouped Bounding Boxes

sampleIndices = [700, 1000, 2000];

figure('Name', 'Dataset Samples with Grouped Classes', 'Position', [100, 100, 1500, 500]);
for i = 1:length(sampleIndices)
    idx = sampleIndices(i);
    img = imread(filenames_train{idx});

    bboxes_people   = double(peopleBoxes_train{idx});
    bboxes_vehicles = double(vehicleBoxes_train{idx});

    img = aux_annotate(img, bboxes_people, bboxes_vehicles);

    subplot(1, 3, i);
    imshow(img);
    title(sprintf('Image %d', i), 'FontSize', 12);
end

%% ---- 9. Create Datastores for All Splits ----------------

combinedDatastores = cell(1, length(datasetPaths));

for d = 1:length(datasetPaths)

    cocoPath = fullfile(datasetPaths{d}, 'coco.json');
    cocoData = jsondecode(fileread(cocoPath));

    numImgs      = length(cocoData.images);
    filenames    = cell(numImgs, 1);
    peopleBoxes  = cell(numImgs, 1);
    vehicleBoxes = cell(numImgs, 1);

    % Map image_id -> array index for fast lookup
    imgID_to_idx = containers.Map('KeyType', 'int32', 'ValueType', 'int32');

    for i = 1:numImgs
        img = cocoData.images(i);
        if iscell(img), img = img{1}; end

        filenames{i}             = fullfile(datasetPaths{d}, img.file_name);
        imgID_to_idx(int32(img.id)) = int32(i);

        peopleBoxes{i}  = zeros(0, 4);
        vehicleBoxes{i} = zeros(0, 4);
    end

    annotations = cocoData.annotations;
    for i = 1:length(annotations)
        ann = annotations(i);
        if iscell(ann), ann = ann{1}; end

        imgID = int32(ann.image_id);
        catID = ann.category_id;

        if isKey(imgID_to_idx, imgID)
            idx  = imgID_to_idx(imgID);
            bbox = ann.bbox(:)'; % Ensure 1x4 row vector [x, y, w, h]

            if ismember(catID, class1_IDs)
                peopleBoxes{idx}  = [peopleBoxes{idx};  bbox];
            elseif ismember(catID, class2_IDs)
                vehicleBoxes{idx} = [vehicleBoxes{idx}; bbox];
            end
        end
    end

    % Build ground-truth table and combined datastore
    gtTable = table(filenames, peopleBoxes, vehicleBoxes, ...
        'VariableNames', {'Filename', 'People', 'Vehicles'});

    imds = imageDatastore(gtTable.Filename);
    blds = boxLabelDatastore(gtTable(:, 2:3));

    combinedDatastores{d} = combine(imds, blds);
    fprintf('Created Combined Datastore for %-12s: %d images\n', splitNames{d}, numImgs);
end

% Expose individual datastores for downstream use
dsTrain = combinedDatastores{1};
dsVal   = combinedDatastores{2};
dsTest  = combinedDatastores{3};

%% ---- 10. Data Augmentation ------------------------------

% Apply augmentation transform to the training datastore
dsTrainAugmented = transform(dsTrain, @aux_augment_data);

% Verification: compare an original sample with its augmented version
reset(dsTrain);
reset(dsTrainAugmented);

originalData  = read(dsTrain);
augmentedData = read(dsTrainAugmented);

figure('Name', 'Augmentation Verification');

subplot(1, 2, 1);
imgOrig = aux_annotate(originalData{1}, originalData{2}, originalData{3});
imshow(imgOrig);
title('Original Thermal Image', 'FontSize', 12);

subplot(1, 2, 2);
imgAug = aux_annotate(augmentedData{1}, augmentedData{2}, augmentedData{3});
imshow(imgAug);
title('Augmented (Random Flip & Scale)', 'FontSize', 12);

fprintf('\nPipeline complete. Datastores ready: dsTrain, dsVal, dsTest, dsTrainAugmented.\n');