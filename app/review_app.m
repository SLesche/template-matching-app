classdef review_app < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        review               matlab.ui.Figure
        bin_selection_field  matlab.ui.control.EditField
        erp_selection_field matlab.ui.control.NumericEditField
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
        % Setup
        erp_mat double % The data matrix with erps X channels X times X bins
        time_vector double % The vector showing times
        results_mat double % Results matrix with erps X bins X n_params
        ga_mat double % Matrix for storing grand average information
        ga_latencies double % Latencies of the grand average, should be size [1, n_bins]
        cfg struct % The configuration structure for the data
        
        % Init ERP number and bin
        erp_num double % ERP number
        nbins double % number of bins
        bin_num double % Bin

        % Init result matrices
        final_mat double % All information goes in here

        % Init parameters
        a_param double % current a param
        b_param double % current b param
        a_param_continuous double
        b_param_continuous double

        % Init Plots
        ga_plot matlab.graphics.chart.primitive.Line
        matched_xline matlab.graphics.chart.decoration.ConstantLine
        additional_bins double
        fit_xline matlab.graphics.chart.decoration.ConstantLine

        % Init plot settings
        ylimupper double % Default params set at beginning
        ylimlower double
    end

    % Callbacks that handle component events
    methods (Access = private)
        % Button pushed function: reject_button
        function reject_buttonButtonPushed(app, event)
            % reject the default values
            restore_default_plot(app, "original")
            [a, b, latency, fit_cor, fit_dist] = extract_optimized_params(app);
            
            % write reject info into struct
            review_method = -1; % rejected, so -1
            write_info(app, review_method, app.erp_num, app.bin, a, b, latency, fit_cor, fit_dist)
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
            write_info(app, review_method, app.erp_num, app.bin, a, b, latency, fit_cor, fit_dist)

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

            if app.cfg.approach == "minsq"
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
            
            current_erp = app.erp_num;
            electrodes = app.cfg.electrodes;

            % plot all other bins with color
            for additional_bin = app.additional_bins
                plot( ...
                    app.time_vector, ...
                    squeeze(app.erp_mat(current_erp, electrodes, :, additional_bin)), '--', ...
                    'Color', [0.7, 0.7, 1], ...
                    'Parent', app.erp_display, ...
                    'DisplayName', strcat('Bin ', num2str(additional_bin)))
            end

            % Add the legend

            hold(app.erp_display, 'off')
        end

        function erp_selection_fieldValueChanged(app, event)
            app.erp_num = app.erp_num_selection_field.Value;

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
            % initialize results, fit to everything
            if isempty(app.results_mat)
                run_template_matching_app(app);
            end

            % Initialize final results
            init_final_results(app);

            get_grand_averages(app);

            % Initialize the matrix of reviews
            flag_for_review(app);

            % Initialize which person to review
            app.erp_num = 1;
            app.bin_num = 1;
            app.nbins = size(app.results_mat, 2);

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

            % Create erp_selection_field
            app.erp_selection_field = uieditfield(app.review, 'numeric');
            app.erp_selection_field.ValueChangedFcn = createCallbackFcn(app, @erp_selection_fieldValueChanged, true);
            app.erp_selection_field.Position = [350 21 80 22];
            app.erp_selection_field.Value = app.erp_num;

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