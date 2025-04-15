function display_settings_window(app, event)
    % Create the settings window
    app.settings_window = uifigure('Name', 'Settings', 'Position', [300, 300, 420, 320]);

    % Tab group
    tabGroup = uitabgroup(app.settings_window, 'Position', [10 10 400 300]);

    %% === Plot Settings Tab ===
    plotTab = uitab(tabGroup, 'Title', 'Plot Settings');

    uilabel(plotTab, 'Text', 'Line Width:', 'Position', [20 220 100 22]);
    app.lineWidthField = uieditfield(plotTab, 'numeric', ...
        'Value', app.settings.line_width, ...
        'Position', [130 220 50 22]);

    uilabel(plotTab, 'Text', 'Y Lim Lower:', 'Position', [20 180 100 22]);
    app.ylimlowerField = uieditfield(plotTab, 'numeric', ...
        'Value', app.settings.ylimlower, ...
        'Position', [130 180 50 22]);

    uilabel(plotTab, 'Text', 'Y Lim Upper:', 'Position', [20 140 100 22]);
    app.ylimupperField = uieditfield(plotTab, 'numeric', ...
        'Value', app.settings.ylimupper, ...
        'Position', [130 140 50 22]);

    app.displayLegendField = uicheckbox(plotTab, ...
        'Text', 'Show Legend', ...
        'Value', app.settings.display_legend, ...
        'Position', [20 100 120 22]);

    app.displayInfoField = uicheckbox(plotTab, ...
        'Text', 'Show Info Box', ...
        'Value', app.settings.display_info, ...
        'Position', [20 70 120 22]);

    %% === Button Behavior Tab ===
    buttonTab = uitab(tabGroup, 'Title', 'Button Behavior');

    uilabel(buttonTab, 'Text', 'Auto Jump After:', 'Position', [20 220 120 22]);
    app.autoJumpField = uidropdown(buttonTab, ...
        'Items', {'Jump to next review', 'Move to next ERP', 'Do not move'}, ...
        'Value', app.settings.auto_jump_behavior, ...
        'Position', [150 220 100 22]);

    %% === Overview Table Filters Tab ===
    filterTab = uitab(tabGroup, 'Title', 'Overview Table');

    % Multi-select list for Decision Filter
    uilabel(filterTab, 'Text', 'Filter by Decision:', 'Position', [20 220 120 22]);
    app.filterDecisionField = uidropdown(filterTab, ...
        'Items', {'All', 'review', 'accept', 'reject', 'default', 'manual'}, ...
        'Value', app.settings.filter_decision, ... % default selection
        'Position', [150 180 120 60]);

    % Expression field for Fit filter
    uilabel(filterTab, 'Text', 'Fit Status Expression:', 'Position', [20 130 140 22]);
    app.filterFitField = uieditfield(filterTab, 'text', ...
        'Placeholder', 'e.g., < 0.6', ...
        'Value', '', ...
        'Position', [170 130 180 22]);

    uilabel(filterTab, 'Text', 'Filter by Status:', 'Position', [20 140 120 22]);
    app.filterStatusField = uidropdown(filterTab, ...
        'Items', {'All', 'flagged only', 'unflagged only'}, ...
        'Value', app.settings.filter_status, ...
        'Position', [150 140 100 22]);

    %% === Apply Button ===
    uibutton(app.settings_window, ...
        'Text', 'Apply Settings', ...
        'Position', [270 10 120 30], ...
        'ButtonPushedFcn', @(btn, event) apply_settings(app));

        %% === Cancel Button ===
    uibutton(app.settings_window, ...
        'Text', 'Cancel', ...
        'Position', [150 10 120 30], ...
        'ButtonPushedFcn', @(btn, event) cancel_settings(app));
end



function apply_settings(app)
    app.settings.ylimlower = app.ylimlowerField.Value;
    app.settings.ylimupper = app.ylimupperField.Value;
    app.settings.line_width = app.lineWidthField.Value;
    app.settings.display_legend = app.displayLegendField.Value;
    app.settings.display_info = app.displayInfoField.Value;
    app.settings.auto_jump_behavior = app.autoJumpField.Value;
    app.settings.filter_decision = app.filterDecisionField.Value;
    app.settings.filter_fit = app.filterFitField.Value;
    app.settings.filter_status = app.filterStatusField.Value;

    load_new_plot(app);

    close(app.settings_window);
end

function cancel_settings(app)
    % Close the settings window without applying changes
    close(app.settings_window);
end
