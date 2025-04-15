function update_overview_table(app)
    app.overview_table.Data = prep_overview_table_data(app);

    apply_styles_to_overview_table(app);

    update_progress_bar_overview_table(app);
end

