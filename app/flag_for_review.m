function flag_for_review(app)
    [n_subjects, n_bins, n_params] = size(app.results_mat);
    
    for isubject = 1:n_subjects
        for ibin = 1:n_bins
            is_low_fit = app.results_mat(isubject, ibin, 4) <= app.cfg.cutoff; 
            is_extreme_b = app.results_mat(isubject, ibin, 2) <= (1 / app.cfg.extreme_b) || app.results_mat(isubject, ibin, 2) >= app.cfg.extreme_b;
            is_extreme_a = app.results_mat(isubject, ibin, 1) <= 0.2 || app.results_mat(isubject, ibin, 1) >= 5;
            
            if app.cfg.extreme_b ~= 99 && any([is_low_fit, is_extreme_a, is_extreme_b])
                app.final_mat(ierp, ibin, n_params+1) = 1;
            else
                app.final_mat(ierp, ibin, n_params+1) = 0;
            end
        end
    end
end