classdef review_app < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        % Generate Review Window
        review               matlab.ui.Figure

        fileMenu             matlab.ui.container.Menu
        openItem             matlab.ui.container.Menu
        saveItem             matlab.ui.container.Menu
        exitItem             matlab.ui.container.Menu
        importItem           matlab.ui.container.Menu

        settingsMenu         matlab.ui.container.Menu
        preferencesItem      matlab.ui.container.Menu
        settings_window      matlab.ui.Figure
            positiveUpField      matlab.ui.control.CheckBox
            lineWidthField       matlab.ui.control.NumericEditField
            ylimlowerField       matlab.ui.control.NumericEditField
            ylimupperField       matlab.ui.control.NumericEditField
            legendLocationField  matlab.ui.control.EditField
            displayAutoLatField  matlab.ui.control.CheckBox
            displayLegendField    matlab.ui.control.CheckBox
            displayInfoField      matlab.ui.control.CheckBox
            autoJumpField        matlab.ui.control.DropDown
            filterDecisionField  matlab.ui.control.DropDown
            filterFitField      matlab.ui.control.EditField
            filterStatusField   matlab.ui.control.DropDown
        
        compareMenu          matlab.ui.container.Menu
        compareApproachesItem      matlab.ui.container.Menu
        compareERPsItem      matlab.ui.container.Menu

        erp_display          matlab.ui.control.UIAxes
        fit_display          matlab.ui.control.UIAxes

        % Init Plots
        ga_plot              matlab.graphics.chart.primitive.Line
        matched_xline        matlab.graphics.chart.decoration.ConstantLine
        additional_bins      double
        fit_xline            matlab.graphics.chart.decoration.ConstantLine

        a_slider             matlab.ui.control.Slider
        % aSliderLabel         matlab.ui.control.Label
        % a_field              matlab.ui.control.NumericEditField
        % a_spinner            matlab.ui.control.Spinner

        b_slider             matlab.ui.control.Slider
        % bSliderLabel         matlab.ui.control.Label
        % b_field              matlab.ui.control.NumericEditField
        % b_spinner            matlab.ui.control.Spinner

        next_button          matlab.ui.control.Button
        previous_button      matlab.ui.control.Button
        jumpprevious_button  matlab.ui.control.Button
        jumpnext_button      matlab.ui.control.Button
        reject_button        matlab.ui.control.Button
        manual_button        matlab.ui.control.Button
        restore_button       matlab.ui.control.Button
        search_button        matlab.ui.control.Button
        add_button           matlab.ui.control.Button

        bin_selection_field  matlab.ui.control.EditField
        erp_selection_field  matlab.ui.control.NumericEditField
        bin_dropdown         matlab.ui.control.DropDown
        MainBinLabel         matlab.ui.control.Label

        % Overview Table
        table_window         matlab.ui.Figure
        overview_table       matlab.ui.control.Table

        progressContainer    matlab.ui.container.Panel
        progressDefaultFill  matlab.ui.container.Panel
        progressReviewedFill matlab.ui.container.Panel
        progressLabel        matlab.ui.control.Label

        % Setup Data Structuress
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

        % Init plot settings
        settings struct % The structure for the settings of the plot
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
            write_info(app, review_method, app.erp_num, app.bin_num, a, b, latency, fit_cor, fit_dist)

            jump_to_next_review(app)

            load_new_plot(app)
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
            write_info(app, review_method, app.erp_num, app.bin_num, a, b, latency, fit_cor, fit_dist)

            % move to next review
            if app.settings.auto_jump_behavior == "Jump to next review"
                % move ireview
                jump_to_next_review(app)
            elseif app.settings.auto_jump_behavior == "Move to next ERP"
                % move ireview
                go_to_next_erp(app)
            end

            % New plot
            load_new_plot(app)
        end

        function restore_buttonButtonPushed(app, event)
            % If restore defaults
            restore_default_plot(app, "original")
        end

        % Button pushed function: previous_button
        function jumpprevious_buttonButtonPushed(app, event)
            % move ireview
            jump_to_previous_review(app)

            load_new_plot(app)
        end

        % Button pushed function: previous_button
        function jumpnext_buttonButtonPushed(app, event)
            % move ireview
            jump_to_next_review(app)

            load_new_plot(app)
        end

        % Button pushed function: previous_button
        function previous_buttonButtonPushed(app, event)
            % move ireview
            go_to_previous_erp(app)

            load_new_plot(app)
        end

        % Button pushed function: previous_button
        function next_buttonButtonPushed(app, event)
            % move ireview
            go_to_next_erp(app)

            load_new_plot(app)
        end

        % Button pushed function: previous_button
        function search_buttonButtonPushed(app, event)
            % move ireview
            [new_erp_num, new_bin_num] = search_for_erp(app);

            app.erp_num = new_erp_num;
            app.bin_num = new_bin_num;

            load_new_plot(app)
        end

        % Button pushed function: previous_button
        function add_buttonButtonPushed(app, event)
            plot_additional_bins(app)
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

        function saveItemMenuSelectedFcn(app, event)
            export_final_mat(app)

            % Close the main figure to exit the app
            close(app.table_window);
            close(app.review);

        end

        function importItemMenuSelectedFcn(app, event)
           imported_final_mat = import_final_mat(app);

           app.final_mat = imported_final_mat;

           load_new_plot(app)
        end

        function exitItemMenuSelectedFcn(app, event)
            % Ask for confirmation to exit the app
            choice = questdlg('Are you sure you want to exit?', 'Exit Confirmation', 'Yes', 'No', 'No');
            if strcmp(choice, 'Yes')
                % Close the main figure to exit the app
                close(app.table_window);
                close(app.review);
            end
        end

        function on_review_resize(app)
            %disp("Resizing review window");
            %set_window_positions(app);
            set_component_positions(app);
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
            app.review.Name = 'Review Window';
            app.review.AutoResizeChildren = 'off';
            app.review.SizeChangedFcn = @(src, event) on_review_resize(app);


            % Create erp_display
            app.erp_display = uiaxes(app.review);
            xlabel(app.erp_display, 'X')
            ylabel(app.erp_display, 'Y')
            zlabel(app.erp_display, 'Z')
            app.erp_display.ButtonDownFcn = createCallbackFcn(app, @erp_displayButtonDown, true);
            %app.erp_display.Position = [38 219 633 306];

            % Create fit_display
            app.fit_display = uiaxes(app.review);
            app.fit_display.XLim = [0 3];
            app.fit_display.YLim = [0 1];
            app.fit_display.YTickLabel = '';
            %app.fit_display.Position = [78 182 593 38];

            % % Create bSliderLabel
            % app.bSliderLabel = uilabel(app.review);
            % app.bSliderLabel.HorizontalAlignment = 'right';
            % app.bSliderLabel.Position = [26 160 25 22];
            % app.bSliderLabel.Text = 'b';

            % Create b_slider
            app.b_slider = uislider(app.review);
            app.b_slider.Limits = [0 3];
            app.b_slider.MajorTicks = [0 0.25 0.5 0.75 1 1.25 1.5 1.75 2 2.25 2.5 2.75 3];
            app.b_slider.ValueChangedFcn = createCallbackFcn(app, @b_sliderValueChanged, true);
            app.b_slider.ValueChangingFcn = createCallbackFcn(app, @b_sliderValueChanging, true);
            %app.b_slider.Position = [78 168 593 7];

            % Create manual_button
            app.manual_button = uibutton(app.review, 'push');
            app.manual_button.ButtonPushedFcn = createCallbackFcn(app, @manual_buttonButtonPushed, true);
            %app.manual_button.Position = [345 84 101 31];
            app.manual_button.Text = '';
            app.manual_button.Icon = 'app/src/accept_icon.svg';

            % Create reject_button
            app.reject_button = uibutton(app.review, 'push');
            app.reject_button.ButtonPushedFcn = createCallbackFcn(app, @reject_buttonButtonPushed, true);
            %app.reject_button.Position = [501 84 101 31];
            app.reject_button.Text = '';
            app.reject_button.Icon = 'app/src/reject_icon.svg';

            % Create restore_button
            app.restore_button = uibutton(app.review, 'push');
            app.restore_button.ButtonPushedFcn = createCallbackFcn(app, @restore_buttonButtonPushed, true);
            %app.restore_button.Position = [189 84 101 31];
            app.restore_button.Text = '';
            app.restore_button.Icon = 'app/src/restore_icon.svg';

            % % Create aSliderLabel
            % app.aSliderLabel = uilabel(app.review);
            % app.aSliderLabel.HorizontalAlignment = 'right';
            % app.aSliderLabel.Position = [653 219 25 21];
            % app.aSliderLabel.Text = 'a';

            % Create a_slider
            app.a_slider = uislider(app.review);
            app.a_slider.Limits = [0 10];
            app.a_slider.Orientation = 'vertical';
            app.a_slider.ValueChangedFcn = createCallbackFcn(app, @a_sliderValueChanged, true);
            app.a_slider.ValueChangingFcn = createCallbackFcn(app, @a_sliderValueChanging, true);
            %app.a_slider.Position = [686 257 7 247];

            % Create previous_button
            app.previous_button = uibutton(app.review, 'push');
            app.previous_button.ButtonPushedFcn = createCallbackFcn(app, @previous_buttonButtonPushed, true);
            %app.previous_button.Position = [26 18 101 31];
            app.previous_button.Text = '';
            app.previous_button.Icon = 'app/src/previous_icon.svg';

            % Create next_button
            app.next_button = uibutton(app.review, 'push');
            app.next_button.ButtonPushedFcn = createCallbackFcn(app, @next_buttonButtonPushed, true);
            %app.next_button.Position = [628 18 101 31];
            app.next_button.Text = '';  
            app.next_button.Icon = 'app/src/next_icon.svg';

            % Style settings
            %app.next_button.BackgroundColor = ;  % Custom color (light grey)

            % Create jumpprevious_button
            app.jumpprevious_button = uibutton(app.review, 'push');
            app.jumpprevious_button.ButtonPushedFcn = createCallbackFcn(app, @jumpprevious_buttonButtonPushed, true);
            %app.jumpprevious_button.Position = [26 18 101 31];
            app.jumpprevious_button.Text = '';
            app.jumpprevious_button.Icon = 'app/src/jump_previous_icon.svg';

            % Create jumpnext_button
            app.jumpnext_button = uibutton(app.review, 'push');
            app.jumpnext_button.ButtonPushedFcn = createCallbackFcn(app, @jumpnext_buttonButtonPushed, true);
            %app.jumpnext_button.Position = [26 18 101 31];
            app.jumpnext_button.Text = '';
            app.jumpnext_button.Icon = 'app/src/jump_next_icon.svg';

            % Create search_button
            app.search_button = uibutton(app.review, 'push');
            app.search_button.ButtonPushedFcn = createCallbackFcn(app, @search_buttonButtonPushed, true);
            %app.search_button.Position = [26 18 101 31];
            app.search_button.Text = '';
            app.search_button.Icon = 'app/src/search_icon.svg';

            % Create add_button
            app.add_button = uibutton(app.review, 'push');
            app.add_button.ButtonPushedFcn = createCallbackFcn(app, @add_buttonButtonPushed, true);
            %app.add_button.Position = [26 18 101 31];
            app.add_button.Text = '';
            app.add_button.Icon = 'app/src/add_icon.svg';

            % % Create b_field
            % app.b_field = uieditfield(app.review, 'numeric');
            % app.b_field.ValueChangedFcn = createCallbackFcn(app, @b_fieldValueChanged, true);
            % app.b_field.Position = [9 138 42 22];
            % app.b_field.Value = round(app.b_param, 3);

            % % Create a_field
            % app.a_field = uieditfield(app.review, 'numeric');
            % app.a_field.ValueChangedFcn = createCallbackFcn(app, @a_fieldValueChanged, true);
            % app.a_field.Position = [685 218 42 22];
            % app.a_field.Value = round(app.a_param, 3);

            % % Create b_spinner
            % app.b_spinner = uispinner(app.review, "Limits",[0.25 3], "Step", 0.01);
            % app.b_spinner.ValueChangedFcn = createCallbackFcn(app, @b_spinnerValueChanged, true);
            % app.b_spinner.Position = [49 138 24 22];

            % % Create a_spinner
            % app.a_spinner = uispinner(app.review, "Limits",[0 10], "Step", 0.01);
            % app.a_spinner.ValueChangedFcn = createCallbackFcn(app, @a_spinnerValueChanged, true);
            % app.a_spinner.Position = [728 218 24 22];
  
            % Show the figure after all components are created
            app.review.Visible = 'on';

            % Create the "File" menu
            app.fileMenu = uimenu(app.review);
            app.fileMenu.Text = 'File';

            % Add submenu items under "File"
            % app.openItem = uimenu(app.fileMenu);
            % app.openItem.Text = 'Open...';
            % app.openItem.MenuSelectedFcn = @(src, event) disp('Open selected');

            app.saveItem = uimenu(app.fileMenu);
            app.saveItem.Text = 'Save';
            app.saveItem.MenuSelectedFcn = createCallbackFcn(app, @saveItemMenuSelectedFcn, true);

            app.exitItem = uimenu(app.fileMenu);
            app.exitItem.Text = 'Exit';
            app.exitItem.MenuSelectedFcn =  createCallbackFcn(app, @exitItemMenuSelectedFcn, true);

            app.importItem = uimenu(app.fileMenu);
            app.importItem.Text = 'Import...';
            app.importItem.MenuSelectedFcn = createCallbackFcn(app, @importItemMenuSelectedFcn, true);

            % Create the "Settings" menu
            app.settingsMenu = uimenu(app.review);
            app.settingsMenu.Text = 'Settings';

            % Add a submenu item
            app.preferencesItem = uimenu(app.settingsMenu);
            app.preferencesItem.Text = 'Preferences';
            app.preferencesItem.MenuSelectedFcn = createCallbackFcn(app, @display_settings_window, true);

            % % Create the "Compare" menu
            % app.compareMenu = uimenu(app.review);
            % app.compareMenu.Text = 'Compare';

            % % Add a submenu item
            % app.compareApproachesItem = uimenu(app.compareMenu);
            % app.compareApproachesItem.Text = 'Compare Approaches';
            % app.compareApproachesItem.MenuSelectedFcn = @(src, event) disp('Preferences selected');

            % app.compareERPsItem = uimenu(app.compareMenu);
            % app.compareERPsItem.Text = 'Compare ERPs';
            % app.compareERPsItem.MenuSelectedFcn = @(src, event) disp('Preferences selected');

            % Initialize plotting
            restore_default_plot(app)

            % generate fit plot
            generate_fit_display(app)

            % Init review table
            init_review_overview_table(app)

            % Set positions
            set_window_positions(app)

            set_component_positions(app)
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