function go_to_next_erp(app)
    current_erp = app.erp_num;
    current_bin = app.bin_num;

    flag_layer = app.final_mat(:, :, 6);
    [erp_max, bin_max] = size(flag_layer);

    if current_erp == erp_max && current_bin == bin_max
        warning("Already at the last review")
        return
    end

    if current_bin == bin_max
        current_bin = 1;
        current_erp = current_erp + 1;
    else
        current_bin = current_bin + 1;
    end

    if isempty(current_bin) || isempty(current_erp)
        warning("No more reviews left")
    else
        app.bin_num = current_bin;
        app.erp_num = current_erp;
    end
end