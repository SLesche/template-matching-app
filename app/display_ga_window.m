function display_ga_window(app, event)

    % Create window
    app.ga_window = uifigure('Name', 'Grand Average', ...
        'Position', [300, 300, 520, 460]);

    % Initialize latency storage (per bin)
    nBins = size(app.ga_mat, 1);
    app.ga_latencies = nan(nBins, 1);

    % === AXES ===
    app.ga_axes = uiaxes(app.ga_window, ...
        'Position', [60 120 400 300]);

    % === DROPDOWN ===
    app.ga_bin_dropdown = uidropdown(app.ga_window, ...
        'Position', [60 70 120 30], ...
        'Items', string(1:nBins), ...
        'Value', "1", ...
        'ValueChangedFcn', @(src,event) update_ga_plot(app));

    % === BUTTONS ===
    app.ga_btn_peak = uibutton(app.ga_window, ...
        'push', ...
        'Text', 'Peak', ...
        'Position', [200 70 80 30], ...
        'ButtonPushedFcn', @(src,event) set_peak_latency(app));

    app.ga_btn_area = uibutton(app.ga_window, ...
        'push', ...
        'Text', 'Area', ...
        'Position', [290 70 80 30], ...
        'ButtonPushedFcn', @(src,event) set_area_latency(app));

    app.ga_btn_clear = uibutton(app.ga_window, ...
        'push', ...
        'Text', 'Clear', ...
        'Position', [380 70 80 30], ...
        'ButtonPushedFcn', @(src,event) clear_latency(app));

    % === LATENCY LABEL ===
    app.ga_latency_label = uilabel(app.ga_window, ...
        'Position', [60 30 400 30], ...
        'Text', 'Latency: -');

    app.ga_btn_apply = uibutton(app.ga_window, ...
        'push', ...
        'Text', 'Apply & Close', ...
        'Position', [200 30 120 30], ...
        'ButtonPushedFcn', @(src,event) apply_ga_latency(app));

    % === GLOBAL CLICK HANDLER ===
    app.ga_window.WindowButtonDownFcn = ...
        @(src, event) ga_click_callback(app);

    % Initial plot
    update_ga_plot(app);
end
function update_ga_plot(app)

    bin = str2double(app.ga_bin_dropdown.Value);
    time_vec = app.time_vector;
    ga = app.ga_mat(bin, :)';

    plot(app.ga_axes, time_vec, ga, 'k', 'LineWidth', 1.5);
    hold(app.ga_axes, 'on');

    % Draw stored latency
    lat = app.ga_latencies(bin);
    if ~isnan(lat)
        xline(app.ga_axes, lat, 'r', 'LineWidth', 1.5);
        app.ga_latency_label.Text = ['Latency: ', num2str(lat, '%.1f'), ' ms'];
    else
        app.ga_latency_label.Text = 'Latency: -';
    end

    hold(app.ga_axes, 'off');

    if app.settings.positive_up
        set(app.ga_axes, 'YDir','normal') % Hier wird einmal die Achse gedreht -> Positivierung oben 
    else
        set(app.ga_axes, 'YDir','reverse') % Hier wird einmal die Achse gedreht -> Negativierung oben 
    end

    xlabel(app.ga_axes, 'ms');
    ylabel(app.ga_axes, 'µV');
    title(app.ga_axes, ['Grand Average - Bin ', num2str(bin)]);
end

function ga_click_callback(app)

    cp = app.ga_axes.CurrentPoint;
    x = cp(1,1);
    y = cp(1,2);

    xl = xlim(app.ga_axes);
    yl = ylim(app.ga_axes);

    inside = x >= xl(1) && x <= xl(2) && ...
             y >= yl(1) && y <= yl(2);

    if inside
        bin = str2double(app.ga_bin_dropdown.Value);

        app.ga_latencies(bin) = x;

        update_ga_plot(app);
    end
end

function set_peak_latency(app)

    bin = str2double(app.ga_bin_dropdown.Value);

    time_vec = app.time_vector;
    ga = app.ga_mat(bin, :)';

    window = app.cfg.window;
    polarity = app.cfg.polarity;

    lat = approx_peak_latency(time_vec, ga, window, polarity);

    if ~isnan(lat)
        app.ga_latencies(bin) = lat;
        update_ga_plot(app);
    end
end

function set_area_latency(app)

    bin = str2double(app.ga_bin_dropdown.Value);

    time_vec = app.time_vector;
    ga = app.ga_mat(bin, :)';

    window = app.cfg.window;
    polarity = app.cfg.polarity;

    lat = approx_area_latency(time_vec, ga, window, polarity, 0.5, true);

    if ~isnan(lat)
        app.ga_latencies(bin) = lat;
        update_ga_plot(app);
    end
end

function clear_latency(app)

    bin = str2double(app.ga_bin_dropdown.Value);

    app.ga_latencies(bin) = NaN;

    update_ga_plot(app);
end

function apply_ga_latency(app)    
    disp('GA latencies applied:');
    disp(app.ga_latencies);


    % === CLOSE WINDOW ===
    if isvalid(app.ga_window)
        delete(app.ga_window);

        recompute_latencies(app);
        plot_latency(app);
        update_overview_table(app);
    end

end