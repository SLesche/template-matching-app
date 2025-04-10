function init_review_overview_table(app)
    % Create new figure
    app.table_window = uifigure('Name', 'Overview');
    app.table_window.Position = [800 500 575 300];

    colnames = {'ERP', 'bin', 'a', 'b', 'latency', 'fit_cor', 'fit_dist', 'status', 'decision'};
    types = {'char', 'char', 'numeric', 'numeric', 'numeric', 'numeric', 'numeric', 'char', 'char'};

    data = prep_overview_table_data(app.final_mat);

    % Create the table
    app.overview_table = uitable(app.table_window);
    app.overview_table.Position = [10 10 555 280];
    app.overview_table.ColumnName = colnames;  % customize columns
    app.overview_table.ColumnWidth = {40, 40, 50, 50, 65, 60, 60, 60, 70};
    app.overview_table.ColumnFormat = types;  % customize column types

    app.overview_table.Data = data;  % initially populate

    apply_styles_to_overview_table(app);  % apply styles to the table
end