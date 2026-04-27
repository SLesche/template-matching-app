function recompute_latencies(app)
    % Recompute latency (column 3) using:
    % latency = b * GA latency (vectorized)
    
    b = app.results_mat(:, :, 2);        % [subjects x bins]
    ga = app.ga_latencies(:)';             % [1 x bins] force row vector
    
    % --- Safety: avoid divide-by-zero / NaNs ---
    ga(~isfinite(ga)) = NaN;
    
    % --- Vectorized computation ---
    app.results_mat(:, :, 3) = b .* ga;
    app.final_mat(:, :, 3) = b .* ga; 
end