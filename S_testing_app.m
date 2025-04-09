clear all;

%% Set paths
addpath("functions\")
addpath("app\")

% Setting paths
% Get the directory of the currently executing script
[filepath, ~, ~] = fileparts(mfilename('fullpath'));

% Set the current directory to that directory
cd(filepath);

% Path for files
PATH_ERP = fullfile(filepath, "data\flanker_16");

%% Load ERPs
[erp, allerp] = fetch_erp_files(char(PATH_ERP));
[erp_data, time_vec] = convert_eeglab_to_rawdata(allerp);

%% Add configuration
cfg = struct();
cfg.approach = "maxcor";
cfg.weight = "get_normalized_weights";
cfg.penalty = "exponential_penalty";
cfg.normalization = "none";
cfg.use_derivative = 0;
cfg.component_name = "p3_flanker";
cfg.polarity = "positive";
cfg.electrodes = 11;
cfg.window = [250 700];
cfg.cutoff = 0.3;
cfg.extreme_b = 1.5;

%% Run matching
results_mat = run_template_matching(erp_data, time_vec, cfg);

%% Start review app
review_app

