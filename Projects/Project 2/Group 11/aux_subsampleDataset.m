function subsetPath = aux_subsampleDataset(splitPath, fraction, rngSeed)
% AUX_SUBSAMBLEDATASET  Randomly samples a fraction of images from a COCO
%   split and saves the subset to a new folder with the suffix '_subset'.
%
%   subsetPath = aux_subsampleDataset(splitPath, fraction, rngSeed)
%
%   Inputs:
%     splitPath  - path to the original split folder (contains coco.json + data/)
%     fraction   - fraction of images to retain (e.g. 0.10 for 10%)
%     rngSeed    - random seed for reproducibility
%
%   Output:
%     subsetPath - path to the newly created subset folder

    % ── Paths ─────────────────────────────────────────────
    cocoPath   = fullfile(splitPath, 'coco.json');
    imgSrcDir  = fullfile(splitPath, 'data');
    subsetPath = [splitPath '_subset'];
    imgDstDir  = fullfile(subsetPath, 'data');

    % ── Load COCO JSON ────────────────────────────────────
    coco = jsondecode(fileread(cocoPath));

    % ── Sample images ─────────────────────────────────────
    rng(rngSeed);
    numTotal    = numel(coco.images);
    numSample   = max(1, round(fraction * numTotal));
    sampledIdx  = sort(randperm(numTotal, numSample));

    % Get sampled image IDs
    sampledImgs = coco.images(sampledIdx);
    sampledIDs  = arrayfun(@(x) x.id, sampledImgs);

    % ── Filter annotations ────────────────────────────────
    if iscell(coco.annotations)
        allAnns = coco.annotations;
        keepAnn = cellfun(@(a) ismember(a.image_id, sampledIDs), allAnns);
        sampledAnns = allAnns(keepAnn);
    else
        keepAnn     = arrayfun(@(a) ismember(a.image_id, sampledIDs), coco.annotations);
        sampledAnns = coco.annotations(keepAnn);
    end

    % ── Build new COCO struct ─────────────────────────────
    newCoco.info        = coco.info;
    newCoco.categories  = coco.categories;
    newCoco.images      = sampledImgs;
    newCoco.annotations = sampledAnns;

    % ── Create output folders ─────────────────────────────
    if ~exist(imgDstDir, 'dir')
        mkdir(imgDstDir);
    end

    % ── Copy images ───────────────────────────────────────
    copiedCount = 0;
    for i = 1:numel(sampledImgs)
        fname = sampledImgs(i).file_name;  % e.g. 'data/video-xxx.jpg'
    
        src = fullfile(splitPath, fname);  % splitPath/data/video-xxx.jpg
        dst = fullfile(subsetPath, fname); % subsetPath/data/video-xxx.jpg
    
        % Make sure destination subfolder exists
        dstDir = fileparts(dst);
        if ~exist(dstDir, 'dir')
            mkdir(dstDir);
        end
    
        if exist(src, 'file') && ~exist(dst, 'file')
            copyfile(src, dst);
            copiedCount = copiedCount + 1;
        end
    end
    fprintf('   Copied %d / %d images\n', copiedCount, numel(sampledImgs));

    % ── Save new coco.json ────────────────────────────────
    newCocoJson = jsonencode(newCoco);
    fid = fopen(fullfile(subsetPath, 'coco.json'), 'w');
    fprintf(fid, '%s', newCocoJson);
    fclose(fid);

    fprintf('   [%s] %d → %d images (%.0f%%) saved to %s\n', ...
        splitPath, numTotal, numSample, fraction*100, subsetPath);
end