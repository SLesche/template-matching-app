function [ERP, ALLERP] = fetch_erp_files(path, keyword)
% fetch_erp_files returns all .erp files that contain a keyword (optional)
%
%   [ERP, ALLERP] = fetch_erp_files(path, keyword)
%
%   Inputs:
%       path    - directory containing ERP files
%       keyword - optional keyword to filter filenames
%
%   Outputs:
%       ERP     - combined ERP structure
%       ALLERP  - array of ERP structures

    if ~exist('keyword', 'var') || isempty(keyword)
        % No keyword: get all .erp files
        list = dir(fullfile(path, '*.erp'));
    else
        % Keyword specified
        list = dir(fullfile(path, ['*', keyword, '*.erp']));
    end

    % Collect filenames
    arr = cell(1, numel(list));
    for i = 1:numel(list)
        arr{i} = list(i).name;   % pop_loaderp expects filenames only
    end

    % Load ERP files
    [ERP, ALLERP] = pop_loaderp('filename', arr, 'filepath', path);

end
