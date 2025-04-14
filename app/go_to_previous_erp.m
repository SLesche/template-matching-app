function go_to_previous_erp(app)
    current_erp = app.erp_num;
    current_bin = app.bin_num;

    flag_layer = app.final_mat(:, :, 6);
    [erp_max, bin_max] = size(flag_layer);

    if current_erp == 1 && current_bin == 1
        warning("Already at the first review")
        return
    end

    if current_bin == bin_max
        if bin_max == 1
            current_erp = current_erp - 1;
        else
            current_bin = current_bin - 1;
        end
    elseif current_bin == 1
        current_bin = bin_max;
        current_erp = current_erp - 1;
    else
        current_bin = current_bin - 1;
    end

    if isempty(current_bin) || isempty(current_erp)
        warning("No more reviews left")
    else
        app.bin_num = current_bin;
        app.erp_num = current_erp;
    end
end