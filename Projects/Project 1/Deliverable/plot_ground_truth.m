function plot_ground_truth(imgRGB, gtEntry)
    
    imshow(imgRGB); hold on;
    
    % Plot both left and right rails in blue
    if ~isempty(gtEntry.left)
        plot(gtEntry.left(:,1), gtEntry.left(:,2), ...
             'b.-', 'MarkerSize', 10, 'LineWidth', 2);
    end
    
    if ~isempty(gtEntry.right)
        plot(gtEntry.right(:,1), gtEntry.right(:,2), ...
             'b.-', 'MarkerSize', 10, 'LineWidth', 2);
    end
    
    hold off;
end