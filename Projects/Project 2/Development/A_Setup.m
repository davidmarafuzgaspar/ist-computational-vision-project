%% Lista dos datasets
datasets = {'../Data/images_thermal_train', '../Data/images_thermal_val', '../Data/video_thermal_test'};
datasetNames = {'Treino', 'Validação', 'Teste'};

%% Ler classes do dataset de treino
cocoPath = fullfile(datasets{1}, 'coco.json');
fid = fopen(cocoPath); 
raw = fread(fid, inf); 
str = char(raw'); 
fclose(fid); 
cocoData = jsondecode(str); 
categories = cocoData.categories; 
numClasses = length(categories); 

classNames = strings(1, numClasses);
classIDs = zeros(1, numClasses);
for i = 1:numClasses
    classNames(i) = categories(i).name;
    classIDs(i) = categories(i).id;
end

fprintf('Todas as classes do dataset (%d):\n', numClasses);
fprintf('%s\n', join(classNames, ', '));

%% Inicializar tabelas
numImagesPerDataset = zeros(1, length(datasets));
countsPerDataset = zeros(numClasses, length(datasets));

%% Processar cada conjunto
for d = 1:length(datasets)
    cocoPath = fullfile(datasets{d}, 'coco.json');    
    fid = fopen(cocoPath);     
    raw = fread(fid, inf);     
    str = char(raw');     
    fclose(fid);     
    cocoData = jsondecode(str); 
    
    %% Contar número de imagens
    numImages = length(cocoData.images);
    numImagesPerDataset(d) = numImages;
    
    %% Contar instâncias por classe
    annotations = cocoData.annotations;
    counts = zeros(1, numClasses);
    for i = 1:length(annotations)
        if iscell(annotations)
            ann = annotations{i};
        else
            ann = annotations(i);
        end
        catID = ann.category_id;
        idx = find(classIDs == catID);
        counts(idx) = counts(idx) + 1;
    end
    countsPerDataset(:, d) = counts';
end

%% --- Tabela 1: número de imagens por dataset ---
fprintf('\n=== Número de imagens por dataset ===\n');
fprintf('Dataset   | N Imagens\n');
fprintf('---------------------\n');
for d = 1:length(datasets)
    fprintf('%-10s | %d\n', datasetNames{d}, numImagesPerDataset(d));
end

%% --- Tabela 2: número de instâncias por classe em cada dataset ---
% Selecionar apenas classes com pelo menos uma instância em algum dataset
idxNonZero = any(countsPerDataset > 0, 2);
classNamesNonZero = classNames(idxNonZero);
countsPerDatasetNonZero = countsPerDataset(idxNonZero, :);

fprintf('\n=== Número de instâncias por classe ===\n');
fprintf('%-20s | %-6s | %-6s | %-6s\n', 'Classe', 'Treino', 'Val', 'Teste');
fprintf('-------------------------------------------------\n');
for i = 1:length(classNamesNonZero)
    fprintf('%-20s | %-6d | %-6d | %-6d\n', ...
        classNamesNonZero(i), ...
        countsPerDatasetNonZero(i, 1), ...
        countsPerDatasetNonZero(i, 2), ...
        countsPerDatasetNonZero(i, 3));
end