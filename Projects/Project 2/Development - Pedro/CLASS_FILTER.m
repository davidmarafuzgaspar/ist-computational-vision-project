%% Define Dataset Paths and Splits
datasetPaths = {'../Data/images_thermal_train', '../Data/images_thermal_val', '../Data/video_thermal_test'};
splitNames = {'Train', 'Validation', 'Test'};

%% Read Categories from the Training Dataset
% Using 'fileread' is a much cleaner, one-line way to read text files in MATLAB!
cocoPath = fullfile(datasetPaths{1}, 'coco.json');
cocoData = jsondecode(fileread(cocoPath)); 

% Extract class names and IDs
numClasses = length(cocoData.categories); 
classNames = strings(1, numClasses);
classIDs = zeros(1, numClasses);

for i = 1:numClasses
    classNames(i) = cocoData.categories(i).name;
    classIDs(i) = cocoData.categories(i).id;
end

%% Initialize Counters
numImagesPerSplit = zeros(1, length(datasetPaths));
countsPerSplit = zeros(numClasses, length(datasetPaths));

%% Process Each Dataset Split
for d = 1:length(datasetPaths)
    % Read JSON for the current split
    cocoPath = fullfile(datasetPaths{d}, 'coco.json');    
    cocoData = jsondecode(fileread(cocoPath)); 
    
    % Count total images
    numImagesPerSplit(d) = length(cocoData.images);
    
    % Count instances per class
    annotations = cocoData.annotations;
    for i = 1:length(annotations)
        % Handle both cell and struct arrays gracefully
        if iscell(annotations)
            ann = annotations{i};
        else
            ann = annotations(i);
        end
        
        % Find the index of the category ID and increment the counter
        idx = find(classIDs == ann.category_id);
        if ~isempty(idx)
            countsPerSplit(idx, d) = countsPerSplit(idx, d) + 1;
        end
    end
end

%% Print Table 1: Number and Percentage of Images per Split
totalImages = sum(numImagesPerSplit);
fprintf('\n=== Image Count and Percentage by Dataset Split ===\n');
fprintf('%-12s | %-10s | %-11s\n', 'Dataset', 'N Images', 'Percentage');
fprintf('------------------------------------------\n');
for d = 1:length(datasetPaths)
    pct = (numImagesPerSplit(d) / totalImages) * 100;
    fprintf('%-12s | %-10d | %.2f%%\n', splitNames{d}, numImagesPerSplit(d), pct);
end

%% Print Table 2: Filter Target Categories (People and Vehicles) 
% Convert class names to lowercase for robust matching
lowerClassNames = lower(classNames);

% Define the target categories we actually care about
targetCategories = ["person", "car", "motorcycle", "bus", "train", "truck", "other vehicle"];

% Print the final table with only the relevant categories across all splits
fprintf('\n=== Number of Instances for Relevant Categories ===\n');
fprintf('%-15s | %-7s | %-7s | %-7s\n', 'Category', 'Train', 'Val', 'Test');
fprintf('---------------------------------------------------\n');

for c = 1:length(targetCategories)
    % Find where our target category matches the dataset categories
    idxCat = find(lowerClassNames == targetCategories(c));
    
    if ~isempty(idxCat)
        % Print the counts for Train (1), Val (2), and Test (3)
        fprintf('%-15s | %-7d | %-7d | %-7d\n', ...
            classNames(idxCat), ...
            countsPerSplit(idxCat, 1), ...
            countsPerSplit(idxCat, 2), ...
            countsPerSplit(idxCat, 3));
    end
end

%% Final Table: Grouping into Class 1 and Class 2
countsClass1 = zeros(1, 3); 
countsClass2 = zeros(1, 3);

% What belongs to each class
targetClass1 = "person";
targetClass2 = ["car", "motorcycle", "bus", "train", "truck", "other vehicle"];

% Sum instances for Class 1 (People)
idxPerson = find(lowerClassNames == targetClass1);
if ~isempty(idxPerson)
    countsClass1 = countsPerSplit(idxPerson, :);
end

% Sum instances for Class 2 (Vehicles)
for v = 1:length(targetClass2)
    idxVeh = find(lowerClassNames == targetClass2(v));
    if ~isempty(idxVeh)
        countsClass2 = countsClass2 + countsPerSplit(idxVeh, :);
    end
end

% Final Grouped Table
fprintf('\nGrouped Instance Counts\n');
fprintf('%-20s | %-7s | %-7s | %-7s\n', 'Class', 'Train', 'Val', 'Test');
fprintf('------------------------------------------------------\n');
fprintf('%-20s | %-7d | %-7d | %-7d\n', 'Class 1 (People)', countsClass1(1), countsClass1(2), countsClass1(3));
fprintf('%-20s | %-7d | %-7d | %-7d\n', 'Class 2 (Vehicles)', countsClass2(1), countsClass2(2), countsClass2(3));

