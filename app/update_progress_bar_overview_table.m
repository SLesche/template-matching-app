function update_progress_bar_overview_table(app)
    data = app.overview_table.Data;
    total = height(data);
    decisionColumn = data(:, end - 1);

    % Count types
    count_accept_reject = sum(ismember(decisionColumn, {'accept', 'reject'}));
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
    app.progressLabel.Text = sprintf('%d of %d reviewed or accepted by default (%.0f%%) - %d left to review', ...
        totalReviewed, total, 100 * totalReviewed / total, count_review);
end
