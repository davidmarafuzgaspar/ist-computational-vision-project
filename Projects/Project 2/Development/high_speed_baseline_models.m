%% Phase 1: High-Speed Baseline Comparison Script (Final Fix)
classNames = {'People', 'Vehicles'};

%% 1. Estimate Anchor Boxes
numAnchors = 6;
[anchors, meanIoU] = estimateAnchorBoxes(dsTrainAugmented, numAnchors);
fprintf('Anchor boxes estimated. Mean IoU: %.4f\n', meanIoU);

%% Convert anchors to cell array split across 2 scales
anchorBoxes = {anchors(1:3, :); anchors(4:6, :)};

%% DIAGNOSTIC: Check actual channel count of training data
sampleData = preview(dsTrainAugmented);
sampleImg  = sampleData{1};
fprintf('Training image size: %s\n', mat2str(size(sampleImg)));
numChannels = size(sampleImg, 3);
fprintf('Detected channels: %d\n', numChannels);

%% Define backbone feature layer names
featureLayers.squeezenet = {'fire8-concat', 'fire5-concat'};
featureLayers.googlenet  = {'inception_4d-output', 'inception_3b-output'};

%% Input sizes — match channel count to actual training data
inputSizes.squeezenet = [227 227 numChannels];
inputSizes.googlenet  = [224 224 numChannels];

%% 2. List of Baselines
baselines = {'squeezenet', 'googlenet'};

for i = 1:length(baselines)
    arch = baselines{i};
    fprintf('\n### Testing Baseline: %s ###\n', arch);

    %% 3. Load Pretrained Network
    if strcmp(arch, 'squeezenet')
        net = squeezenet;
    elseif strcmp(arch, 'googlenet')
        net = googlenet;
    end

    lgraph = layerGraph(net);

    %% 4. Remove Incompatible Layers
    layerTypes = arrayfun(@(l) class(l), lgraph.Layers, 'UniformOutput', false);
    layerNames = arrayfun(@(l) l.Name,  lgraph.Layers, 'UniformOutput', false);

    toRemove = lgraph.Layers( ...
        contains(layerTypes, {'ClassificationOutputLayer','SoftmaxLayer', ...
                              'GlobalAveragePooling2DLayer'}) | ...
        contains(layerNames, {'pool10','pool5-7x7_s1', ...
                              'loss3-ave_pool','loss3-classifier','output'}) ...
    );

    for k = 1:numel(toRemove)
        fprintf('  Removing layer: %s (%s)\n', toRemove(k).Name, class(toRemove(k)));
        lgraph = removeLayers(lgraph, toRemove(k).Name);
    end

    %% 5. Replace ImageInputLayer — correct size AND normalization
    layerTypes   = arrayfun(@(l) class(l), lgraph.Layers, 'UniformOutput', false);
    inputLayerIdx = find(contains(layerTypes, 'ImageInputLayer'));

    if ~isempty(inputLayerIdx)
        inputLayerName = lgraph.Layers(inputLayerIdx).Name;
        oldInputSize   = lgraph.Layers(inputLayerIdx).InputSize;

        % Keep spatial dims from original network, but fix channels
        newSize = [oldInputSize(1) oldInputSize(2) numChannels];

        newInputLayer = imageInputLayer(newSize, ...
            'Name',          inputLayerName, ...
            'Normalization', 'none');

        lgraph = replaceLayer(lgraph, inputLayerName, newInputLayer);
        fprintf('  ImageInputLayer replaced: %s -> Normalization=none, Channels=%d\n', ...
            mat2str(oldInputSize), numChannels);
    end

    %% 6. Convert to dlnetwork
    baseNet = dlnetwork(lgraph);
    fprintf('  dlnetwork created successfully for %s\n', arch);

    %% 7. Verify feature layers
    allNames = {baseNet.Layers.Name};
    fl = featureLayers.(arch);
    for f = 1:numel(fl)
        if any(strcmp(allNames, fl{f}))
            fprintf('    [OK] %s\n', fl{f});
        else
            fprintf('    [MISSING] %s\n', fl{f});
        end
    end

    %% 8. Initialize YOLOv4
    detector = yolov4ObjectDetector(baseNet, classNames, anchorBoxes, ...
        'DetectionNetworkSource', fl, ...
        'InputSize', inputSizes.(arch));
    fprintf('  YOLOv4 detector initialized for %s\n', arch);

    %% 9. Training Options
    options = trainingOptions('sgdm', ...
        'InitialLearnRate',  0.001, ...
        'MiniBatchSize',     8, ...
        'MaxEpochs',         10, ...
        'Plots',             'training-progress', ...
        'Shuffle',           'every-epoch', ...
        'Verbose',           true);

    %% 10. Train
    fprintf('  Starting training for %s...\n', arch);
    [trainedNet, info] = trainYOLOv4ObjectDetector(dsTrainAugmented, detector, options);

    %% 11. Save
    saveName = sprintf('baseline_%s.mat', arch);
    save(saveName, 'trainedNet', 'info');
    fprintf('  Model saved to: %s\n', saveName);
end

fprintf('\n=== Phase 1 Complete ===\n');