classdef review_app < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        review               matlab.ui.Figure
        bin_selection_field  matlab.ui.control.EditField
        subject_selection_field matlab.ui.control.NumericEditField
        a_spinner            matlab.ui.control.Spinner
        b_spinner            matlab.ui.control.Spinner
        a_field              matlab.ui.control.NumericEditField
        b_field              matlab.ui.control.NumericEditField
        bin_dropdown         matlab.ui.control.DropDown
        MainBinLabel         matlab.ui.control.Label
        next_button          matlab.ui.control.Button
        previous_button      matlab.ui.control.Button
        a_slider             matlab.ui.control.Slider
        aSliderLabel         matlab.ui.control.Label
        reject_button        matlab.ui.control.Button
        manual_button        matlab.ui.control.Button
        restore_button       matlab.ui.control.Button
        b_slider             matlab.ui.control.Slider
        bSliderLabel         matlab.ui.control.Label
        fit_display          matlab.ui.control.UIAxes
        erp_display          matlab.ui.control.UIAxes
        save_check           matlab.ui.control.CheckBox
        exit_button          matlab.ui.control.Button
        ylimupper_field      matlab.ui.control.NumericEditField
        ylimlower_field      matlab.ui.control.NumericEditField
    end
    
    % Set properties that the review process needs
    properties (Access = public)
        erp_mat double % The data matrix with subject X channels X times X bins
        time_vector double % The vector showing times
        results_mat double % Results matrix with subject X bins X n_params
        ga_latencies double % Latencies of the grand average
        subject double % Subject number
        method double % Method number
        baseline_method double % Number of method in method table to base review on
        bin double % Bin
        method_table table % Information about the fitting method
        cutoff double % Cutoff for review
        extreme_pars double % Review extreme bs?

        review_mat double % Which subject, bin combo is to be reviewed
        ireview double % Which review we are on

        final_mat double % All information goes in here

        a_param double % current a param
        b_param double % current b param
        a_param_continuous double
        b_param_continuous double

        nbins double % number of bins

        ga_plot matlab.graphics.chart.primitive.Line
        matched_xline matlab.graphics.chart.decoration.ConstantLine
        additional_bins double
        fit_xline matlab.graphics.chart.decoration.ConstantLine

        ylimupper double % Default params set at beginning
        ylimlower double
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Specify review params
        function specify_review_params(app)
            % Prompt the user for input using a dialog box
            prompt = {'Name of dataset:', 'Name of time vector:', 'Name of method table:', 'Baseline method:', 'Cutoff:', 'Y-Limit: Upper', 'Y-Limit: Lower', 'Name of results matrix (optional):', 'Name of GA latencies (optional):'};
            dlgTitle = 'Set Review Params';
            numLines = 1;
            defaultInput = {'erp_data', 'time_vec', 'method_table', '1', '1', '-5', '9', '', ''};
        
            userInput = inputdlg(prompt, dlgTitle, numLines, defaultInput);
        
            % Handle cancel button press or empty inputs
            if isempty(userInput)
                error('User input canceled or empty.');
            end
        
            % Convert baseline method to number
            userInput{4} = str2double(userInput{4});
            % Convert cutoff to a double
            userInput{5} = str2double(userInput{5});

            % Convert limits to a double
            userInput{6} = str2double(userInput{6});
            userInput{7} = str2double(userInput{7});

            if isnan(userInput{5})
                error('Invalid input for Cutoff. Please enter a numeric value.');
            end
            
            app.erp_mat = evalin('base', userInput{1});
            app.method_table = evalin('base', userInput{3});
            app.time_vector = evalin('base', userInput{2});
            app.baseline_method = userInput{4};
            app.cutoff = userInput{5};
            app.ylimlower = userInput{6};
            app.ylimupper = userInput{7};
            
            if ~isempty(userInput{8})
                app.results_mat = evalin('base', userInput{8});
                n_subjects = size(app.erp_mat, 1);
                n_params = 5;
                n_bins = size(app.erp_mat, 4);

                if length(size(app.results_mat)) ~= 3
                    error('Results matrix does not match the data matrix');
                end
                if ~all(size(app.results_mat) == [n_subjects, n_bins, n_params])
                    error('Results matrix does not match the data matrix');
                end
            end

            if ~isempty(userInput{9})
                app.ga_latencies = evalin('base', userInput{9});
                n_bins = size(app.erp_mat, 4);

                if length(app.ga_latencies) ~= n_bins
                    error('This vector should contain one latency per bin');
                end
            end
        end

        % Function fetching the current method, subject, bin combo
        function update_review_info(app)
             [app.subject, app.bin] = app.review_mat(app.ireview, :);
        end

        function init_final_results(app)
            [n_subjects, n_bins, n_params] = size(app.results_mat);

            final_review_mat = zeros([n_subjects, n_bins, n_params + 1]);
            final_review_mat(:, :, 1:n_params) = app.results_mat;
            final_review_mat(:, :, n_params + 1) = 0;
            app.final_mat = final_review_mat;
        end

        function [a_param, b_param, latency, fit_cor, fit_dist] = extract_optimized_params(app, source)
            if ~exist('source', 'var')
                source = "reviewed";
            end
            % This function just return the previously optimized params by
            % the baseline optimization method
            if source == "original"
                values = app.results_mat(app.subject, app.bin, :);
            else
                values = app.final_mat(app.subject, app.bin, :);
            end
            a_param = values(1);
            b_param = values(2);
            latency = values(3);
            fit_cor = values(4);
            fit_dist = values(5);
        end

        function [a_param, b_param, latency, fit_cor, fit_dist] = run_new_optimization(app)
            % This function can run a completely new optimization for a
            % given subject, bin and method
            current_subject = app.subject;
            current_bin = app.bin;
            current_method = app.method;
            time_vec = app.time_vector;

            % Fit the baseline method
            method_entry = app.method_table(current_method, :);
            
            polarity = table2array(method_entry(1, "polarity"));
            electrodes = table2array(method_entry(1, "electrodes"));
            window = cell2mat(table2array(method_entry(1, "window")));
            approach = table2array(method_entry(1, "approach"));
            if approach == "minsq" || approach == "maxcor"
               is_template_matching = 1;
            elseif approach == "area" || approach == "peak" || approach == "liesefeldarea"
                is_template_matching = 0;
            else
                error("Set a proper matching approach")
            end

            if table2array(method_entry(1, "weight")) ~= "none"
                weight_function = eval(strcat("@", table2array(method_entry(1, "weight"))));
            else
                weight_function = @(time_vector, signal, window) ones(length(time_vector), 1);
            end
            
            if table2array(method_entry(1, "penalty")) ~= "none"
                penalty_function = eval(strcat("@", table2array(method_entry(1, "penalty"))));
            else 
                penalty_function = @(a, b) 1;
            end
            
            if table2array(method_entry(1, "normalization")) ~= "none"
                normalize_function = eval(strcat("@", table2array(method_entry(1, "normalization")))); 
            else
                normalize_function = @(x) x;
            end

            if table2array(method_entry(1, "approach")) == "minsq"
                eval_function = @eval_sum_of_squares;
            elseif table2array(method_entry(1, "approach")) == "maxcor"
                eval_function = @eval_correlation;
            end

            use_derivative = table2array(method_entry(1, "use_derivative"));

            ga = squeeze(mean(app.erp_mat(:, electrodes, :, current_bin), 1, 'omitnan'));

            if is_template_matching
                if isempty(app.ga_latencies)
                    lat_ga = approx_peak_latency(time_vec, ga, [window(1) window(2)], polarity);
                else
                    lat_ga = app.ga_latencies(current_bin);
                end         
                signal = squeeze(app.erp_mat(current_subject, electrodes, :, current_bin));
                if all(isnan(signal)) || all(signal == 0)
                    [a_param, b_param, latency, fit_cor, fit_dist] = NaN;
                else
                    params = run_global_search(define_optim_problem(specify_objective_function(time_vec', signal, ga, [window(1) window(2)], polarity, weight_function, eval_function, normalize_function ,penalty_function, use_derivative)));

                    a_param = params(1);
                    b_param = params(2);
                    latency = return_matched_latency(params(2), lat_ga);
                    fits = get_fits(time_vec', signal, ga, [window(1) window(2)], polarity, weight_function, params(1), params(2));

                    fit_cor = fits(1);
                    fit_dist = fits(2);
                end
            else
                latency = NaN;
                signal = squeeze(app.erp_mat(app.subject, electrodes, :, app.bin));
                
                if all(isnan(signal)) || all(signal == 0)
                    [a_param, b_param, latency, fit_cor, fit_dist] = NaN;
                else
                    if approach == "area"
                        latency = approx_area_latency(time_vec, signal, [window(1) window(2)], polarity, 0.5);
                    elseif approach == "liesefeld_area"
                        latency = approx_area_latency(time_vec, signal, [window(1) window(2)], polarity, 0.5, true);
                    elseif approach == "peak"
                        latency = approx_peak_latency(time_vec, signal, [window(1) window(2)], polarity);
                    end
                    [a_param, b_param, fit_cor, fit_dist] = NaN;
                end
            end
        end
        
        function [a_param, b_param, latency, fit_cor, fit_dist] = evaluate_matching_results(app)
            % This function will provide new latency, fit_cor and fit_dist
            % estimates for updated a_params and b_params
            current_subject = app.subject;
            current_bin = app.bin;
            current_method = app.baseline_method; % this is why here is baseline method
            time_vec = app.time_vector;

            % Fit the baseline method
            method_entry = app.method_table(current_method, :);
            
            polarity = table2array(method_entry(1, "polarity"));
            electrodes = table2array(method_entry(1, "electrodes"));
            window = cell2mat(table2array(method_entry(1, "window")));
            approach = table2array(method_entry(1, "approach"));
            if approach == "minsq" || approach == "maxcor"
               is_template_matching = 1;
            elseif approach == "area" || approach == "peak" || approach == "liesefeldarea"
                is_template_matching = 0;
            else
                error("Set a proper matching approach")
            end

            if table2array(method_entry(1, "weight")) ~= "none"
                weight_function = eval(strcat("@", table2array(method_entry(1, "weight"))));
            else
                weight_function = @(time_vector, signal, window) ones(length(time_vector), 1);
            end

            ga = squeeze(mean(app.erp_mat(:, electrodes, :, current_bin), 1, 'omitnan'));

            if is_template_matching
                if isempty(app.ga_latencies)
                    lat_ga = approx_peak_latency(time_vec, ga, [window(1) window(2)], polarity);
                else
                    lat_ga = app.ga_latencies(current_bin);
                end  
                signal = squeeze(app.erp_mat(current_subject, electrodes, :, current_bin));
                if all(isnan(signal)) || all(signal == 0)
                    [a_param, b_param, latency, fit_cor, fit_dist] = NaN;
                else
                    a_param = app.a_param;
                    b_param = app.b_param;
                    latency = return_matched_latency(b_param, lat_ga);
                    fits = get_fits(time_vec', signal, ga, [window(1) window(2)], polarity, weight_function, a_param, b_param);
                    fit_cor = fits(1);
                    fit_dist = fits(2);
                end
            else
                % In the case of non-template matching, updating a and b
                % will not change anything, so we can just extract the
                % already optimized params
                [a_param, b_param, latency, fit_cor, fit_dist] = extract_optimized_params(app);
            end
        end

        function [legend_text, title_text, subtitle_text] = return_plot_legend(app, approach, b, latency, fit_cor)     
            if approach == "maxcor"
                proper_latency = round(latency, 2);
                title_text = {"Individual ERP matched to grand average via minimizing the squared distance", strcat("Method: ", num2str(app.method), " | ERP Number: ", num2str(app.subject))};
                legend_text = ["Subject ERP", "Matched Grand Average Waveform", strcat("Correlation Fitted ", table2array(app.method_table(app.method, "component_name")))];
                subtitle_text = {strcat("MAXCOR: Latency = ", num2str(proper_latency)), strcat("MAXCOR: Correlation = ", num2str(fit_cor)), strcat("Stretch Factor = ", num2str(round(b, 2)))};
            elseif approach == "minsq"
                proper_latency = round(latency, 2);
                title_text = {"Individual ERP matched to grand average via minimizing the squared distance", strcat("Method: ", num2str(app.method), " | ERP Number: ", num2str(app.subject))};
                legend_text = ["Subject ERP", "Matched Grand Average Waveform", strcat("Minsq Fitted ", table2array(app.method_table(app.method, "component_name")))];
                subtitle_text = {strcat("MINSQ: Latency = ", num2str(proper_latency)), strcat("MINSQ: Correlation = ", num2str(fit_cor)), strcat("Stretch Factor = ", num2str(round(b, 2)))};
            end
        end
        
        function plot_latency(app)
            [a_param, b_param, latency, fit_cor, ~] = evaluate_matching_results(app);

            current_subject = app.subject;
            current_bin = app.bin;
            current_method = app.baseline_method; % this is why here is baseline method
            time_vec = app.time_vector;

            % Fit the baseline method
            method_entry = app.method_table(current_method, :);
            
            polarity = table2array(method_entry(1, "polarity"));
            electrodes = table2array(method_entry(1, "electrodes"));
            window = cell2mat(table2array(method_entry(1, "window")));
            approach = table2array(method_entry(1, "approach"));
            
            ga = squeeze(mean(app.erp_mat(:, electrodes, :, current_bin), 1, 'omitnan'));
            signal = squeeze(app.erp_mat(current_subject, electrodes, :, current_bin));
            
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

        function update_plot(app)
            hold(app.erp_display, 'on');
            %{
            [corr, ~, latency, ~, a, b] = get_matching_results(app);

            if app.fitting_approach == "corr"
                plot_color = 'red';
            elseif app.fitting_approach == "minsq"
                plot_color = 'blue';
            end
            %}

            delete(app.ga_plot)
            %delete(app.matched_xline)

            ga_x = app.time_vector;
            current_subject = app.subject;
            current_bin = app.bin;
            current_method = app.baseline_method;
            method_entry = app.method_table(current_method, :);
            
            polarity = table2array(method_entry(1, "polarity"));
            electrodes = table2array(method_entry(1, "electrodes"));
            window = cell2mat(table2array(method_entry(1, "window")));
            approach = table2array(method_entry(1, "approach"));
            
            ga_y = squeeze(mean(app.erp_mat(:, electrodes, :, current_bin), 1, 'omitnan'));     
            
            matched_ga_x = ga_x .* app.b_param_continuous;
            matched_ga_y = ga_y / app.a_param_continuous;

            % Maybe update fit / latency here?
            app.ga_plot = plot(matched_ga_x, matched_ga_y, "--", 'DisplayName', 'Grand Average Waveform', 'Parent', app.erp_display);
            %app.matched_xline = xline(app.erp_display, latency, 'Color', plot_color);

            hold(app.erp_display, 'off');

            update_fit_display(app)

        end

        % This function sets all displays to the current app params
        function update_param_displays(app)
            a = app.a_param;
            b = app.b_param;
            if b < 0.25 || b > 3 || isnan(b)
                b = 1;                
            end
            if a < 0 || a > 10 || isnan(a)
                a = 1;
            end
            app.b_slider.Value = b;
            app.a_slider.Value = a;
            app.b_field.Value = round(b, 3);
            app.a_field.Value = round(a, 3);
            app.b_spinner.Value = b;
            app.a_spinner.Value = a;

            update_fit_display(app);
        end

        % Function intializing the results_mat
        function run_template_matching_app(app)
            % Fit the baseline method
            baseline_method_entry = app.method_table(app.baseline_method, :);
            
            polarity = table2array(baseline_method_entry(1, "polarity"));
            electrodes = table2array(baseline_method_entry(1, "electrodes"));
            window = cell2mat(table2array(baseline_method_entry(1, "window")));
            time_vec = app.time_vector;

            approach = table2array(baseline_method_entry(1, "approach"));
            if approach == "minsq" || approach == "maxcor"
               is_template_matching = 1;
            elseif approach == "area" || approach == "peak" || approach == "liesefeldarea"
                is_template_matching = 0;
            else
                error("Set a proper matching approach")
            end

            if table2array(baseline_method_entry(1, "weight")) ~= "none"
                weight_function = eval(strcat("@", table2array(baseline_method_entry(1, "weight"))));
            else
                weight_function = @(time_vector, signal, window) ones(length(time_vector), 1);
            end
            
            if table2array(baseline_method_entry(1, "penalty")) ~= "none"
                penalty_function = eval(strcat("@", table2array(baseline_method_entry(1, "penalty"))));
            else 
                penalty_function = @(a, b) 1;
            end
            
            if table2array(baseline_method_entry(1, "normalization")) ~= "none"
                normalize_function = eval(strcat("@", table2array(baseline_method_entry(1, "normalization")))); 
            else
                normalize_function = @(x) x;
            end

            if table2array(baseline_method_entry(1, "approach")) == "minsq"
                eval_function = @eval_sum_of_squares;
            elseif table2array(baseline_method_entry(1, "approach")) == "maxcor"
                eval_function = @eval_correlation;
            end

            use_derivative = table2array(baseline_method_entry(1, "use_derivative"));
            
            n_subjects = length(app.erp_mat(:, 1, 1, 1));
            n_params = 5;
            n_bins = app.nbins;

            results = zeros([n_subjects, n_bins, n_params]);

            for ibin = 1:n_bins
                match_results = zeros(n_subjects, n_params);
                % Get the GA here, get corresponding approach and other pars
                ga = squeeze(mean(app.erp_mat(:, electrodes, :, ibin), 1, 'omitnan'));                            
                % Get the appropriate measurement window                    
                if is_template_matching
                    lat_ga = approx_peak_latency(time_vec, ga, [window(1) window(2)], polarity);

                    % lat_ga = approx_area_latency(time_vec, ga, [window(1) window(2)], polarity, 0.5, true);

                    for isubject = 1:n_subjects
                        signal = squeeze(app.erp_mat(isubject, electrodes, :, ibin));
                        if all(isnan(signal)) || all(signal == 0)
                            match_results(isubject, :) = NaN;
                        else
                            try
                                params = run_global_search(define_optim_problem(specify_objective_function(time_vec', signal, ga, [window(1) window(2)], polarity, weight_function, eval_function, normalize_function ,penalty_function, use_derivative)));
                            catch ME
                                    % If an error occurs, log the variables and rethrow the error
                                disp('--- An error occurred ---');
                                disp('Error message:');
                                disp(ME.message);
                                disp([ibin, isubject])
                        
                                % Log the input variables
                                disp('--- Input Variables ---');
                                disp('time_vec:');
                                disp(time_vec);
                                disp('signal:');
                                disp(signal);
                                disp('ga:');
                                disp(ga);
                                disp('window:');
                                disp(window);
                                disp('polarity:');
                                disp(polarity);
                                disp('weight_function:');
                                disp(weight_function);
                                disp('eval_function:');
                                disp(eval_function);
                                disp('normalize_function:');
                                disp(normalize_function);
                                disp('penalty_function:');
                                disp(penalty_function);
                                disp('use_derivative:');
                                disp(use_derivative);
                                disp('-----------------------');
                        
                                % Rethrow the error to handle it further up the call stack if necessary
                                rethrow(ME);
                            end

                            match_results(isubject, [1 2]) = params;
                            match_results(isubject, 3) = return_matched_latency(params(2), lat_ga);
                            match_results(isubject, [4 5]) = get_fits(time_vec', signal, ga, [window(1) window(2)], polarity, weight_function, params(1), params(2));
                            
                        end
                    end
                else
                    for isubject = 1:n_subjects
                        latency = NaN;
                        signal = squeeze(app.erp_mat(isubject, electrodes, :, ibin));
                        
                        if all(isnan(signal)) || all(signal == 0)
                            match_results(isubject, :) = NaN;
                        else
                            if approach == "area"
                                latency = approx_area_latency(time_vec, signal, [window(1) window(2)], polarity, 0.5);
                            elseif approach == "liesefeld_area"
                                latency = approx_area_latency(time_vec, signal, [window(1) window(2)], polarity, 0.5, true);
                            elseif approach == "peak"
                                latency = approx_peak_latency(time_vec, signal, [window(1) window(2)], polarity);
                            end
                            match_results(isubject, [1 2 4 5]) = NaN;
                            match_results(isubject, 3) = latency;
                        end
                    end
                end

                results(:, ibin, :) = match_results;
            end
    
            app.results_mat = results;
        end

        function flag_for_review(app)
            temp_review_mat = app.review_mat;
            
            results = app.results_mat;
            
            [n_subjects, n_bins, ~] = size(results);
            for isubject = 1:n_subjects
                for ibin = 1:n_bins
                    is_low_fit = results(isubject, ibin, 4) <= app.cutoff; 
                    is_extreme_b = results(isubject, ibin, 2) <= 0.66 || results(isubject, ibin, 2) >= 1.5;
                    is_extreme_a = results(isubject, ibin, 1) <= 0.2 || results(isubject, ibin, 1) >= 5;
                    
                    if app.extreme_pars == 1 && any([is_low_fit, is_extreme_a, is_extreme_b])
                        temp_review_mat(end+1, :) = [isubject, ibin];
                    elseif app.extreme_pars == 0 && is_low_fit
                        temp_review_mat(end+1, :) = [isubject, ibin];
                    end
                end
            end

            app.review_mat = temp_review_mat;
        end
        
        function write_info(app, review, subject, bin, a, b, latency, fit_cor, fit_dist)
            % Write the information in the current review step to the
            % results matrix
            app.final_mat(subject, bin, :) = [a, b, latency, fit_cor, fit_dist, review];
        end

        function restore_default_plot(app, source)
            if ~exist('source', 'var')
                source = "final";
            end
            % reload all plots for that subject, set a and b to their
            % solutions
            app.method = app.baseline_method;
            app.subject = app.review_mat(app.ireview, 1);
            app.bin = app.review_mat(app.ireview, 2);
            [app.a_param, app.b_param, ~, ~, ~] = extract_optimized_params(app, source);
            [app.a_param_continuous, app.b_param_continuous, ~, ~, ~] = extract_optimized_params(app, source);
            app.bin_selection_field.Value = '';
            update_param_displays(app)
            plot_latency(app)
            update_dropdown_items(app)
        end

        function move_ireview(app, move)
            if app.ireview > 1 && app.ireview < height(app.review_mat)
                app.ireview = app.ireview + move;
            elseif (app.ireview == height(app.review_mat) && move ~= -1)
                warning("This is the last review case")
            elseif (app.ireview == 1 && move ~= 1)
                warning("This is the first review case")
            elseif (app.ireview == height(app.review_mat) && move == -1)
                app.ireview = app.ireview + move;
            elseif (app.ireview == 1 && move == 1)
                app.ireview = app.ireview + move;
            end
        end

        function update_dropdown_items(app)
            items = 1:app.nbins;
            app.bin_dropdown.Items = cellfun(@num2str, num2cell(items), 'UniformOutput', false);
            app.bin_dropdown.Value = num2str(app.bin);

            app.subject_selection_field.Value = app.subject;
        end

        % Button pushed function: reject_button
        function reject_buttonButtonPushed(app, event)
            % reject the default values
            restore_default_plot(app, "original")
            [a, b, latency, fit_cor, fit_dist] = extract_optimized_params(app);
            
            % write reject info into struct
            review_method = -1; % rejected, so -1
            write_info(app, review_method, app.subject, app.bin, a, b, latency, fit_cor, fit_dist)
            % move ireview            
            move_ireview(app, 1);
            % regenerate plot
            restore_default_plot(app)

            % generate fit plot
            generate_fit_display(app)
        end

        % Button pushed function: manual_button
        function manual_buttonButtonPushed(app, event)
            % Figure out whether values have been changed or not
            [initial_a, initial_b, ~, ~, ~] = extract_optimized_params(app, "original");
            
            if initial_a == app.a_param && initial_b == app.b_param
                review_method = 1; % accepted
            else
                review_method = 2; % manual
            end


            % write accepted info into struct
            [a, b, latency, fit_cor, fit_dist] = evaluate_matching_results(app);
            write_info(app, review_method, app.subject, app.bin, a, b, latency, fit_cor, fit_dist)

            % move ireview
            move_ireview(app, 1)

            % regenerate plot
            restore_default_plot(app)

            % generate fit plot
            generate_fit_display(app)

        end

        function restore_buttonButtonPushed(app, event)
            % If restore defaults
            restore_default_plot(app, "original")
        end


        % Button pushed function: previous_button
        function previous_buttonButtonPushed(app, event)
           % move ireview
            move_ireview(app, -1)

            % regenerate plot
            restore_default_plot(app)

            % generate fit plot
            generate_fit_display(app)
        end

        % Button pushed function: previous_button
        function next_buttonButtonPushed(app, event)
            % move ireview
            move_ireview(app, 1)

            % regenerate plot
            restore_default_plot(app)

            % generate fit plot
            generate_fit_display(app)
        end

        % Value changed function: b_slider
        function b_sliderValueChanged(app, event)
            app.b_param = app.b_slider.Value;
            plot_latency(app)
            update_param_displays(app);
            % update the plot and fit values
        end

        % Value changed function: a_slider
        function a_sliderValueChanged(app, event)
            app.a_param = app.a_slider.Value;
            plot_latency(app)
            update_param_displays(app);
            % update the plot and fit values
            % generate fit display

            if table2array(app.method_table(app.baseline_method, "approach")) == "minsq"
                generate_fit_display(app)
            end
        end

        % Value changing function: b_slider
        function b_sliderValueChanging(app, event)
            app.b_param_continuous = event.Value;
            update_plot(app)
            pause(0.01);
        end

        % Value changing function: a_slider
        function a_sliderValueChanging(app, event)
            app.a_param_continuous = event.Value;
            update_plot(app)
            pause(0.01);
        end

        % Value changed function: bin_dropdown
        function bin_dropdownValueChanged(app, event)
            % update app.bin
            app.bin = str2num(app.bin_dropdown.Value);

            [app.a_param, app.b_param, ~, ~, ~] = extract_optimized_params(app);
            [app.a_param_continuous, app.b_param_continuous, ~, ~, ~] = extract_optimized_params(app);
            app.bin_selection_field.Value = '';
            update_param_displays(app)
            plot_latency(app)
            update_dropdown_items(app)

            % generate fit plot
            generate_fit_display(app)
        end

        function add_red_frame(app)
            % Get the axis limits
            xlims = xlim(app.erp_display);
            ylims = ylim(app.erp_display);
            
            % Define the rectangle around the plot
            rect_position = [xlims(1), ylims(1), diff(xlims), diff(ylims)];
            
            % Add a red rectangle around the plot
            rectangle(app.erp_display, 'Position', rect_position, 'EdgeColor', 'red', 'LineWidth', 2);
        end


        function a_spinnerValueChanged(app, event)
            app.a_param = app.a_spinner.Value;
            plot_latency(app)
            update_param_displays(app)
        end

        function b_spinnerValueChanged(app, event)
            app.b_param = app.b_spinner.Value;
            plot_latency(app)
            update_param_displays(app)
        end

        % Value changed function: a_field
        function a_fieldValueChanged(app, event)
            app.a_param = app.a_field.Value;
            plot_latency(app)
            update_param_displays(app)
            
        end

        % Value changed function: a_field
        function b_fieldValueChanged(app, event)
            app.b_param = app.b_field.Value;
            plot_latency(app)
            update_param_displays(app)
            
        end

        function exit_buttonButtonPushedFcn(app, event)
            % Promt, are you sure? save information
            % then quit the app and write the new object to 
            % the name specified in exit window
            % Check the value of the save checkbox
            save_value = app.save_check.Value;

            if save_value == 1
                % Prompt user to enter object name in the same window
                objectName = inputdlg('Enter object name:', 'Save Results', 1);
                if isempty(objectName)
                    % User clicked cancel or closed the dialog
                    return;
                end
        
                % Save results to a variable in the global workspace
                globalObjectName = objectName{1};
                assignin('base', globalObjectName, app.final_mat);
                fprintf('Results saved to variable in global workspace: %s\n', globalObjectName);

                % Close the main figure to exit the app
                close(app.review);
            else
                % Ask for confirmation to exit the app
                choice = questdlg('Are you sure you want to exit?', 'Exit Confirmation', 'Yes', 'No', 'No');
                if strcmp(choice, 'Yes')
                    % Close the main figure to exit the app
                    close(app.review);
                end
            end
        end

        function generate_fit_display(app)
            % use app.fitting approach and method, subject, bin and then
            % generate fit values for different b-params
            % display these using colors in the fit plot

            % generate the color plot indicating the fit for various
            % b-params
            b_params = linspace(0, 3, 1000);

            fit_value = zeros(1, length(b_params));

            % This function will provide new latency, fit_cor and fit_dist
            % estimates for updated a_params and b_params
            current_subject = app.subject;
            current_bin = app.bin;
            current_method = app.baseline_method; % this is why here is baseline method
            time_vec = app.time_vector;

            % Fit the baseline method
            method_entry = app.method_table(current_method, :);
            
            polarity = table2array(method_entry(1, "polarity"));
            electrodes = table2array(method_entry(1, "electrodes"));
            window = cell2mat(table2array(method_entry(1, "window")));
            approach = table2array(method_entry(1, "approach"));
            if approach == "minsq" || approach == "maxcor"
               is_template_matching = 1;
            elseif approach == "area" || approach == "peak" || approach == "liesefeldarea"
                is_template_matching = 0;
            else
                error("Set a proper matching approach")
            end

            if table2array(method_entry(1, "weight")) ~= "none"
                weight_function = eval(strcat("@", table2array(method_entry(1, "weight"))));
            else
                weight_function = @(time_vector, signal, window) ones(length(time_vector), 1);
            end

            ga = squeeze(mean(app.erp_mat(:, electrodes, :, current_bin), 1, 'omitnan'));
            
            if is_template_matching
                signal = squeeze(app.erp_mat(current_subject, electrodes, :, current_bin));
                if all(isnan(signal)) || all(signal == 0)
                    fit_value = NaN;
                else
                    for i = 1:length(b_params)
                        current_b = b_params(i);
                        fits = get_fits(time_vec', signal, ga, [window(1) window(2)], polarity, weight_function, app.a_param, current_b);
                        fit_cor = fits(1);
                        
                        % make this maxcor and minsq compatible
                        fit_value(i) = fit_cor;
                    end
                end
            else
                % In the case of non-template matching, updating a and b
                % will not change anything, so we can just extract the
                % already optimized params
                fit_value = NaN;
            end

            plot(app.fit_display, b_params, fit_value)
            app.fit_xline = xline(app.fit_display, app.b_param);
        end

        function update_fit_display(app)
            delete(app.fit_xline)
            app.fit_xline = xline(app.fit_display, app.b_param_continuous);
        end


        function ylimupper_fieldValueChanged(app, event)
            app.ylimupper = app.ylimupper_field.Value;
            plot_latency(app)
        end

        function ylimlower_fieldValueChanged(app, event)
            app.ylimlower = app.ylimlower_field.Value;
            plot_latency(app)
        end

        function bin_selection_fieldValueChanged(app, event)
            app.additional_bins = eval(strcat("[", app.bin_selection_field.Value, "]"));
            plot_latency(app)
            plot_additional_bins(app)
        end

        function plot_additional_bins(app)
            hold(app.erp_display, 'on')
            
            current_subject = app.subject;
            electrodes = table2array(app.method_table(app.method, "electrodes"));

            % plot all other bins with color
            for additional_bin = app.additional_bins
                plot( ...
                    app.time_vector, ...
                    squeeze(app.erp_mat(current_subject, electrodes, :, additional_bin)), '--', ...
                    'Color', [0.7, 0.7, 1], ...
                    'Parent', app.erp_display, ...
                    'DisplayName', strcat('Bin ', num2str(additional_bin)))
            end

            % Add the legend

            hold(app.erp_display, 'off')
        end

        function subject_selection_fieldValueChanged(app, event)
            app.subject = app.subject_selection_field.Value;

            [app.a_param, app.b_param] = extract_optimized_params(app);
            [app.a_param_continuous, app.b_param_continuous] = extract_optimized_params(app);
            app.bin_selection_field.Value = '';
            update_param_displays(app)
            plot_latency(app)
            update_dropdown_items(app)

            % generate fit plot
            generate_fit_display(app)
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Set initial values
            app.extreme_pars = 1;
            app.method = app.baseline_method;
            app.nbins = length(squeeze(app.erp_mat(1, 1, 1, :)));

            % initialize results, fit to everything
            if isempty(app.results_mat)
                run_template_matching_app(app);
            end

            % Initialize the matrix of reviews
            flag_for_review(app);

            % Initialize final results
            init_final_results(app);

            % Initialize which person to review
            app.ireview = 1;
            app.subject = app.review_mat(app.ireview, 1);
            app.bin = app.review_mat(app.ireview, 2);

            [app.a_param, app.b_param, ~, ~, ~] = extract_optimized_params(app);
            [app.a_param_continuous, app.b_param_continuous, ~, ~, ~] = extract_optimized_params(app);

            % Create review and hide until all components are created
            app.review = uifigure('Visible', 'off');
            app.review.Position = [100 100 762 541];
            app.review.Name = 'MATLAB App';

            % Create erp_display
            app.erp_display = uiaxes(app.review);
            xlabel(app.erp_display, 'X')
            ylabel(app.erp_display, 'Y')
            zlabel(app.erp_display, 'Z')
            app.erp_display.ButtonDownFcn = createCallbackFcn(app, @erp_displayButtonDown, true);
            app.erp_display.Position = [38 219 633 306];

            % Create fit_display
            app.fit_display = uiaxes(app.review);
            app.fit_display.XLim = [0 3];
            app.fit_display.YLim = [0 1];
            app.fit_display.YTickLabel = '';
            app.fit_display.Position = [78 182 593 38];

            % Create bSliderLabel
            app.bSliderLabel = uilabel(app.review);
            app.bSliderLabel.HorizontalAlignment = 'right';
            app.bSliderLabel.Position = [26 160 25 22];
            app.bSliderLabel.Text = 'b';

            % Create b_slider
            app.b_slider = uislider(app.review);
            app.b_slider.Limits = [0 3];
            app.b_slider.MajorTicks = [0 0.25 0.5 0.75 1 1.25 1.5 1.75 2 2.25 2.5 2.75 3];
            app.b_slider.ValueChangedFcn = createCallbackFcn(app, @b_sliderValueChanged, true);
            app.b_slider.ValueChangingFcn = createCallbackFcn(app, @b_sliderValueChanging, true);
            app.b_slider.Position = [78 168 593 7];

            % Create manual_button
            app.manual_button = uibutton(app.review, 'push');
            app.manual_button.ButtonPushedFcn = createCallbackFcn(app, @manual_buttonButtonPushed, true);
            app.manual_button.Position = [345 84 101 31];
            app.manual_button.Text = 'Accept';

            % Create reject_button
            app.reject_button = uibutton(app.review, 'push');
            app.reject_button.ButtonPushedFcn = createCallbackFcn(app, @reject_buttonButtonPushed, true);
            app.reject_button.Position = [501 84 101 31];
            app.reject_button.Text = 'Reject';

            % Create restore_button
            app.restore_button = uibutton(app.review, 'push');
            app.restore_button.ButtonPushedFcn = createCallbackFcn(app, @restore_buttonButtonPushed, true);
            app.restore_button.Position = [189 84 101 31];
            app.restore_button.Text = 'Restore';

            % Create aSliderLabel
            app.aSliderLabel = uilabel(app.review);
            app.aSliderLabel.HorizontalAlignment = 'right';
            app.aSliderLabel.Position = [653 219 25 21];
            app.aSliderLabel.Text = 'a';

            % Create a_slider
            app.a_slider = uislider(app.review);
            app.a_slider.Limits = [0 10];
            app.a_slider.Orientation = 'vertical';
            app.a_slider.ValueChangedFcn = createCallbackFcn(app, @a_sliderValueChanged, true);
            app.a_slider.ValueChangingFcn = createCallbackFcn(app, @a_sliderValueChanging, true);
            app.a_slider.Position = [686 257 7 247];

            % Create previous_button
            app.previous_button = uibutton(app.review, 'push');
            app.previous_button.ButtonPushedFcn = createCallbackFcn(app, @previous_buttonButtonPushed, true);
            app.previous_button.Position = [26 18 101 31];
            app.previous_button.Text = 'Previous';

            % Create next_button
            app.next_button = uibutton(app.review, 'push');
            app.next_button.ButtonPushedFcn = createCallbackFcn(app, @next_buttonButtonPushed, true);
            app.next_button.Position = [628 18 101 31];
            app.next_button.Text = 'Next';

            % Create MainBinLabel
            app.MainBinLabel = uilabel(app.review);
            app.MainBinLabel.HorizontalAlignment = 'right';
            app.MainBinLabel.Position = [137 22 52 22];
            app.MainBinLabel.Text = 'Main Bin';

            % Create bin_dropdown
            app.bin_dropdown = uidropdown(app.review);
            %app.bin_dropdown.DropDownOpeningFcn = createCallbackFcn(app, @bin_dropdownDropDownOpening, true);
            app.bin_dropdown.ValueChangedFcn = createCallbackFcn(app, @bin_dropdownValueChanged, true);
            %app.bin_dropdown.ClickedFcn = createCallbackFcn(app, @bin_dropdownClicked, true);
            app.bin_dropdown.Position = [204 19 38 28];

            % Create b_field
            app.b_field = uieditfield(app.review, 'numeric');
            app.b_field.ValueChangedFcn = createCallbackFcn(app, @b_fieldValueChanged, true);
            app.b_field.Position = [9 138 42 22];
            app.b_field.Value = round(app.b_param, 3);

            % Create a_field
            app.a_field = uieditfield(app.review, 'numeric');
            app.a_field.ValueChangedFcn = createCallbackFcn(app, @a_fieldValueChanged, true);
            app.a_field.Position = [685 218 42 22];
            app.a_field.Value = round(app.a_param, 3);

            % Create b_spinner
            app.b_spinner = uispinner(app.review, "Limits",[0.25 3], "Step", 0.01);
            app.b_spinner.ValueChangedFcn = createCallbackFcn(app, @b_spinnerValueChanged, true);
            app.b_spinner.Position = [49 138 24 22];

            % Create a_spinner
            app.a_spinner = uispinner(app.review, "Limits",[0 10], "Step", 0.01);
            app.a_spinner.ValueChangedFcn = createCallbackFcn(app, @a_spinnerValueChanged, true);
            app.a_spinner.Position = [728 218 24 22];

            % Create bin_selection_field
            app.bin_selection_field = uieditfield(app.review, 'text');
            app.bin_selection_field.ValueChangedFcn = createCallbackFcn(app, @bin_selection_fieldValueChanged, true);
            app.bin_selection_field.Position = [251 21 80 22];

            % Create subject_selection_field
            app.subject_selection_field = uieditfield(app.review, 'numeric');
            app.subject_selection_field.ValueChangedFcn = createCallbackFcn(app, @subject_selection_fieldValueChanged, true);
            app.subject_selection_field.Position = [350 21 80 22];
            app.subject_selection_field.Value = app.subject;

            % Create exit_button
            app.exit_button = uibutton(app.review, 'push');
            app.exit_button.Position = [725 519 39 23];
            app.exit_button.ButtonPushedFcn = createCallbackFcn(app, @exit_buttonButtonPushedFcn, true);
            app.exit_button.Text = 'Exit';

            % Create save_check
            app.save_check = uicheckbox(app.review);
            app.save_check.Text = 'Save';
            app.save_check.Position = [672 519 50 22];
            app.save_check.Value = 1;

            % Create ylimupper
            app.ylimupper_field = uieditfield(app.review, 'numeric');
            app.ylimupper_field.ValueChangedFcn = createCallbackFcn(app, @ylimupper_fieldValueChanged, true);
            app.ylimupper_field.Position = [26 239 25 19];
            app.ylimupper_field.Value = app.ylimupper;

            % Create ylimlower
            app.ylimlower_field = uieditfield(app.review, 'numeric');
            app.ylimlower_field.ValueChangedFcn = createCallbackFcn(app, @ylimlower_fieldValueChanged, true);
            app.ylimlower_field.Position = [26 503 25 19];
            app.ylimlower_field.Value = app.ylimlower;

            % Show the figure after all components are created
            app.review.Visible = 'on';

            % Initialize plotting
            restore_default_plot(app)

            % generate fit plot
            generate_fit_display(app)

        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = review_app

            % Call setup function
            specify_review_params(app)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.review)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.review)
        end
    end
end