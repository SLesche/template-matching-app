function write_info(app, review, erp, bin, a, b, latency, fit_cor, fit_dist)
    % Write the information in the current review step to the
    % results matrix
    app.final_mat(erp, bin, [1:5, 7]) = [a, b, latency, fit_cor, fit_dist, review];
end