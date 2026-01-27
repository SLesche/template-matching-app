%% Set paths
% These paths are necessary to run the functions and app
addpath(fullfile("functions"))
addpath(fullfile("app"))

% Get script location robustly
filepath = fileparts(matlab.desktop.editor.getActiveFilename);
cd(filepath);
disp("Current folder changed to: " + filepath);

% Path for ERP files
PATH_ERP = fullfile(filepath, "data", "flanker_16");


%% Load ERPs
% If you want to load ERPs manually, simply replace this

%eeglab % may not need this if EEGLAB functions are not used to import data
% eeglab functions are not employed in the template matching process

[erp, allerp] = fetch_erp_files(char(PATH_ERP));
[erp_data, time_vec] = convert_eeglab_to_rawdata(allerp);

% erp_data should be a matrix following this format:
% subjects x channels x times x conditions
% time_vec should be a vector with time points

%% Add configuration
cfg = struct();
cfg.approach = "maxcor"; % "maxcor" or "minsq"
cfg.weight = "get_normalized_weights"; % Weighting function
% To define you own weighting function, create a function that returns a vector of weights
% and provide the function name as a string here.

cfg.penalty = "exponential_penalty"; % or "none", or a custom function name
cfg.normalization = "none"; % experimental, not used in publication
cfg.use_derivative = 0; % experimental, not used in publication
cfg.component_name = "p3-flanker"; % Name of the component to be detected
cfg.polarity = "positive";  % "positive" or "negative"
cfg.electrodes = 11; % Index of electrode to be used for matching
cfg.window = [250 700]; % Measurement window based on the time vector (in ms)

% Review settings, not used in matching
cfg.cutoff = 0.6; % Cutoff for review app
cfg.extreme_b = 1.5; % Multiplier for extreme value detection in review app

%% Run matching
%results_mat = run_template_matching(erp_data, time_vec, cfg);
%results_mat = run_template_matching_serial(erp_data, time_vec, cfg); 
% ^ if no parallel processing toolbox available

%writematrix(results_mat, 'data/results_mat.txt'); 

%% Or load previous results
results_mat = reshape(readmatrix('data/results_mat'), 142, 2, 5);

%% Start review app
review_app
    