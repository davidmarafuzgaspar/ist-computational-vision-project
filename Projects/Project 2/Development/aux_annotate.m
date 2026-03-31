function img = aux_annotate(img, bboxes_people, bboxes_vehicles)
    % AUX_ANNOTATE_THERMAL Draws bounding boxes for People and Vehicles
    %
    % Inputs:
    %   img             - The raw thermal image matrix
    %   bboxes_people   - [x, y, w, h] matrix for People
    %   bboxes_vehicles - [x, y, w, h] matrix for Vehicles
    
    % Draw 'People' in Green
    if ~isempty(bboxes_people)
        img = insertObjectAnnotation(img, 'rectangle', bboxes_people, 'People', ...
            'Color', 'green', 'LineWidth', 3, 'FontSize', 14);
    end
    
    % Draw 'Vehicles' in Red
    if ~isempty(bboxes_vehicles)
        img = insertObjectAnnotation(img, 'rectangle', bboxes_vehicles, 'Vehicle', ...
            'Color', 'red', 'LineWidth', 3, 'FontSize', 14);
    end
end