%% Data Loading (Creating Ground Truth Tables and Datastores)

% Identify which Category IDs belong to the two target classes
class1_IDs = classIDs(lowerClassNames == targetClass1);
class2_IDs = classIDs(ismember(lowerClassNames, targetClass2));

combinedDatastores = cell(1, length(datasetPaths));

% Loop through Train, Val, and Test splits
for d = 1:length(datasetPaths)
    
    % Read JSON for the current split
    cocoPath = fullfile(datasetPaths{d}, 'coco.json');
    cocoData = jsondecode(fileread(cocoPath));
    
    numImgs = length(cocoData.images);
    filenames = cell(numImgs, 1);
    peopleBoxes = cell(numImgs, 1);
    vehicleBoxes = cell(numImgs, 1);
    
    % Create a map (dictionary) to link image_id to the array index
    imgID_to_idx = containers.Map('KeyType', 'int32', 'ValueType', 'int32');
    
    % Extract image filenames and initialize empty bounding box arrays
    for i = 1:numImgs
        img = cocoData.images(i);
        if iscell(img), img = img{1}; end
        
        filenames{i} = fullfile(datasetPaths{d}, img.file_name);
        imgID_to_idx(int32(img.id)) = int32(i);
        
        % Initialize empty bounding box arrays [x, y, width, height]
        peopleBoxes{i} = zeros(0, 4);
        vehicleBoxes{i} = zeros(0, 4);
    end
    
    % Extract and filter Bounding Boxes from annotations
    annotations = cocoData.annotations;
    for i = 1:length(annotations)
        ann = annotations(i);
        if iscell(ann), ann = ann{1}; end
        
        imgID = int32(ann.image_id);
        catID = ann.category_id;
        
        if isKey(imgID_to_idx, imgID)
            idx = imgID_to_idx(imgID);
            bbox = ann.bbox(:)'; % Ensure it is a 1x4 row vector [x, y, w, h]
            
            % Assign the bounding box to the correct target class
            if ismember(catID, class1_IDs)
                peopleBoxes{idx} = [peopleBoxes{idx}; bbox];
            elseif ismember(catID, class2_IDs)
                vehicleBoxes{idx} = [vehicleBoxes{idx}; bbox];
            end
        end
    end
    
    % Create MATLAB Ground Truth Table
    gtTable = table(filenames, peopleBoxes, vehicleBoxes, ...
        'VariableNames', {'Filename', 'People', 'Vehicles'});
    
    % Create Datastores
    imds = imageDatastore(gtTable.Filename);
    blds = boxLabelDatastore(gtTable(:, 2:3));
    
    % Combine them so the image and bounding boxes are passed together
    combinedDatastores{d} = combine(imds, blds);
    
    fprintf('Created Combined Datastore for %-10s:  %d images ready.\n', splitNames{d}, numImgs);
end

% Extract individual datastores to easily call them in the training phase
dsTrain = combinedDatastores{1};
dsVal   = combinedDatastores{2};
dsTest  = combinedDatastores{3};

%% Plot das 3 primeiras imagens do Treino com Bounding Boxes

% 2. Criar a figura
figure('Name', 'Amostras do Dataset de Treino', 'Position', [100, 100, 1500, 500]);

for i = 1:3
    % Ler uma amostra do datastore de treino
    data = read(dsTrain);
    
    % Extrair a imagem
    img = data{1};
    
    % Extrair as bounding boxes. 
    bboxes_people = data{2};
    bboxes_vehicles = data{3};
    
    % CORREÇÃO: Se as boxes vierem dentro de uma cell array, extraímos a matriz numérica
    if iscell(bboxes_people)
        bboxes_people = bboxes_people{1};
    end
    if iscell(bboxes_vehicles)
        bboxes_vehicles = bboxes_vehicles{1};
    end
    
    % Desenhar as Bounding Boxes para 'People' (Verde)
    % Só desenha se a matriz de caixas não estiver vazia
    if ~isempty(bboxes_people)
        img = insertObjectAnnotation(img, 'rectangle', bboxes_people, 'People', ...
            'Color', 'green', 'TextBoxOpacity', 0.8, 'FontSize', 14);
    end
    
    % Desenhar as Bounding Boxes para 'Vehicles' (Vermelho)
    if ~isempty(bboxes_vehicles)
        img = insertObjectAnnotation(img, 'rectangle', bboxes_vehicles, 'Vehicle', ...
            'Color', 'red', 'TextBoxOpacity', 0.8, 'FontSize', 14);
    end
    
    % Mostrar no subplot
    subplot(1, 3, i);
    imshow(img);
    title(sprintf('Amostra de Treino #%d', i), 'FontSize', 14, 'FontWeight', 'bold');
end
