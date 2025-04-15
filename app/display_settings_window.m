function display_settings_window(app, event)
    % Create the settings window
    app.settings_window = uifigure('Name', 'Settings', 'Position', [300, 300, 420, 360]);

    % Tab group
    tabGroup = uitabgroup(app.settings_window, 'Position', [10 60 400 280]);

    %% === Plot Settings Tab ===
    plotTab = uitab(tabGroup, 'Title', 'Plot Settings');
    
    % Line Width
    uilabel(plotTab, 'Text', 'Line Width:', 'Position', [20 220 100 22]);
    app.lineWidthField = uieditfield(plotTab, 'numeric', ...
        'Value', app.settings.line_width, ...
        'Position', [130 220 50 22]);

    % Y Lim Lower
    uilabel(plotTab, 'Text', 'Y Lim Lower:', 'Position', [20 180 100 22]);
    app.ylimlowerField = uieditfield(plotTab, 'numeric', ...
        'Value', app.settings.ylimlower, ...
        'Position', [130 180 50 22]);

    % Y Lim Upper
    uilabel(plotTab, 'Text', 'Y Lim Upper:', 'Position', [20 140 100 22]);
    app.ylimupperField = uieditfield(plotTab, 'numeric', ...
        'Value', app.settings.ylimupper, ...
        'Position', [130 140 50 22]);

    % Show Legend
    app.displayLegendField = uicheckbox(plotTab, ...
        'Text', 'Show Legend', ...
        'Value', app.settings.display_legend, ...
        'Position', [20 100 120 22]);

    % Show Info Box
    app.displayInfoField = uicheckbox(plotTab, ...
        'Text', 'Show Info Box', ...
        'Value', app.settings.display_info, ...
        'Position', [20 70 120 22]);

    %% === Button Behavior Tab ===
    buttonTab = uitab(tabGroup, 'Title', 'Button Behavior');

    % Auto Jump Behavior
    uilabel(buttonTab, 'Text', 'Auto Jump After:', 'Position', [20 220 120 22]);
    app.autoJumpField = uidropdown(buttonTab, ...
        'Items', {'Jump to next review', 'Move to next ERP', 'Do not move'}, ...
        'Value', app.settings.auto_jump_behavior, ...
        'Position', [150 220 160 22]);

    %% === Overview Table Filters Tab ===
    filterTab = uitab(tabGroup, 'Title', 'Overview Table');

    % Decision Filter Dropdown
    uilabel(filterTab, 'Text', 'Filter by Decision:', 'Position', [20 220 120 22]);
    app.filterDecisionField = uidropdown(filterTab, ...
        'Items', {'All', 'auto', 'review', 'accept', 'reject', 'manual'}, ...
        'Value', app.settings.filter_decision, ...
        'Position', [150 220 160 22]);

    % Fit Status Expression Field
    uilabel(filterTab, 'Text', 'Fit Status Expression:', 'Position', [20 170 140 22]);
    app.filterFitField = uieditfield(filterTab, 'text', ...
        'Placeholder', 'e.g., < 0.6', ...
        'Value', app.settings.filter_fit, ...
        'Position', [170 170 180 22]);

    % Status Filter Dropdown
    uilabel(filterTab, 'Text', 'Filter by Status:', 'Position', [20 120 120 22]);
    app.filterStatusField = uidropdown(filterTab, ...
        'Items', {'All', 'flagged only', 'unflagged only'}, ...
        'Value', app.settings.filter_status, ...
        'Position', [150 120 160 22]);

    %% === Apply and Cancel Buttons ===
    applyButton = uibutton(app.settings_window, ...
        'Text', 'Apply Settings', ...
        'Position', [250 10 120 30], ...
        'ButtonPushedFcn', @(btn, event) apply_settings(app));

    cancelButton = uibutton(app.settings_window, ...
        'Text', 'Cancel', ...
        'Position', [130 10 120 30], ...
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
