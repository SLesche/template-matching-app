function plot_latency(app)
    [a_param, b_param, latency, fit_cor, ~] = evaluate_matching_results(app);

    current_erp_num = app.erp_num;
    current_bin = app.bin_num;
    time_vec = app.time_vector;

    % Get the cfg parameters
    polarity = app.cfg.polarity;
    electrodes = app.cfg.electrodes;
    window = app.cfg.window;
    approach = app.cfg.approach;
    
    ga = app.ga_mat(current_bin, :)';
    signal = squeeze(app.erp_mat(current_erp_num, electrodes, :, current_bin));
    
    matched_ga_x = time_vec * b_param;
    matched_ga_y = interpolate_transformed_template(time_vec, ga, 1/a_param, 1/b_param);

    if approach == "maxcor"
        plot_color = 'red';
    elseif approach == "minsq"
        plot_color = 'blue';
    end

    plot( ...
        time_vec, ...
        signal, 'black', ...
        'Parent', app.erp_display)
        
    hold(app.erp_display, 'on');
    
    app.ga_plot = plot(time_vec, matched_ga_y, "--", 'DisplayName', 'Grand Average Waveform', 'Parent', app.erp_display);
    app.matched_xline = xline(app.erp_display, latency, 'Color', plot_color);

    peak_auto_latency = approx_peak_latency(time_vec, signal, window, polarity);
    area_auto_latency = approx_area_latency(time_vec, signal, window, polarity, 0.5, true);

    [legend_text, title_text, subtitle_text] = return_plot_legend(app, approach, b_param, latency, fit_cor);


    xline(app.erp_display, peak_auto_latency, '--m', 'Label', 'Peak') % change dash-type and color
    xline(app.erp_display, area_auto_latency, '-.m', 'Label','Area') % change dash-type and color
    
    %axis([-200 800 -5 9]) % Achsen entsprechend des Signals anpassen 
    xlim(app.erp_display, [min(time_vec), max(time_vec)]);
    ylim(app.erp_display, [app.ylimlower app.ylimupper]);
    set(app.erp_display, 'YDir','reverse') % Hier wird einmal die Achse gedreht -> Negativierung oben 
    
    ax = app.erp_display;
    ax.XAxisLocation = 'origin';
    ax.YAxisLocation = 'origin';
    set(app.erp_display,'TickDir','in'); 
    ax.XRuler.TickLabelGapOffset = -20;    
    Ylm=ylim(app.erp_display);                          
    Xlm=xlim(app.erp_display);  
    Xlb=0.90*Xlm(2);
    Ylb=0.90*Ylm(1);
    xlabel(app.erp_display, 'ms','Position',[Xlb 1]); 
    ylabel(app.erp_display, 'µV','Position',[-100 Ylb]); 
    
    legend(app.erp_display, legend_text, 'location', 'southwest')
    title(app.erp_display, title_text)


    text(app.erp_display, 0.95*Xlm(2), 0.95*Ylm(2), ...
        subtitle_text, ...
        'FontSize', 10, ...
        'HorizontalAlignment', 'right', ...
        'VerticalAlignment', 'bottom');
    
    hold(app.erp_display, 'off');
end