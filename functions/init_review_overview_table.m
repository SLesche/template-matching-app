function init_review_overview_table(app)
    % Create new figure
    app.table_window = uifigure('Name', 'Overview');
    app.table_window.Position = [200 200 500 300];

    % Create the table
    app.overview_table = uitable(app.table_window);
    app.overview_table.Position = [10 10 480 280];
    app.overview_table.ColumnName = {'erp_num', 'bin_num', 'a', 'b', 'latency', 'fit_cor', 'fit_dist', 'review_flag', 'decision'};  % customize columns
    app.overview_table.Data = prep_overview_table_data(app.final_mat);  % initially populate
end