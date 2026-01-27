function save_to_workspace(app)
    % Save app.final_mat to base workspace with user-defined variable name

    % Prompt user for variable name
    answer = inputdlg( ...
        'Enter variable name for workspace:', ...
        'Save to Workspace', ...
        [1 50], ...
        {'final_mat'} );

    if isempty(answer)
        disp('Save to workspace cancelled.');
        return;
    end

    varName = strtrim(answer{1});

    % Validate variable name
    if ~isvarname(varName)
        uialert(app.review, ...
            'Invalid variable name. Please enter a valid MATLAB variable name.', ...
            'Invalid Name');
        return;
    end

    try
        % Assign to base workspace
        assignin('base', varName, app.final_mat);

        disp(['final_mat saved to workspace as "', varName, '".']);

    catch ME
        uialert(app.review, ...
            sprintf('Error saving to workspace:\n%s', ME.message), ...
            'Save Error');
    end
end
