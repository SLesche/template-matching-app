function plot_additional_bins(app)
    % Create a dialog window
    d = dialog('Position', [300 300 250 150], 'Name', 'Enter Bin Numbers to add (MATLAB syntax)');

    % % ERP number label and input
    % uicontrol('Parent', d, ...
    %         'Style', 'text', ...
    %         'Position', [20 100 80 20], ...
    %         'String', 'ERP number:');
    % erpField = uicontrol('Parent', d, ...
    %                     'Style', 'edit', ...
    %                     'Position', [110 100 100 20]);

    % Bin number label and input
    uicontrol('Parent', d, ...
            'Style', 'text', ...
            'Position', [20 60 80 20], ...
            'String', 'Bin number:');
    binField = uicontrol('Parent', d, ...
                        'Style', 'edit', ...
                        'Position', [110 60 100 20]);

    % OK button
    uicontrol('Parent', d, ...
            'Position', [85 20 70 25], ...
            'String', 'OK', ...
            'Callback', @(src, event) onConfirm());

    % Wait for the dialog to close before returning
    uiwait(d);

    % Callback for OK button
    function onConfirm()
        % erp_num = str2double(erpField.String);
        bin_nums = eval(binField.String);

        % Remove the current bin from this
        bin_nums(bin_nums == app.bin_num) = [];

        % Plot the additional bins
        if ~isempty(bin_nums)
            hold(app.erp_display, 'on')
            
            current_erp = app.erp_num;
            electrodes = app.cfg.electrodes;

            % plot all other bins with color
            for additional_bin = bin_nums
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

        uiresume(d);  % Resume execution of the main function
        delete(d);    % Close the dialog
    end
end
