a% Specify review params
function specify_review_params(app)
    % Prompt the user for input using a dialog box
    prompt = {'Name of dataset:', 'Name of time vector:', 'Name of configuration', 'Name of results matrix (optional):', 'Name of GA latencies (optional):'};
    dlgTitle = 'Set Review Params';
    numLines = 1;
    defaultInput = {'erp_data', 'time_vec', 'cfg', '', ''};

    userInput = inputdlg(prompt, dlgTitle, numLines, defaultInput);

    % Handle cancel button press or empty inputs
    if isempty(userInput)
        error('User input canceled or empty.');
    end
    
    app.erp_mat = evalin('base', userInput{1});
    app.cfg = evalin('base', userInput{3});
    app.time_vector = evalin('base', userInput{2});
    app.ylimlower = -5;
    app.ylimupper = 9;
    
    if ~isempty(userInput{4})
        app.results_mat = evalin('base', userInput{4});
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

    if ~isempty(userInput{5})
        app.ga_latencies = evalin('base', userInput{5});
        n_bins = size(app.erp_mat, 4);

        if length(app.ga_latencies) ~= n_bins
            error('This vector should contain one latency per bin');
        end
    end
end