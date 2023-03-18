library(terra)
library(viridis)

data       <- "G:/CLIMA/a8_gm2_wd1_2019_1X_8D.c3.epar.nc"
coastlines <- "C:/Russell/R_Scripts/TROPOMI_2/mapping/GSHHS_shp/c/GSHHS_c_L1.shp"

r <- rast(data, subds = "mSIF740")
v <- vect(coastlines)

##### Clip to shapefile #####
clipped <- mask(r, v, touches = FALSE)

# 
# ##### OPTIONAL: Remove pixels with low n for the year #####
# len <- function(x) {
#   length(x[!is.na(x)])
# }
# 
# count <- app(clipped, fun = len)


##### Set NAs to 0 where values appear during the year #####

# Get map of all gridcells that had a value in the year for masking
mask <- app(clipped, "mean", na.rm = TRUE)
mask[mask >= 0] <- 1
mask[is.na(mask)] <- 0

# Compare values in mask and source layer and replace NaN in source with 0
# if mask indicates there is a value for that gridcell in the time series
val_m <- values(mask)

for (i in 1:nlyr(clipped)) {
  val_s <- values(clipped[[i]])
  val_new <- matrix(0, nrow = nrow(val_m), ncol = ncol(val_m))
  
  for (j in 1:length(val_s)) {
    if (is.na(val_s[j]) && val_m[j] == 1) {
      val_new[j] <- 0
    } else {
      val_new[j] <- val_s[j]
    }
  }
  values(clipped[[i]]) <- val_new
}


plot(clipped[[1]], xlim = c(100,150), ylim = c(-10, 10))
plot(v, add = TRUE)

writeCDF(clipped, "G:/CLIMA/clipfill/a8_gm2_wd1_2019_1X_8D.c3.epar.clipfill.nc",
         varname = "clima_sif", longname = "Daily Solar Induced Chlorophyll Fluorescence", unit = "mW/m2/sr/nm",
         missval = -9999, overwrite = TRUE)
