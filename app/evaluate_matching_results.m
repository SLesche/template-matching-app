function [a_param, b_param, latency, fit_cor, fit_dist] = evaluate_matching_results(app)
    % This function will provide new latency, fit_cor and fit_dist
    % estimates for updated a_params and b_params
    current_erp_num = app.erp_num;
    current_bin = app.bin_num;
    time_vec = app.time_vector;

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
        if isempty(app.ga_latencies)
            lat_ga = approx_peak_latency(time_vec, ga, [window(1) window(2)], polarity);
        else
            lat_ga = app.ga_latencies(current_bin);
        end  
        signal = squeeze(app.erp_mat(current_erp_num, electrodes, :, current_bin));
        if all(isnan(signal)) || all(signal == 0)
            [a_param, b_param, latency, fit_cor, fit_dist] = NaN;
        else
            a_param = app.a_param;
            b_param = app.b_param;
            latency = return_matched_latency(b_param, lat_ga);
            fits = get_fits(time_vec', signal, ga, [window(1) window(2)], polarity, weight_function, a_param, b_param);
            fit_cor = fits(1);
            fit_dist = fits(2);
        end
    else
        % In the case of non-template matching, updating a and b
        % will not change anything, so we can just extract the
        % already optimized params
        [a_param, b_param, latency, fit_cor, fit_dist] = extract_optimized_params(app);
    end
end