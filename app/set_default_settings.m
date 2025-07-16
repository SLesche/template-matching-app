function set_default_settings(app)
    settings = struct();

    settings.ylimlower = -5;
    settings.ylimupper = 9;
    settings.line_width = 1.5;
    settings.display_legend = true;
    settings.legend_location = 'southeast'; % Options: 'northwest', 'northeast', 'southwest', 'southeast', 'north', 'south', 'east', 'west'
    settings.display_info = true;
    settings.display_traditional_lat = true; % Display traditional latency lines (Peak and Area)
    settings.auto_jump_behavior = 'Jump to next review'; % {'Jump to next review', 'Move to next ERP', 'Do not move'}
    settings.filter_decision = 'All';  % Options: 'All', 'review', 'accept', 'reject', 'auto', 'manual'
    settings.filter_fit = '';  % Options: 'All', expression
    settings.filter_status = 'All';  % Options: 'All', 'flagged_only', 'unflagged_only'
    settings.positive_up = false; % If true, Y-axis is positive up, otherwise negative up

    app.settings = settings;
end