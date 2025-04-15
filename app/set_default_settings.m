function set_default_settings(app)
    settings = struct();

    settings.ylimlower = -5;
    settings.ylimupper = 9;
    settings.line_width = 1.5;
    settings.display_legend = true;
    settings.display_info = true;
    settings.auto_jump_behavior = 'Jump to next review'; % {'Jump to next review', 'Move to next ERP', 'Do not move'}
    settings.filter_decision = 'All';  % Options: 'All', 'review', 'accept', 'reject', 'default'
    settings.filter_fit = 'All';  % Options: 'All', 'OK', 'Fail', 'NA'

    app.settings = settings;
end