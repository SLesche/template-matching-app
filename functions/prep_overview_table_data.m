function [table_data] = prep_overview_table_data(final_mat)
    [n_erps, n_bins, n_params] = size(final_mat);
    
    flat_params = reshape(final_mat, [], n_params);  % size: (n_erps * n_bins) x n_params

    % ERP indices (repeated per bin)
    erp_idx = repelem((1:n_erps)', n_bins);  % column vector
    
    % Bin indices (cycled for each ERP)
    bin_idx = repmat((1:n_bins)', n_erps, 1);  % column vector

    table_data = [erp_idx, bin_idx, flat_params];
end