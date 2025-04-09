function update_plot(app)
    hold(app.erp_display, 'on');
    %{
    [corr, ~, latency, ~, a, b] = get_matching_results(app);

    if app.fitting_approach == "corr"
        plot_color = 'red';
    elseif app.fitting_approach == "minsq"
        plot_color = 'blue';
    end
    %}

    delete(app.ga_plot)
    %delete(app.matched_xline)

    ga_x = app.time_vector;
    % current_erp_num = app.erp_num;
    current_bin = app.bin_num;
    
    % % Get the cfg parameters
    % polarity = app.cfg.polarity;
    % electrodes = app.cfg.electrodes;
    % window = app.cfg.window;
    % approach = app.cfg.approach;
    
    ga_y = app.ga_mat(current_bin, :);
    
    matched_ga_x = ga_x .* app.b_param_continuous;
    matched_ga_y = ga_y / app.a_param_continuous;

    % Maybe update fit / latency here?
    app.ga_plot = plot(matched_ga_x, matched_ga_y, "--", 'DisplayName', 'Grand Average Waveform', 'Parent', app.erp_display);
    %app.matched_xline = xline(app.erp_display, latency, 'Color', plot_color);

    hold(app.erp_display, 'off');

    update_fit_display(app)
end