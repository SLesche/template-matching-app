function get_grand_averages(app)
    [~, ~, n_times, n_bins] = size(app.erp_mat);

    ga_mat = zeros([n_bins, n_times]);

    for ibin = 1:n_bins
        ga_mat(ibin, :) = squeeze(mean(app.erp_mat(:, app.cfg.electrodes, :, ibin), 1, 'omitnan'));
    end

    app.ga_mat = ga_mat;
end