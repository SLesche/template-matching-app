% Function intializing the results_mat
function run_template_matching_app(app)   
    app.results_mat = run_template_matching_serial(app.erp_mat, app.time_vector, app.cfg);
end