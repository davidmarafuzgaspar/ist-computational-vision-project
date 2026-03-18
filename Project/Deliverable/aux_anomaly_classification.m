function final_status = aux_anomaly_classification(predicted_status, anomaly_ratios, area_thresh)
% Reclassify based on anomaly ratios.
%
% Inputs:
%   predicted_status - Nx1 string ("Clear"/"Obstructed") from first stage
%   anomaly_ratios - Nx2 [sides_ratio, middle_ratio]
%   area_thresh - Threshold (e.g. 0.1)
%
% Output:
%   final_status - Nx1 string array

    N = length(predicted_status);
    final_status = strings(N, 1);
    for i = 1:N
        if predicted_status(i) == "Obstructed"
            final_status(i) = "Obstructed";
        else
            r_s = anomaly_ratios(i, 1);
            r_m = anomaly_ratios(i, 2);
            if isnan(r_s), r_s = 0; end
            if isnan(r_m), r_m = 0; end
            if r_s > area_thresh || r_m > area_thresh
                final_status(i) = "Obstructed";
            else
                final_status(i) = "Clear";
            end
        end
    end
end
