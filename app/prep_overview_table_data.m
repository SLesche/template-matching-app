function [table_data] = prep_overview_table_data(final_mat)
    [n_erps, n_bins, n_params] = size(final_mat);
    
    flat_params = round(reshape(final_mat, [], n_params), 2);  % size: (n_erps * n_bins) x n_params

    % ERP indices (repeated per bin)
    erp_idx = round(repelem((1:n_erps)', n_bins), 0);  % column vector
    
    % Bin indices (cycled for each ERP)
    bin_idx = round(repmat((1:n_bins)', n_erps, 1), 0);  % column vector

    table_data = [erp_idx, bin_idx, flat_params];
    table_data(:, end-1) = round(table_data(:, end-1), 0);
    table_data(:, end) = round(table_data(:, end), 0);

    % Convert whole table to char
    table_data = cellfun(@num2str, num2cell(table_data), 'UniformOutput', false);

    % Helper function for transforming decision codes
    function result = transform_decision_code(value, flag)
        if str2double(flag) == 1 && str2double(value) == 0
            result = '⚠';  % Warning sign
        elseif str2double(value) == 0
            result = 'default';
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
    table_data(:, end) = cellfun(@(x, flag) transform_decision_code(x, flag), table_data(:, end), table_data(:, end-1), 'UniformOutput', false);

    % In review_flag, convert 0 to checkmark and 1 to warning sign
    table_data(:, end-1) = cellfun(@(x) strrep(x, '0', '✓'), table_data(:, end-1), 'UniformOutput', false);
    table_data(:, end-1) = cellfun(@(x) strrep(x, '1', '⚠'), table_data(:, end-1), 'UniformOutput', false);

    % Transform numeric decision codes to strings
    % Define the mapping
    % codeMap = containers.Map({'0', '-1', '1', '2'}, {'default', 'reject', 'accept', 'manual'});

    % % Apply the mapping using cellfun
    % table_data(:, end) = cellfun(@(x) codeMap(x), table_data(:, end), 'UniformOutput', false);

    


end