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

    for ibin = 1:n_bins
        match_results = zeros(n_erps, n_params);
        % Get the GA here, get corresponding approach and other pars
        ga = squeeze(mean(erp_mat(:, electrodes, :, ibin), 1, 'omitnan'));                            
        % Get the appropriate measurement window                    
        if is_template_matching
            lat_ga = approx_peak_latency(time_vec, ga, [window(1) window(2)], polarity);

            % lat_ga = approx_area_latency(time_vec, ga, [window(1) window(2)], polarity, 0.5, true);

            for ierp = 1:n_erps
                signal = squeeze(erp_mat(ierp, electrodes, :, ibin));
                if all(isnan(signal)) || all(signal == 0)
                    match_results(ierp, :) = NaN;
                else
                    try
                        params = run_global_search(define_optim_problem(specify_objective_function(time_vec', signal, ga, [window(1) window(2)], polarity, weight_function, eval_function, normalize_function ,penalty_function, use_derivative, fix_a_param), fix_a_param));
                    catch ME
                            % If an error occurs, log the variables and rethrow the error
                        disp('--- An error occurred ---');
                        disp('Error message:');
                        disp(ME.message);
                        disp([ibin, ierp])
                
                        % Log the input variables
                        disp('--- Input Variables ---');
                        disp('time_vec:');
                        disp(time_vec);
                        disp('signal:');
                        disp(signal);
                        disp('ga:');
                        disp(ga);
                        disp('window:');
                        disp(window);
                        disp('polarity:');
                        disp(polarity);
                        disp('weight_function:');
                        disp(weight_function);
                        disp('eval_function:');
                        disp(eval_function);
                        disp('normalize_function:');
                        disp(normalize_function);
                        disp('penalty_function:');
                        disp(penalty_function);
                        disp('use_derivative:');
                        disp(use_derivative);
                        disp('-----------------------');
                
                        % Rethrow the error to handle it further up the call stack if necessary
                        rethrow(ME);
                    end

                    if fix_a_param == 1
                        params = [1 params];
                    end
                    
                    match_results(ierp, [1 2]) = params;
                    match_results(ierp, 3) = return_matched_latency(params(2), lat_ga);
                    match_results(ierp, [4 5]) = get_fits(time_vec', signal, ga, [window(1) window(2)], polarity, weight_function, params(1), params(2));
                    
                end
            end
        else
            for ierp = 1:n_erps
                latency = NaN;
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
            end
        end

        results(:, ibin, :) = match_results;
    end

    results_mat = results;

end