function display_ga_window(app, event)

    % =========================
    % WINDOW
    % =========================
    app.ga_window = uifigure('Name', 'Grand Average', ...
        'Position', [300, 300, 560, 430]);

    % =========================
    % DATA
    % =========================
    nBins = size(app.ga_mat, 1);
    app.ga_latencies = nan(nBins, 1);

    % =========================
    % AXES (slightly higher to balance layout)
    % =========================
    app.ga_axes = uiaxes(app.ga_window, ...
        'Position', [40 115 480 320]);

    % =========================
    % TOP ROW: BIN + LATENCY + INFO
    % =========================
    uilabel(app.ga_window, ...
        'Position', [40 80 80 20], ...
        'Text', 'Bin:');

    app.ga_bin_dropdown = uidropdown(app.ga_window, ...
        'Position', [80 80 80 22], ...
        'Items', string(1:nBins), ...
        'Value', "1", ...
        'ValueChangedFcn', @(src,event) update_ga_plot(app));

    % Latency moved here (compact inline display)
    app.ga_latency_label = uilabel(app.ga_window, ...
        'Position', [170 80 200 20], ...
        'Text', 'Latency: -');

    % Bin overview
    app.ga_bin_info = uilabel(app.ga_window, ...
        'Position', [340 80 110 20], ...
        'Text', sprintf('Bins: %d', nBins));

    % Info button
    app.ga_info_btn = uibutton(app.ga_window, ...
        'state', ...
        'Text', '? Info', ...
        'Position', [450 80 70 22], ...
        'ValueChangedFcn', @(src,event) toggle_ga_info(app));

    % =========================
    % BUTTON ROW (now fills freed space better)
    % =========================
    btnY = 35;

    app.ga_btn_peak = uibutton(app.ga_window, ...
        'push', ...
        'Text', 'Peak', ...
        'Position', [40 btnY 90 28], ...
        'ButtonPushedFcn', @(src,event) set_peak_latency(app));

    app.ga_btn_area = uibutton(app.ga_window, ...
        'push', ...
        'Text', 'Area', ...
        'Position', [135 btnY 90 28], ...
        'ButtonPushedFcn', @(src,event) set_area_latency(app));

    app.ga_btn_clear = uibutton(app.ga_window, ...
        'push', ...
        'Text', 'Clear', ...
        'Position', [230 btnY 90 28], ...
        'ButtonPushedFcn', @(src,event) clear_latency(app));

    app.ga_btn_apply = uibutton(app.ga_window, ...
        'push', ...
        'Text', 'Apply & Close', ...
        'Position', [350 btnY 170 28], ...
        'ButtonPushedFcn', @(src,event) apply_ga_latency(app), ...
        'Enable', 'off');

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

function update_progress(app)

    total = length(app.ga_latencies);
    completed = sum(~isnan(app.ga_latencies));
    missing = total - completed;

    app.ga_bin_info.Text = sprintf('Bins: %d | Missing: %d', total, missing);

    if missing == 0
        app.ga_btn_apply.Enable = "on";
    else
        app.ga_btn_apply.Enable = "off";
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

    update_progress(app);
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