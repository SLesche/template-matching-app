function [] = export_final_mat(app)
    % This function exports `app.final_mat` as a flattened 2D CSV file.
    % Output columns: ERP, Bin, A, B, Latency, Fit1, Fit2, Inspect (0)
    % Prompt user for file location
    [filename, pathname] = uiputfile('*.csv', 'Save final_mat as CSV');
    if isequal(filename, 0)
        disp('Export cancelled.');
        return;
    end
    fullpath = fullfile(pathname, filename);

    % Extract and reshape the final_mat
    final_mat = app.final_mat;
    [n_erps, n_bins, n_params] = size(final_mat);

    % Flatten: dimensions [ERP × Bin, params]
    flat_params = reshape(permute(final_mat, [2, 1, 3]), [], n_params);
    % flat_params = round(flat_params, 2);  % Round to 2 decimals

    % Generate ERP and Bin indices
    erp_idx = repelem((1:n_erps)', n_bins);  % Repeats for each bin
    bin_idx = repmat((1:n_bins)', n_erps, 1);  % Cycles for each ERP

    % Round latency and fits to integers
    % flat_params(:, end-2) = round(flat_params(:, end-2), 0);
    % flat_params(:, end-1) = round(flat_params(:, end-1), 0);

    % Assemble final table
    table_data = [erp_idx, bin_idx, flat_params];

    % Define header
    header = {'erp_num', 'bin_num', 'a_param', 'b_param', 'latency', 'fit_cor', 'fit_dist', 'review_flag', 'decision'};

    try
        % Convert matrix to table
        table_out = array2table(table_data, 'VariableNames', header);

        % Write table to CSV
        writetable(table_out, fullpath);

        disp(['final_mat exported to: ', fullpath]);
    catch ME
        error('Error writing CSV: %s', ME.message);
    end
    
end
