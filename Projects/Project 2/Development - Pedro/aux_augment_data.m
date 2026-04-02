function dataOut = aux_augment_data(dataIn)
    % AUX_AUGMENT_DATA Handles combined datastore input as a single cell array
    % dataIn is a cell array: {Image, BoundingBoxes, Labels}
    
    img    = dataIn{1};
    bboxes = dataIn{2};
    labels = dataIn{3};
    
    % Get image dimensions
    sz = size(img); 
    imgWidth = sz(2);
    
    % 1. Random Horizontal Flip (50% chance)
    if rand > 0.5
        img = flip(img, 2);
        if ~isempty(bboxes)
            % Manual coordinate flip: x_new = width - x_old - box_width
            bboxes(:,1) = imgWidth - bboxes(:,1) - bboxes(:,3);
        end
    end
    
    % 2. Random Scaling (between 90% and 110%)
    scale = 0.9 + (1.1 - 0.9) * rand;
    img = imresize(img, scale);
    if ~isempty(bboxes)
        bboxes = bboxes * scale;
    end
    
    % Return the data in the same cell array format
    dataOut = {img, bboxes, labels};
end