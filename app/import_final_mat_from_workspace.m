function final_mat = import_final_mat_from_workspace(app)
    % Import final_mat from base workspace

    % Prompt for variable name
    answer = inputdlg( ...
        'Enter workspace variable name:', ...
        'Import from Workspace', ...
        [1 50], ...
        {'final_mat'} );

    if isempty(answer)
        disp('Workspace import cancelled.');
        final_mat = [];
        return;
    end

    varName = strtrim(answer{1});

    % Check existence
    if ~evalin('base', sprintf('exist(''%s'',''var'')', varName))
        error('Variable "%s" does not exist in base workspace.', varName);
    end

    try
        final_mat = evalin('base', varName);
    catch ME
        error('Failed to read workspace variable: %s', ME.message);
    end

    % Validate matrix
    validate_final_mat(app, final_mat);

    disp(['final_mat imported from workspace variable "', varName, '".']);
end
