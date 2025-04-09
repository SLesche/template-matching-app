function [erp_data, time_vector] = convert_eeglab_to_rawdata(allerp)

    time_vector = allerp(1).times;
    
    n_erps = length(allerp);
    
    erp_data = zeros([n_erps, size(allerp(1).bindata)]);
    
    for ierp = 1:n_erps
        erp_data(ierp, :, :, :) = allerp(ierp).bindata;
    end

end