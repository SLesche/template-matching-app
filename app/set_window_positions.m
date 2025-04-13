function set_window_positions(app)
    % Get relative screen size and position
    screenSize = get(0, 'ScreenSize');

    centerX = screenSize(3)/2;
    centerY = screenSize(4)/2;

    % Place the main window in the center of the screen, with offset of 10% of screen width

    offsetX = screenSize(3) * 0.1; % 10% of screen width
    mainWindowWidth = 762;
    mainWindowHeight = 541;
    mainWindowX = centerX - mainWindowWidth/2 - offsetX;
    mainWindowY = centerY - mainWindowHeight/2;
    mainWindowPosition = [mainWindowX, mainWindowY, mainWindowWidth, mainWindowHeight];

    % Set the main window position
    app.review.Position = mainWindowPosition;

    % Position the overview table to the right of the main window
    overviewTableWidth = 625;
    overviewTableHeight = 300;
    
    overviewTableX = mainWindowX + mainWindowWidth + 10; % 10 pixels to the right of the main window
    overviewTableY = centerY + mainWindowHeight/2 - overviewTableHeight; % Align with the top of the main window
    overviewTablePosition = [overviewTableX, overviewTableY, overviewTableWidth, overviewTableHeight];

    % Set the overview table position
    app.table_window.Position = overviewTablePosition;
end