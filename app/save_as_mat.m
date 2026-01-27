function save_as_mat(app)
    % This function exports app.final_mat as a MAT file

    % Prompt user for file location
    [filename, pathname] = uiputfile('*.mat', 'Save final_mat as MAT');
    if isequal(filename, 0)
        disp('Export cancelled.');
        return;
    end

    fullpath = fullfile(pathname, filename);

    % Extract data
    final_mat = app.final_mat;

    try
        % Save MAT file
        save(fullpath, 'final_mat', '-v7.3');

        disp(['final_mat saved to: ', fullpath]);

    catch ME
        error('Error writing MAT file: %s', ME.message);
    end
end

