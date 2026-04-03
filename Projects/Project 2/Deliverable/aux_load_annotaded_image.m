function [img, labels, bboxes] = aux_load_annotaded_image(imgInfo, subsetPath, annByImage, catLabels)
% LOADANNOTATEDIMAGE Loads an image and its filtered COCO annotations.
% Inputs:
%   imgInfo    - Struct with image metadata (id, file_name)
%   subsetPath - String path to the image folder
%   annByImage - containers.Map (image_id -> annotations)
%   catLabels  - containers.Map (category_id -> 'Person'/'Vehicle')
% Outputs:
%   img        - The RGB or expanded grayscale image
%   labels     - Cell array of strings ('Person' or 'Vehicle')
%   bboxes     - [N x 4] matrix of bounding boxes [x, y, w, h]

    img    = [];
    labels = {};
    bboxes = [];

    imgId   = double(imgInfo.id);
    imgPath = fullfile(subsetPath, imgInfo.file_name);
    
    % Check if annotations exist and file is accessible
    if ~isKey(annByImage, imgId) || ~exist(imgPath, 'file'); return; end

    % Read image and ensure it is 3-channel for annotation insertion
    img = imread(imgPath);
    if size(img, 3) == 1; img = repmat(img, [1 1 3]); end

    anns   = annByImage(imgId);
    tempBboxes = zeros(numel(anns), 4);
    tempLabels = cell(numel(anns), 1);
    
    for j = 1:numel(anns)
        % COCO is 0-indexed; MATLAB is 1-indexed
        b               = anns{j}.bbox;
        tempBboxes(j,:) = [b(1)+1, b(2)+1, b(3), b(4)];
        catId           = double(anns{j}.category_id);
        
        if isKey(catLabels, catId)
            tempLabels{j} = catLabels(catId);
        else
            tempLabels{j} = 'Other'; 
        end
    end

    % Filter only relevant classes for Topic A3
    keep   = strcmp(tempLabels, 'Person') | strcmp(tempLabels, 'Vehicle');
    bboxes = tempBboxes(keep, :);
    labels = tempLabels(keep);
end