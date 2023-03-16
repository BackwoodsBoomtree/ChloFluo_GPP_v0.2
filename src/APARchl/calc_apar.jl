
###############################################################################
#
# Calculate APARchl
#
# 
#
###############################################################################

function day_length(doy, lat)
    _decl = 23.45 * sind(360 * (283 + doy) / 365);

    if -tand(lat) * tand(_decl) <= -1
        return 24
    elseif -tand(lat) * tand(_decl) > 1
        return 0
    else
        return 2 * acosd(-tand(lat) * tand(_decl)) / 15
    end
end

function calc_apar(sif::String, y::String)
    sif_data = Dataset(sif)["sif743_qc"][:,:,:]
    yield   = Dataset(y)["sif_yield"][:,:,:]
    lat = Dataset(sif)["lat"][:]
    
    sif_data = replace!(sif_data, missing => NaN)
    yield   = replace!(yield, missing => NaN)

    # Get day length correction factor
    lat_array = similar(sif_data, Float32)
    doy_array = similar(sif_data, Float32)

    # Build array of lats and doy
    for i in 1:size(lat_array)[3]
        for j in 1:size(lat_array)[1]
            lat_array[j,:,i] = lat
        end
        doy_array[:,:,i] .= i * 8 - 4
    end
    doy_array[:,:,46] .= 363

    day_factor = day_length.(doy_array, lat_array) ./ 24

    apar                = sif_data ./ yield .* day_factor
    apar                = replace!(apar, missing => NaN)
    apar[apar .< 0]    .= NaN;
    apar[apar .== Inf] .= NaN;

    # Arrange rasters dims to match
    apar                = permutedims(apar, [2,1,3])

    println("APARchl has been calculated.")
    return(apar)
end