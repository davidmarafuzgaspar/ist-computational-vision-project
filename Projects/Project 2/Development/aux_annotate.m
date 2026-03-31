function img = aux_annotate(img, bboxes, labels)
    % AUX_ANNOTATE Safely draws boxes for People and Vehicles
    
    % --- STEP 1: Force Bounding Boxes to Double Matrix ---
    if istable(bboxes)
        bboxes = table2array(bboxes);
    end
    if iscell(bboxes)
        bboxes = bboxes{1};
    end
    bboxes = double(bboxes); % Final conversion to numeric
    
    % --- STEP 2: Force Labels to String Array ---
    if istable(labels)
        labels = table2array(labels);
    end
    if iscell(labels)
        labels = labels{1};
    end
    labels = string(labels); % Final conversion to strings
    
    % --- STEP 3: Separate and Draw ---
    % People (Green)
    idxP = (labels == "People");
    pBoxes = bboxes(idxP, :);
    if ~isempty(pBoxes)
        img = insertObjectAnnotation(img, 'rectangle', pBoxes, 'People', ...
            'Color', 'green', 'LineWidth', 3, 'FontSize', 14);
    end
    
    % Vehicles (Red)
    idxV = (labels == "Vehicles");
    vBoxes = bboxes(idxV, :);
    if ~isempty(vBoxes)
        img = insertObjectAnnotation(img, 'rectangle', vBoxes, 'Vehicle', ...
            'Color', 'red', 'LineWidth', 3, 'FontSize', 14);
    end
end