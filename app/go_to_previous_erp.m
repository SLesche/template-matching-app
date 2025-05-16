function go_to_previous_erp(app)
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

    % Sort all pairs in ERP-major order
    [~, sorted_idx] = sortrows(table_pairs, [1 2]);
    sorted_pairs = table_pairs(sorted_idx, :);

    % Find current index
    current_idx = find(ismember(sorted_pairs, current_pair, 'rows'), 1);

    if isempty(current_idx)
        % If current not found, find the last pair that's smaller
        prev_idx = find(all(sorted_pairs < current_pair, 2), 1, 'last');
        if isempty(prev_idx)
            warning("Already at or before first entry in overview table");
            return;
        end
    else
        prev_idx = current_idx - 1;
        if prev_idx < 1
            warning("Already at the first entry in overview table");
            return;
        end
    end

    % Get the previous ERP/bin from sorted list
    prev_pair = sorted_pairs(prev_idx, :);
    app.erp_num = prev_pair(1);
    app.bin_num = prev_pair(2);
end
