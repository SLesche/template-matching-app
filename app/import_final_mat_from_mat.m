function final_mat = import_final_mat_from_mat(app)
    % Import final_mat from a MAT file and validate dimensions

    % Prompt user to select a MAT file
    [filename, pathname] = uigetfile('*.mat', 'Select a MAT file containing final_mat');
    if isequal(filename, 0)
        disp('File selection cancelled.');
        final_mat = [];
        return;
    end

    fullpath = fullfile(pathname, filename);

    try
        S = load(fullpath);
    catch ME
        error('Failed to load MAT file: %s', ME.message);
    end

    % Expect exactly one variable OR a variable named final_mat
    if isfield(S, 'final_mat')
        final_mat = S.final_mat;
    elseif numel(fieldnames(S)) == 1
        fn = fieldnames(S);
        final_mat = S.(fn{1});
    else
        error('MAT file must contain a variable named "final_mat" or only one variable.');
    end

    % Validate matrix
    validate_final_mat(app, final_mat);

    disp(['final_mat imported from MAT file: ', fullpath]);
end
