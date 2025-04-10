function [table_data] = prep_overview_table_data(final_mat)
    [n_erps, n_bins, n_params] = size(final_mat);
    
    flat_params = round(reshape(final_mat, [], n_params), 2);  % size: (n_erps * n_bins) x n_params

    % ERP indices (repeated per bin)
    erp_idx = round(repelem((1:n_erps)', n_bins), 0);  % column vector
    
    % Bin indices (cycled for each ERP)
    bin_idx = round(repmat((1:n_bins)', n_erps, 1), 0);  % column vector

    table_data = [erp_idx, bin_idx, flat_params];
    table_data(:, end-1) = round(table_data(:, 6), 0);
    table_data(:, end) = round(table_data(:, 7), 0);

    % Convert whole table to char
    table_data = cellfun(@num2str, num2cell(table_data), 'UniformOutput', false);
end