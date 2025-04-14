function set_component_positions(app)
    % Get current window size
    full_window_width = app.review.Position(3);
    full_window_height = app.review.Position(4);

    % Define padding 
    top_padding = 10;
    bottom_padding = 10;

    left_padding = 30;
    right_padding = 20;

    avail_width = full_window_width - (left_padding + right_padding);
    avail_height = full_window_height - (top_padding + bottom_padding);

    % Define "divs" for layout
    percent_width_window_div = 100;
    percent_height_window_div = 80;

    percent_width_buttons_div = 100;
    percent_height_buttons_div = 15;

    window_width = avail_width * percent_width_window_div / 100;
    window_height = avail_height * percent_height_window_div / 100;

    buttons_height = avail_height * percent_height_buttons_div / 100;
    buttons_width = avail_width * percent_width_buttons_div / 100;

    % Buttons are anchored at bottom, window is anchored at top

    %% Within Window
    percent_height_plot = 81;
    percent_height_fit_display = 15;
    percent_height_b_slider = 4;
    percent_height_a_slider = percent_height_plot;

    percent_width_erp = 90;
    percent_width_fit_display = percent_width_erp;
    percent_width_b_slider = percent_width_erp;

    percent_width_a_slider = 15;

    % Div
    bottom_corner_window_y = full_window_height - (top_padding + avail_height*percent_height_window_div / 100);
    bottom_corner_window_x = left_padding;

    % b slider
    bottom_corner_b_slider_y = bottom_corner_window_y;
    bottom_corner_b_slider_x = bottom_corner_window_x;
    b_slider_height = window_height*percent_height_b_slider / 100;
    b_slider_width = window_width*percent_width_b_slider / 100;
    b_slider_position = [bottom_corner_b_slider_x, bottom_corner_b_slider_y, b_slider_width, b_slider_height];

    % Fit display
    bottom_corner_fit_display_y = bottom_corner_window_y + window_height*percent_height_b_slider / 100;
    bottom_corner_fit_display_x = bottom_corner_window_x;
    fit_display_height = window_height*percent_height_fit_display / 100;
    fit_display_width = window_width*percent_width_fit_display / 100;
    fit_display_position = [bottom_corner_fit_display_x, bottom_corner_fit_display_y, fit_display_width, fit_display_height];

    % Plot
    bottom_corner_erp_y = bottom_corner_fit_display_y + window_height*percent_height_fit_display / 100;
    bottom_corner_erp_x = bottom_corner_window_x;
    plot_height = window_height*percent_height_plot / 100;
    plot_width = window_width*percent_width_erp / 100;
    plot_position = [bottom_corner_erp_x, bottom_corner_erp_y, plot_width, plot_height];

    % a slider
    bottom_corner_a_slider_y = bottom_corner_erp_y;
    bottom_corner_a_slider_x = bottom_corner_window_x + window_width*percent_width_erp / 100;
    a_slider_height = window_height*percent_height_a_slider / 100;
    a_slider_width = window_width*percent_width_a_slider / 100;
    a_slider_position = [bottom_corner_a_slider_x, bottom_corner_a_slider_y, a_slider_width, a_slider_height];


    %% Buttons
    icon_height = buttons_height * 0.5;
    icon_width = icon_height * 1.6;

    center_x = plot_width / 2 + left_padding;

    %distance_from_edge = buttons_width*0.1;
    short_margin = buttons_width*0.015;
    long_margin = buttons_width*0.06;

    bottom_corner_buttons_y = bottom_padding + buttons_height/2 - icon_height/2;

    bottom_corner_accept_x = center_x - icon_width/2;
    bottom_corner_reject_x = bottom_corner_accept_x + short_margin + icon_width;
    bottom_corner_restore_x = bottom_corner_accept_x - short_margin - icon_width;

    bottom_corner_previous_x = bottom_corner_restore_x - long_margin - icon_width;
    bottom_corner_jumpprevious_x = bottom_corner_previous_x - short_margin - icon_width;
    
    bottom_corner_next_x = bottom_corner_reject_x + long_margin + icon_width;
    bottom_corner_jumpnext_x = bottom_corner_next_x + short_margin + icon_width;

    bottom_corner_search_x = avail_width - icon_width;

    jumpprevious_position = [bottom_corner_jumpprevious_x, bottom_corner_buttons_y, icon_width, icon_height];
    previous_position = [bottom_corner_previous_x, bottom_corner_buttons_y, icon_width, icon_height];
    accept_position = [bottom_corner_accept_x, bottom_corner_buttons_y, icon_width, icon_height];
    reject_position = [bottom_corner_reject_x, bottom_corner_buttons_y, icon_width, icon_height];
    restore_position = [bottom_corner_restore_x, bottom_corner_buttons_y, icon_width, icon_height];
    next_position = [bottom_corner_next_x, bottom_corner_buttons_y, icon_width, icon_height];
    jumpnext_position = [bottom_corner_jumpnext_x, bottom_corner_buttons_y, icon_width, icon_height];
    search_position = [bottom_corner_search_x, bottom_corner_buttons_y, icon_width, icon_height];

    %% Add button in fit display
    bottom_corner_add_button_x = bottom_corner_erp_x + short_margin;
    bottom_corner_add_button_y = bottom_corner_erp_y + 0.05*plot_height;

    add_button_position = [bottom_corner_add_button_x, bottom_corner_add_button_y, icon_width, icon_height];


    %% Set positions in app
    app.erp_display.Position = plot_position;
    app.fit_display.Position = fit_display_position;
    app.b_slider.Position = b_slider_position;
    app.a_slider.Position = a_slider_position;

    app.jumpprevious_button.Position = jumpprevious_position;
    app.previous_button.Position = previous_position;
    app.manual_button.Position = accept_position;
    app.reject_button.Position = reject_position;
    app.restore_button.Position = restore_position;
    app.next_button.Position = next_position;
    app.jumpnext_button.Position = jumpnext_position;

    app.search_button.Position = search_position;
    app.add_button.Position = add_button_position;
end