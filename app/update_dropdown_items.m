function update_dropdown_items(app)
    items = 1:app.nbins;
    app.bin_dropdown.Items = cellfun(@num2str, num2cell(items), 'UniformOutput', false);
    app.bin_dropdown.Value = num2str(app.bin_num);

    app.erp_selection_field.Value = app.erp_num;
end