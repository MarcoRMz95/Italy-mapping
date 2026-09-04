# Maintainer script: package the supplied national GIS sources.
# Rscript scripts/prepare_local_data.R /path/to/source_directory
# The directory must contain Limiti01012023 and eleva.
suppressPackageStartupMessages({library(sf);library(terra)})
args <- commandArgs(trailingOnly=TRUE)
if(length(args)!=1L) stop('Supply the directory containing Limiti01012023 and eleva.')
dir.create('data/downloads',recursive=TRUE,showWarnings=FALSE)
dir.create('inst/extdata',recursive=TRUE,showWarnings=FALSE)
read_admin <- function(folder) {
 x <- st_read(file.path(args[1],'Limiti01012023',folder),quiet=TRUE)
 stopifnot(!is.na(st_crs(x)))
 x <- st_make_valid(st_transform(x,32632))
 x[!st_is_empty(x),]
}
regions <- read_admin('Reg01012023')
municipalities <- read_admin('Com01012023')
stopifnot(nrow(regions)==20L,nrow(municipalities)==7901L,
          !anyDuplicated(municipalities$PRO_COM_T),all(municipalities$COD_REG %in% regions$COD_REG))
st_write(regions,'inst/extdata/regions_2023.gpkg',layer='regions',delete_dsn=TRUE,quiet=TRUE)
st_write(municipalities,'data/downloads/municipalities_2023.gpkg',layer='municipalities',delete_dsn=TRUE,quiet=TRUE)
if(!requireNamespace('zip',quietly=TRUE)) stop('Install zip to rebuild the municipal archive.')
zip::zipr(zipfile=file.path(normalizePath('inst/extdata'),'municipalities_2023.gpkg.zip'),
          files='municipalities_2023.gpkg',root='data/downloads')
dem <- rast(file.path(args[1],'eleva/ITA_alt.vrt'))
names(dem) <- 'elevation_m'
writeRaster(dem,'inst/extdata/elevation_italy_30as.tif',overwrite=TRUE,
            datatype='INT2S',NAflag=-9999,gdal=c('COMPRESS=DEFLATE','PREDICTOR=2'))
countries <- st_as_sf(rnaturalearthhires::countries10)
sf_use_s2(FALSE)
countries <- st_make_valid(countries)
extent <- st_bbox(c(xmin=5,ymin=34,xmax=20,ymax=49),crs=st_crs(4326))
# Union in a metric CRS to avoid fine-scale topology issues at shared edges.
countries <- suppressWarnings(st_crop(countries,extent))
countries <- st_make_valid(st_transform(countries,3035))
land <- st_sf(geometry=st_union(st_geometry(countries)))
land <- st_transform(land,4326)
st_write(land,'inst/extdata/land_natural_earth.gpkg',layer='land',delete_dsn=TRUE,quiet=TRUE)
cat('Regions:',nrow(regions),'Municipalities:',nrow(municipalities),'\n')
print(dem)
