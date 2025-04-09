function jump_to_next_review(app)
    current_erp = app.erp_num;
    current_bin = app.bin_num;

    flag_layer = app.final_mat(:, :, 6);
    [erp_max, bin_max] = size(flag_layer);

    % Linear index in row-major order (like going across bins then down erps)
    start_idx = (current_erp - 1) * bin_max + current_bin;

    % Flatten in row-major order
    flag_vec = reshape(flag_layer.', [], 1);  % Transpose to simulate row-major

    % Find all indices with flag == 1 after start
    next_idx = find(flag_vec > 0 & (1:numel(flag_vec))' > start_idx, 1);

    if isempty(next_idx)
        warning("No more reviews left")
    else
        % Reverse the row-major index back to (erp, bin)
        [app.bin_num, app.erp_num] = ind2sub([bin_max, erp_max], next_idx);
    end
end