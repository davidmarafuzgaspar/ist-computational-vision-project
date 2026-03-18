function plot_segments(segments)
    for k = 1:length(segments)
        pts = segments{k};
        [Y_unique,~,idxu] = unique(pts(:,2));
        X_mean = accumarray(idxu, pts(:,1), [], @mean);

        if numel(Y_unique)>=2
            Y_spline = linspace(min(Y_unique), max(Y_unique), 50);
            X_spline = interp1(Y_unique, X_mean, Y_spline, 'pchip');
            plot(X_spline,Y_spline,'g','LineWidth',2);
        end
    end
end