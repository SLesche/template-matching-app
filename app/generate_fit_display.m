function generate_fit_display(app)
    % use app.fitting approach and method, erp, bin and then
    % generate fit values for different b-params
    % display these using colors in the fit plot

    % generate the color plot indicating the fit for various
    % b-params
    b_params = linspace(0, 3, 1000);

    fit_values = zeros(1, length(b_params));

    % This function will provide new latency, fit_cor and fit_dist
    % estimates for updated a_params and b_params
    current_erp = app.erp_num;
    current_bin = app.bin_num;
    time_vec = app.time_vector;

    % Get the cfg parameters
    polarity = app.cfg.polarity;
    electrodes = app.cfg.electrodes;
    window = app.cfg.window;
    approach = app.cfg.approach;

    if approach == "minsq" || approach == "maxcor"
       is_template_matching = 1;
    elseif approach == "area" || approach == "peak" || approach == "liesefeldarea"
        is_template_matching = 0;
    else
        error("Set a proper matching approach")
    end

    if app.cfg.weight ~= "none"
        weight_function = eval(strcat("@", app.cfg.weight));
    else
        weight_function = @(time_vector, signal, window) ones(length(time_vector), 1);
    end

    ga = app.ga_mat(current_bin, :)';
    
    if is_template_matching
        signal = squeeze(app.erp_mat(current_erp, electrodes, :, current_bin));
        if all(isnan(signal)) || all(signal == 0)
            fit_values = NaN;
        else
            for i = 1:length(b_params)
                current_b = b_params(i);
                fits = get_fits(time_vec', signal, ga, [window(1) window(2)], polarity, weight_function, app.a_param, current_b);
                fit_cor = fits(1);
                
                % make this maxcor and minsq compatible
                fit_values(i) = fit_cor;
            end
        end
    else
        % In the case of non-template matching, updating a and b
        % will not change anything, so we can just extract the
        % already optimized params
        fit_values = NaN;
    end

    plot(app.fit_display, b_params, fit_values)
    app.fit_xline = xline(app.fit_display, app.b_param);
end