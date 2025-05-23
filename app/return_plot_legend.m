function [legend_text, title_text, subtitle_text] = return_plot_legend(app, approach, b, latency, fit_cor)     
    if approach == "maxcor"
        proper_latency = round(latency, 2);
        title_text = {"Individual ERP matched to grand average via minimizing the squared distance", strcat("ERP Number: ", num2str(app.erp_num), " | Bin Number: ", num2str(app.bin_num))};
        legend_text = ["ERP", "Template", strcat("Latency ", app.cfg.component_name)];
        subtitle_text = {strcat("MAXCOR: Latency = ", num2str(proper_latency)), strcat("MAXCOR: Correlation = ", num2str(round(fit_cor, 2))), strcat("Stretch Factor = ", num2str(round(b, 2)))};
    elseif approach == "minsq"
        proper_latency = round(latency, 2);
        title_text = {"Individual ERP matched to grand average via minimizing the squared distance", strcat("ERP Number: ", num2str(app.erp_num), " | Bin Number: ", num2str(app.bin_num))};
        legend_text = ["ERP", "Template", strcat("Latency ", app.cfg.component_name)];
        subtitle_text = {strcat("MINSQ: Latency = ", num2str(proper_latency)), strcat("MINSQ: Correlation = ", num2str(round(fit_cor, 2))), strcat("Stretch Factor = ", num2str(round(b, 2)))};
    end
end