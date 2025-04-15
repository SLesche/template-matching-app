function [table_data] = prep_overview_table_data(app)
    final_mat = app.final_mat;
    [n_erps, n_bins, n_params] = size(final_mat);
    
    flat_params = reshape(permute(final_mat, [2, 1, 3]), [], n_params); % To make ERPs go first, then bins
    flat_params = round(flat_params, 2);  % Round to two decimal places

    % ERP indices (repeated per bin)
    erp_idx = round(repelem((1:n_erps)', n_bins), 0);  % column vector
    
    % Bin indices (cycled for each ERP)
    bin_idx = round(repmat((1:n_bins)', n_erps, 1), 0);  % column vector

    table_data = [erp_idx, bin_idx, flat_params, zeros(size(erp_idx, 1), 1)];  % Initialize table data with zeros for inspect
    table_data(:, end-2) = round(table_data(:, end-2), 0);
    table_data(:, end-1) = round(table_data(:, end-1), 0);

    % Convert whole table to char
    table_data = cellfun(@num2str, num2cell(table_data), 'UniformOutput', false);
    
    % Helper function for transforming decision codes
    function result = transform_decision_code(value, flag)
        if str2double(flag) == 1 && str2double(value) == 0
            result = 'review';  % Warning sign
        elseif str2double(value) == 0
            result = 'auto';
        elseif str2double(value) == -1
            result = 'reject';
        elseif str2double(value) == 1
            result = 'accept';
        elseif str2double(value) == 2
            result = 'manual';
        else
            result = 'unknown';  % Fallback for unexpected values
        end
    end

    % Apply the helper function to transform the last column of the table
    table_data(:, end-1) = cellfun(@(x, flag) transform_decision_code(x, flag), table_data(:, end-1), table_data(:, end-2), 'UniformOutput', false);

    % In review_flag, convert 0 to checkmark and 1 to warning sign
    table_data(:, end-2) = cellfun(@(x) strrep(x, '0', '✓'), table_data(:, end-2), 'UniformOutput', false);
    table_data(:, end-2) = cellfun(@(x) strrep(x, '1', '⚠'), table_data(:, end-2), 'UniformOutput', false);

    
    % === Filter table data ===
    decision_include = app.settings.filter_decision;
    fit_include      = app.settings.filter_fit;
    status_include   = app.settings.filter_status;

    % disp("Filtering table data...")
    % disp("Decision filter: " + decision_include)
    % disp("Fit filter: " + fit_include)
    % disp("Status filter: " + status_include)

    % --- Handle status include translation
    switch status_include
        case 'flagged only'
            status_value = 1;
        case 'unflagged only'
            status_value = 0;
        otherwise
            status_value = 'All';
    end

    % --- Decision filter
    if ~strcmp(decision_include, 'All')
        decision_col = table_data(:, end-1);  % assuming this is the 'decision' column
        decision_filter = ismember(decision_col, decision_include);
        table_data = table_data(decision_filter, :);
    end

    % --- Fit filter (expression-based)
    if ~isempty(strtrim(fit_include))
        try
            fit_values = str2double(cell2mat(table_data(:, 6)));  % numeric fit column
            fit_filter = eval(['fit_values ' fit_include]);  % e.g., '> 0.3'
            table_data = table_data(fit_filter, :);
        catch err
            warning('Invalid fit expression "%s". Skipping fit filter.\n%s', fit_include, err.message);
        end
    end

    % --- Status filter
    if ~strcmp(status_value, 'All')
        status_col = table_data(:, end-2);  % assuming this is the 'status' column
        status_filter = status_col == status_value;
        table_data = table_data(status_filter, :);
    end

    % --- Final check
    if isempty(table_data)
        warning('No data to display after filtering. Please adjust your filters.');
        return;
    end
end