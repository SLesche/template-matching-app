% This function sets all displays to the current app params
function update_param_displays(app)
    a = app.a_param;
    b = app.b_param;
    if b < 0.25 || b > 3 || isnan(b)
        b = 1;                
    end
    if a < 0 || a > 10 || isnan(a)
        a = 1;
    end
    app.b_slider.Value = b;
    app.a_slider.Value = a;
    % app.b_field.Value = round(b, 3);
    % app.a_field.Value = round(a, 3);
    % app.b_spinner.Value = b;
    % app.a_spinner.Value = a;

    update_fit_display(app);
end