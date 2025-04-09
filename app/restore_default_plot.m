function restore_default_plot(app, source)
    if ~exist('source', 'var')
        source = "reviewed";
    end

    % reload all plots for that erp, set a and b to their
    % solutions
    app.method = app.baseline_method;
    app.erp = app.review_mat(app.ireview, 1);
    app.bin = app.review_mat(app.ireview, 2);
    [app.a_param, app.b_param, ~, ~, ~] = extract_optimized_params(app, source);
    [app.a_param_continuous, app.b_param_continuous, ~, ~, ~] = extract_optimized_params(app, source);
    app.bin_selection_field.Value = '';
    update_param_displays(app)
    plot_latency(app)
    update_dropdown_items(app)
end