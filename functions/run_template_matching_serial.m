function [results_mat] = run_template_matching_serial(erp_mat, time_vec, cfg)                 
    polarity = cfg.polarity;
    electrodes = cfg.electrodes;
    window = cfg.window;

    approach = cfg.approach;
    if approach == "minsq" || approach == "maxcor"
        is_template_matching = 1;
    elseif approach == "area" || approach == "peak" || approach == "liesefeldarea"
        is_template_matching = 0;
    else
        error("Set a proper matching approach")
    end

    if cfg.weight ~= "none"
        weight_function = eval(strcat("@", cfg.weight));
    else
        weight_function = @(time_vector, signal, window) ones(length(time_vector), 1);
    end

    if cfg.penalty ~= "none"
        penalty_function = eval(strcat("@", cfg.penalty));
    else 
        penalty_function = @(a, b) 1;
    end

    if cfg.normalization ~= "none"
        normalize_function = eval(strcat("@", cfg.normalization)); 
    else
        normalize_function = @(x) x;
    end

    if approach == "minsq"
        eval_function = @eval_sum_of_squares;
        fix_a_param = 0;
    elseif approach == "maxcor"
        eval_function = @eval_correlation;
        fix_a_param = 1;
    end

    use_derivative = cfg.use_derivative;

    n_erps = size(erp_mat, 1);
    n_params = 5;
    n_bins = size(erp_mat, 4);

    results = zeros([n_erps, n_bins, n_params]);

    total_iters = n_bins * n_erps;
    current_iter = 0;

    % Initialize uiwaitbar
    h = waitbar(0, 'Starting template matching...'); 

    for ibin = 1:n_bins
        match_results = zeros(n_erps, n_params);
    
        ga = squeeze(mean(erp_mat(:, electrodes, :, ibin), 1, 'omitnan'));
    
        if is_template_matching
            lat_ga = approx_peak_latency(time_vec, ga, [window(1) window(2)], polarity);
    
            for ierp = 1:n_erps
                current_iter = current_iter + 1;
    
                signal = squeeze(erp_mat(ierp, electrodes, :, ibin));
                if all(isnan(signal)) || all(signal == 0)
                    match_results(ierp, :) = NaN;
                else
                    try
                        params = run_global_search(define_optim_problem(specify_objective_function( ...
                            time_vec', signal, ga, [window(1) window(2)], polarity, ...
                            weight_function, eval_function, normalize_function, ...
                            penalty_function, use_derivative, fix_a_param), fix_a_param));
                    catch ME
                        disp('--- An error occurred ---');
                        disp(ME.message);
                        disp([ibin, ierp])
                        rethrow(ME);
                    end
    
                    if fix_a_param == 1
                        params = [1 params];
                    end
    
                    match_results(ierp, [1 2]) = params;
                    match_results(ierp, 3) = return_matched_latency(params(2), lat_ga);
                    match_results(ierp, [4 5]) = get_fits(time_vec', signal, ga, ...
                        [window(1) window(2)], polarity, weight_function, ...
                        params(1), params(2));
                end
    
                % Update the progress in the waitbar
                percentDone = 100 * current_iter / total_iters;
                waitbar(percentDone / 100, h, sprintf('Progress: %3.1f%% (%d/%d)', percentDone, current_iter, total_iters));
            end
        else
            for ierp = 1:n_erps
                current_iter = current_iter + 1;
    
                signal = squeeze(erp_mat(ierp, electrodes, :, ibin));
    
                if all(isnan(signal)) || all(signal == 0)
                    match_results(ierp, :) = NaN;
                else
                    if approach == "area"
                        latency = approx_area_latency(time_vec, signal, [window(1) window(2)], polarity, 0.5);
                    elseif approach == "liesefeld_area"
                        latency = approx_area_latency(time_vec, signal, [window(1) window(2)], polarity, 0.5, true);
                    elseif approach == "peak"
                        latency = approx_peak_latency(time_vec, signal, [window(1) window(2)], polarity);
                    end
                    match_results(ierp, [1 2 4 5]) = NaN;
                    match_results(ierp, 3) = latency;
                end

                % Update the progress in the waitbar
                percentDone = 100 * current_iter / total_iters;
                waitbar(percentDone / 100, h, sprintf('Progress: %3.1f%% (%d/%d)', percentDone, current_iter, total_iters));
            end
        end
    
        results(:, ibin, :) = match_results;
    end
    
    % Close the waitbar
    close(h);
    
    fprintf('\nDone.\n');
    
    results_mat = results;

end
