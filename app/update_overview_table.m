function update_overview_table(app)
    app.overview_table.Data = prep_overview_table_data(app.final_mat);

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
    else
        scroll(app.overview_table, "row", 1);
        warning('Row not found for the given erp_num and bin_num');
    end
end

