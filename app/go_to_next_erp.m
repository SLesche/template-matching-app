function go_to_next_erp(app)
    % Current ERP/bin
    current_erp = app.erp_num;
    current_bin = app.bin_num;

    % Get overview table data (assumed ERP and Bin are in cols 1 and 2)
    erp_col = str2double(app.overview_table.Data(:, 1));
    bin_col = str2double(app.overview_table.Data(:, 2));

    % Combine ERP/Bin pairs
    table_pairs = [erp_col, bin_col];

    % Current pair
    current_pair = [current_erp, current_bin];

    % Find current index
    current_idx = find(ismember(table_pairs, current_pair, 'rows'), 1);

    if isempty(current_idx)
        % If current not found, find next larger pair
        next_idx = find(all(table_pairs > current_pair, 2), 1);
        if isempty(next_idx)
            warning("Already at or beyond last entry in overview table");
            return;
        end
    else
        next_idx = current_idx + 1;
        if next_idx > size(table_pairs, 1)
            warning("Already at the last entry in overview table");
            return;
        end
    end

    % Get the next ERP/bin from sorted list
    next_pair = table_pairs(next_idx, :);
    app.erp_num = next_pair(1);
    app.bin_num = next_pair(2);
end
