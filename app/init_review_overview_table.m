function init_review_overview_table(app)
    % Create new figure
    app.table_window = uifigure('Name', 'Overview');

    % Column definitions
    colnames = {'ERP', 'bin', 'a', 'b', 'latency', 'fit_cor', 'fit_dist', 'status', 'decision', 'view'};
    types = {'char', 'char', 'numeric', 'numeric', 'numeric', 'numeric', 'numeric', 'char', 'char', 'logical'};

    % Prepare data
    data = prep_overview_table_data(app.final_mat);

    % === Create the Table ===
    app.overview_table = uitable(app.table_window, ...
        'ColumnEditable', [false(1, width(data)-1), true], ...
        'CellEditCallback', @(src, event) handleButtonClickTable(src, event));
    app.overview_table.Position = [10 60 605 240];
    app.overview_table.ColumnName = colnames;
    app.overview_table.ColumnWidth = {40, 40, 50, 50, 65, 60, 60, 60, 70, 50};
    app.overview_table.ColumnFormat = types;
    app.overview_table.Data = data;

    % Apply custom table styling
    apply_styles_to_overview_table(app);

   % === Create Progress Bar Container ===
    app.progressContainer = uipanel(app.table_window, ...
        'Position', [10, 30, 605, 20], ...
        'BackgroundColor', [0.9 0.9 0.9], ...
        'BorderType', 'none');

    % === Fill for accepted/rejected
    app.progressReviewedFill = uipanel(app.progressContainer, ...
        'Position', [0, 0, 0, 20], ...
        'BackgroundColor', [0.2 0.6 1], ...
        'BorderType', 'none');

    % === Fill for default
    app.progressDefaultFill = uipanel(app.progressContainer, ...
        'Position', [0, 0, 0, 20], ...
        'BackgroundColor', [0.6 0.6 0.6], ...
        'BorderType', 'none');

    % === Progress Label
    app.progressLabel = uilabel(app.table_window, ...
        'Position', [10, 10, 605, 20], ...
        'HorizontalAlignment', 'left', ...
        'Text', '');


    % Initial update of progress bar
    update_progress_bar_overview_table(app);

    % === Callback and Update Logic ===
    function handleButtonClickTable(src, event)
        if strcmp(src.ColumnName{event.Indices(2)}, 'view')
            src.Data(:, end) = {false};  % clear all
            src.Data{event.Indices(1), end} = true;  % set clicked one to true

            selectedRow = src.Data(event.Indices(1), :);
            load_new_plot(app, str2double(selectedRow{1}), str2double(selectedRow{2}));
        end
    end
end
