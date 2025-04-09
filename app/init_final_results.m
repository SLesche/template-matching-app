function init_final_results(app)
    [n_subjects, n_bins, n_params] = size(app.results_mat);

    final_review_mat = zeros([n_subjects, n_bins, n_params + 2]);
    final_review_mat(:, :, 1:n_params) = app.results_mat;
    app.final_mat = final_review_mat;
end