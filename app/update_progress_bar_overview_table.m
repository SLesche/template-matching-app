function update_progress_bar_overview_table(app)
    data = app.overview_table.Data;
    total = height(data);
    decisionColumn = data(:, end - 1);

    % Count types
    count_accept_reject = sum(ismember(decisionColumn, {'accept', 'reject', 'manual'}));
    count_default = sum(ismember(decisionColumn, {'default'}));
    count_review = sum(ismember(decisionColumn, {'review'}));
    
    totalReviewed = count_accept_reject + count_default;

    % Width calculations
    containerWidth = app.progressContainer.Position(3);
    reviewedWidth = containerWidth * (count_accept_reject / total);
    defaultWidth = containerWidth * (count_default / total);

    % Update bar widths
    app.progressReviewedFill.Position = [defaultWidth, 0, reviewedWidth, 20];
    app.progressDefaultFill.Position = [0, 0, defaultWidth, 20];

    % Update label
    app.progressLabel.Text = sprintf('Of %d, %d accepted by default, %d reviewed - %d left to review', ...
        total, count_default, count_accept_reject, count_review);

    % If filtered, display a warning sign before the text
    if app.settings.filter_decision ~= "All" || ~isempty(app.settings.filter_fit) || app.settings.filter_status ~= "All"
        app.progressLabel.Text = ['⚠️ Filtered! | ' app.progressLabel.Text];
    end
end
