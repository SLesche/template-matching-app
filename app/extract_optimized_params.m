function [a_param, b_param, latency, fit_cor, fit_dist] = extract_optimized_params(app, source)
    if ~exist('source', 'var')
        source = "reviewed";
    end
    % This function just return the previously optimized params by
    % the baseline optimization method
    if source == "original"
        values = app.results_mat(app.erp_num, app.bin_num, :);
    else
        values = app.final_mat(app.erp_num, app.bin_num, :);
    end
    a_param = values(1);
    b_param = values(2);
    latency = values(3);
    fit_cor = values(4);
    fit_dist = values(5);
end