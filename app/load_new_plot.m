function load_new_plot(app, erp_num, bin_num)

    % Check if the erp_num and bin_num are valid
    if exist('erp_num', 'var') 
        app.erp_num = erp_num;
    end

    if exist('bin_num', 'var') 
        app.bin_num = bin_num;
    end

    % tic();
    restore_default_plot(app, "reviewed")
    % toc();

    % tic();
    generate_fit_display(app)
    % toc();

    % tic();
    update_overview_table(app)
    % toc();
end