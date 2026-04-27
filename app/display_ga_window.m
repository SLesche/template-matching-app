function display_ga_window(app, event)

    % =========================
    % WINDOW
    % =========================
    app.ga_window = uifigure('Name', 'Grand Average', ...
        'Position', [300, 300, 560, 480]);

    % =========================
    % DATA
    % =========================
    nBins = size(app.ga_mat, 1);
    app.ga_latencies = nan(nBins, 1);

    % =========================
    % AXES (moved up → removes top dead space)
    % =========================
    app.ga_axes = uiaxes(app.ga_window, ...
        'Position', [60 155 440 310]);

    % =========================
    % BIN SELECTOR + INFO ROW
    % =========================
    uilabel(app.ga_window, ...
        'Position', [60 120 80 20], ...
        'Text', 'Bin:');

    app.ga_bin_dropdown = uidropdown(app.ga_window, ...
        'Position', [100 120 100 22], ...
        'Items', string(1:nBins), ...
        'Value', "1", ...
        'ValueChangedFcn', @(src,event) update_ga_plot(app));

    app.ga_bin_info = uilabel(app.ga_window, ...
        'Position', [220 120 250 20], ...
        'Text', sprintf('Bins: %d', nBins));

    % =========================
    % INFO BUTTON (replaces textbox)
    % =========================
    app.ga_info_btn = uibutton(app.ga_window, ...
        'state', ...
        'Text', '? Info', ...
        'Position', [470 120 70 22], ...
        'ValueChangedFcn', @(src,event) toggle_ga_info(app));

    % =========================
    % BUTTON ROW (compact + aligned)
    % =========================
    btnY = 80;

    app.ga_btn_peak = uibutton(app.ga_window, ...
        'push', ...
        'Text', 'Peak', ...
        'Position', [60 btnY 80 28], ...
        'ButtonPushedFcn', @(src,event) set_peak_latency(app));

    app.ga_btn_area = uibutton(app.ga_window, ...
        'push', ...
        'Text', 'Area', ...
        'Position', [150 btnY 80 28], ...
        'ButtonPushedFcn', @(src,event) set_area_latency(app));

    app.ga_btn_clear = uibutton(app.ga_window, ...
        'push', ...
        'Text', 'Clear', ...
        'Position', [240 btnY 80 28], ...
        'ButtonPushedFcn', @(src,event) clear_latency(app));

    app.ga_btn_apply = uibutton(app.ga_window, ...
        'push', ...
        'Text', 'Apply & Close', ...
        'Position', [330 btnY 150 28], ...
        'ButtonPushedFcn', @(src,event) apply_ga_latency(app), ...
        'Enable', 'off');

    % =========================
    % LIVE LATENCY LABEL
    % =========================
    app.ga_latency_label = uilabel(app.ga_window, ...
        'Position', [60 55 300 20], ...
        'Text', 'Latency: -');

    % =========================
    % GLOBAL CLICK HANDLER
    % =========================
    app.ga_window.WindowButtonDownFcn = ...
        @(src, event) ga_click_callback(app);

    % =========================
    % INITIAL STATE
    % =========================
    update_ga_plot(app);
end

function toggle_ga_info(app)

    if app.ga_info_btn.Value

        uialert(app.ga_window, ...
            ['Instructions:' newline ...
            '1. Select a bin' newline ...
            '2. Click plot OR use Peak/Area' newline ...
            '3. Adjust per bin' newline ...
            '4. Apply when done'], ...
            'Info');

        app.ga_info_btn.Value = false;
    end
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

    ax = app.ga_axes;
    ax.XAxisLocation = 'origin';
    ax.YAxisLocation = 'origin';
    set(app.ga_axes,'TickDir','in'); 
    ax.XRuler.TickLabelGapOffset = -20;    
    Ylm=ylim(app.ga_axes);                          
    Xlm=xlim(app.ga_axes);  
    Xlb=0.90*Xlm(2);
    Ylb=1;
    xlabel(app.ga_axes, 'ms','Position',[Xlb 1]); 
    ylabel(app.ga_axes, 'µV','Position',[-100 Ylb]); 
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