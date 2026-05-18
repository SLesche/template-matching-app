function compute_ga_latencies(app)
    time_vec = app.time_vector;

    polarity = app.cfg.polarity;
    window = app.cfg.window;

    n_bins = size(app.erp_mat, 4);

    for bin = 1:n_bins
        if isnan(app.ga_latencies(bin))
            app.ga_latencies(bin) = approx_area_latency(time_vec, app.ga_mat(bin, :)', [window(1) window(2)], polarity);
        end
    end 

    % disp('Computed GA latencies:');
    % disp(app.ga_latencies);
end