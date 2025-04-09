function update_fit_display(app)
    delete(app.fit_xline)
    app.fit_xline = xline(app.fit_display, app.b_param_continuous);
end