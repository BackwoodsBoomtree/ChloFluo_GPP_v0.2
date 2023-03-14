###############################################################################
#
# Calculate SIFyield
#
# Input are CLIMA simulations
#
# Output is one file for each year.
#
###############################################################################


function calc_yield(infile)
    sif  = Dataset(infile)["mSIF740"][:,:,:];
    apar = Dataset(infile)["mPPAR"][:,:,:];

    println("Adjusting SIF values for area.")
    zoom = 1; # spatial resolution is 1/zoom degree
    pft_cover   = load_LUT(PFTPercentCLM{Float32}(), zoom);
    land_cover  = load_LUT(LandMaskERA5{Float32}(), zoom, nan_weight = true);
    corr_factor = min.(land_cover.data[:,:,1], 1 .- pft_cover.data[:,:,1] ./ 100);

    sif = sif ./ corr_factor

    apar  = apar .* 10^6; # convert mol to umol/m2/s1

    yield = sif ./ apar;

    yield = permutedims(yield, [2,1,3]);

    return(yield)
end