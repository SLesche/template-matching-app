function init_review_overview_table(app)
    % Create new figure
    app.table_window = uifigure('Name', 'Overview');
    app.table_window.Position = [800 500 625 300];

    colnames = {'ERP', 'bin', 'a', 'b', 'latency', 'fit_cor', 'fit_dist', 'status', 'decision', 'inspect'};
    types = {'char', 'char', 'numeric', 'numeric', 'numeric', 'numeric', 'numeric', 'char', 'char', 'logical'};

    data = prep_overview_table_data(app.final_mat);

    % Create the table
    app.overview_table = uitable(app.table_window, ...
        'ColumnEditable', [false(1, width(data)-1), true], ...
        'CellEditCallback', @(src, event) handleButtonClickTable(src, event) ...
        );
    app.overview_table.Position = [10 10 555 280];
    app.overview_table.ColumnName = colnames;  % customize columns
    app.overview_table.ColumnWidth = {40, 40, 50, 50, 65, 60, 60, 60, 70, 90};
    app.overview_table.ColumnFormat = types;  % customize column types
    app.overview_table.Data = data;  % initially populate

    apply_styles_to_overview_table(app);  % apply styles to the table

    function handleButtonClickTable(src, event)
        if strcmp(src.ColumnName{event.Indices(2)}, 'inspect')
            src.Data.Inspect(:) = false;
            src.Data.Inspect(event.Indices(1)) = true;
    
            selectedRow = src.Data(event.Indices(1), :);

            disp(['Inspecting ERP = ', selectedRow.ERP{1}, ', bin = ', selectedRow.bin{1}]);

            load_new_plot(app, str2double(selectedRow.ERP{1}), str2double(selectedRow.bin{1}));
        end
    end
end