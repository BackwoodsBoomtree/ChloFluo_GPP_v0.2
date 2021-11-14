###############################################################################
#
# Calculate Maximum LSWI for each year for Wscalar 
#
# Input are the 8-day 0.05-degree MCD43C4 LSWI nc files, which are annual.
# Codes for producting LSWI are here: https://github.com/GeoCarb-OU/MCD43C4_VIs
#
# Output is one file for each year.
#
###############################################################################

using NCDatasets
using DataStructures
using Statistics
# using Colors, Plots

input_nc  = "/mnt/g/ChloFluo/input/LSWI/1deg/MCD43C4.A.2020.LSWI.8-day.1deg.nc";
output_nc = "/mnt/g/ChloFluo/input/LSWImax/1deg/LSWImax.8-day.1deg.2020.nc";
spat_res  = 1.0

# Get maximum lswi
function max_lswi(file::String, spat_res)
    lswi = Dataset(file)["LSWI"]
    data = lswi[:,:]
    data = max_time(data)
    if spat_res != 0.05
        data = reverse(data, dims = 1)
    end
    return data
end

# Get max of timeseries
function max_time(ts_data)
    
    amax = zeros(Float32, size(ts_data)[1], size(ts_data)[2])

    for row in 1:size(ts_data)[1] 
        for col in 1:size(ts_data)[2]
            vals = zeros(0)
            for time in 1:size(ts_data)[3]
                val = ts_data[row, col, time]
                if ismissing(val) == false
                    append!(vals, val)
                end
            end
            if length(vals) != 0    
                m_val          = maximum(vals)
                amax[row, col] = m_val
            else
                amax[row, col] = NaN
            end
        end
    end

    # Scale and change to int to to save space (apply where value ! nan)
    # Commented out scaling because using scale factor negates the fill value. Bug in NCDatasets
    # amax[(!isnan).(amax)] .= round.(amax[(!isnan).(amax)] * 10000)
    amax[isnan.(amax)]    .= -9999
    amax = rotl90(amax)                # Rotate to correct lat/lon
    return(amax)
end

function save_nc(data, path)
    
    ds = Dataset(path, "c")

    ds.attrib["title"]    = "Maximum LSWI"
    ds.attrib["comments"] = "Data computed for ChloFlo model."
    ds.attrib["author"]   = "Russell Doughty, PhD"
    ds.attrib["source"]   = "MCD43C4"

    res = 180 / size(data)[1]
    lat = collect(-90.0 + (res / 2.0) : res : 90.0 - (res / 2.0))
    lon = collect(-180.0 + (res / 2.0) : res : 180.0 - (res / 2.0))

    defDim(ds,"lon", length(lon))
    defDim(ds,"lat", length(lat))

    dsLon    = defVar(ds, "lon" , Float32,("lon",), attrib = ["units" => "degrees_east", "long_name" => "Longitude"])
    dsLat    = defVar(ds, "lat" , Float32,("lat",), attrib = ["units" => "degrees_north", "long_name" => "Latitude"])
    dsLon[:] = lon
    dsLat[:] = lat

    v = defVar(ds, "LSWImax", Float32, ("lat","lon"), deflatelevel = 4, fillvalue = -9999, attrib = ["units" => "Index", "long_name" => "LSWImax"])

    # Scale value does not work
    # v = defVar(ds, "LSWImax", Float32, ("lat","lon"), deflatelevel = 4, fillvalue = -9999, attrib = OrderedDict(
    #     "long_name"    => "LSWImax",
    #     "units"        => "Index",
    #     "scale_factor" => Float32(0.0001),
    #     "add_offset"   => Float32(0.0)))

    v[:,:] = data

    close(ds)
end

data = (max_lswi(input_nc, spat_res));

# Take a look
# heatmap(data, clim = (-5000, 5000), bg = :white, color = :viridis)

save_nc(data, output_nc);