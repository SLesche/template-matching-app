function apply_styles_to_overview_table(app)
    % Given values for app.erp_num and app.bin_num
    erp_num = app.erp_num;
    bin_num = app.bin_num;
    n_bins = app.nbins;
    
    % Assuming the table data structure is organized in a way where the first
    % two columns correspond to erp_num and bin_num respectively
    % (adjust indices if this assumption is incorrect)
    row_to_show = (erp_num - 1)*n_bins + bin_num;  % Calculate the row index
    
    % Ensure a valid row index is found
    if ~isempty(row_to_show)
        % Select the row in the overview table
        scroll(app.overview_table, "row", row_to_show);  % Scroll to the selected row

        app.overview_table.Data(:, end) = {false};  % Set the inspect column to false for all rows
        app.overview_table.Data(row_to_show, end) = {true};  % Set the inspect column to true for the selected row
    else
        scroll(app.overview_table, "row", 1);
        warning('Row not found for the given erp_num and bin_num');

        app.overview_table.Data(:, end) = {false};  % Set the inspect column to false for all rows
        app.overview_table.Data(1, end) = {true};  % Set the inspect column to true for the selected row
    end

    % Highlight active row
    % Create the style for highlighting the row
    highlight_style = uistyle('BackgroundColor', [0.8 0.8 1], 'FontWeight', 'normal');

    % Create the style for resetting the row (default style)
    reset_style = uistyle('BackgroundColor', [1 1 1], 'FontWeight', 'normal');

    % Apply the reset style to all rows
    addStyle(app.overview_table, reset_style);

    % Apply the highlight style to the selected row
    addStyle(app.overview_table, highlight_style, 'Row', row_to_show);

    % % Add icons based on decision, default is accepted
    % accepted_style = uistyle('BackgroundColor', [0.8 1 0.8], 'FontWeight', 'normal', 'Icon', 'success');
    % rejected_style = uistyle('BackgroundColor', [1 0.8 0.8], 'FontWeight', 'normal', 'Icon', 'error');
    % warning_style = uistyle('BackgroundColor', [1 1 0.8], 'FontWeight', 'normal', 'Icon', 'warning');

    % % Add icons in cells based on value in decision
    % accepted_cells = find(strcmp(app.overview_table.Data, 'accept') | ...
    %     strcmp(app.overview_table.Data, 'manual') | ...
    %     strcmp(app.overview_table.Data, 'default'));

    % accepted_cells

    % rejected_cells = find(strcmp(app.overview_table.Data, 'reject'));

    % warning_cells = find(strcmp(app.overview_table.Data, 'review'));


    % % Apply styles to the cells based on their values
    % addStyle(app.overview_table, accepted_style, 'Cell', accepted_cells);
    % addStyle(app.overview_table, rejected_style, 'Cell', rejected_cells);
    % addStyle(app.overview_table, warning_style, 'Cell', warning_cells);
end
