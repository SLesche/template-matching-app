function validate_final_mat(app, final_mat)
    % Ensure final_mat is valid and compatible

    if ~isnumeric(final_mat) || ndims(final_mat) ~= 3
        error('final_mat must be a numeric 3D matrix.');
    end

    % Ensure compatibility with results_mat
    expectedSize = size(app.results_mat);
    expectedSize(3) = expectedSize(3) + 2; % final_mat has 2 extra params

    if ~isequal(size(final_mat), expectedSize)
        error('Size mismatch: expected final_mat size [%s], got [%s].', ...
            num2str(expectedSize), num2str(size(final_mat)));
    end
end
