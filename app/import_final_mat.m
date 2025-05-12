function final_mat = import_final_mat(app)
    % This function opens a file dialog to select and import a final_mat-style CSV,
    % then reshapes it into a 3D matrix [n_erps × n_bins × n_params].

    % Prompt user to select a CSV file
    [filename, pathname] = uigetfile('*.csv', 'Select a final_mat CSV file');
    if isequal(filename, 0)
        disp('File selection cancelled.');
        final_mat = [];
        return;
    end
    fullpath = fullfile(pathname, filename);

    % Read the CSV file into a table
    try
        T = readtable(fullpath);
        disp(T)
    catch ME
        error('Failed to read CSV: %s', ME.message);
    end

    % Check that required columns exist
    required_columns = {'erp_num', 'bin_num', 'a_param', 'b_param', ...
                        'latency', 'fit_cor', 'fit_dist', 'review_flag', 'decision'};
    if ~all(ismember(required_columns, T.Properties.VariableNames))
        error('CSV is missing one or more required columns.');
    end

    % Extract relevant numeric data
    param_data = table2array(T(:, {'a_param', 'b_param', 'latency', ...
                                   'fit_cor', 'fit_dist', 'review_flag', 'decision'}));

    % Determine ERP/bin structure
    n_erps = max(T.erp_num);
    n_bins = max(T.bin_num);
    n_params = size(param_data, 2);

    % Initialize output matrix
    final_mat = nan(n_erps, n_bins, n_params);

    % Fill final_mat using ERP/bin indices
    for i = 1:height(T)
        e = T.erp_num(i);
        b = T.bin_num(i);
        final_mat(e, b, :) = param_data(i, :);
    end

    % Make sure app.results_mat and app.final_mat have same size 
    if size(app.results_mat) ~= (size(final_mat) - [0, 0 , 2])
        error('Size mismatch: app.results_mat and final_mat must have the same dimensions.');
    end

    disp(['final_mat imported from: ', fullpath]);
end
