function jump_to_previous_review(app)
    current_erp = app.erp_num;
    current_bin = app.bin_num;

    % Extract ERP, Bin, and Review columns
    erp_col = str2double(app.overview_table.Data(:, 1));
    bin_col = str2double(app.overview_table.Data(:, 2));
    review_col = app.overview_table.Data(:, 9);
    table_pairs = [erp_col, bin_col];

    current_pair = [current_erp, current_bin];

    % Try to find exact match in the table
    current_idx = find(ismember(table_pairs, current_pair, 'rows'), 1);

    % ---------- CASE 1: Found current in table ----------
    if ~isempty(current_idx)
        for i = current_idx - 1 : -1 : 1
            if ischar(review_col{i}) && strcmpi(strtrim(review_col{i}), 'review')
                app.erp_num = erp_col(i);
                app.bin_num = bin_col(i);

                % Optional: scroll and highlight
                scroll(app.overview_table, "row", i);
                return;
            end
        end
    end

    % ---------- CASE 2: Not found or no match backward: search numerically ----------
    for i = size(app.overview_table.Data, 1) : -1 : 1
        if ischar(review_col{i}) && strcmpi(strtrim(review_col{i}), 'review')
            e = erp_col(i);
            b = bin_col(i);

            % Jump only to numerically prior entries
            if e < current_erp || (e == current_erp && b < current_bin)
                app.erp_num = e;
                app.bin_num = b;
                return;
            end
        end
    end

    warning("No previous 'review' entries found before current ERP/bin.");
end
