function load_new_plot(app, erp_num, bin_num)

    % Check if the erp_num and bin_num are valid
    if exist('erp_num', 'var') 
        app.erp_num = erp_num;
    end

    if exist('bin_num', 'var') 
        app.bin_num = bin_num;
    end

    restore_default_plot(app)

    generate_fit_display(app)

    update_overview_table(app)
end