library(italymapping)
regions <- italy_regions()
stopifnot(nrow(regions)==20L, !anyDuplicated(regions$code),
          regions$english[regions$code==5L]=='Veneto')
ref <- citation('italymapping')
stopifnot(grepl('Ramirez Mauricio',paste(format(ref),collapse=' ')),
          grepl('2026',paste(format(ref),collapse=' ')))
bad <- try(plot_italy_map('This region does not exist'),silent=TRUE)
stopifnot(inherits(bad,'try-error'))
bad_bbox <- try(plot_italy_map('Veneto',bbox=c(11,45,10,46)),silent=TRUE)
stopifnot(inherits(bad_bbox,'try-error'))
bad_crs <- try(plot_italy_map('Veneto',crs=4326),silent=TRUE)
stopifnot(inherits(bad_crs,'try-error'))
# A small window verifies installed-data lookup, reprojection, empty label
# subsets, a combined-region selection and actual raster/vector rendering.
p <- plot_italy_map(c('Veneto','Lombardy'),municipalities=FALSE,
                   bbox=c(11.35,45.30,11.65,45.55),resolution_m=1200)
stopifnot(inherits(p,'ggplot'),setequal(attr(p,'italy_mapping')$regions,c(3L,5L)))
out <- file.path(tempdir(),'italymapping-check')
png <- save_italy_map(p,'smoke',output_dir=out,dpi=72,width=4,tiff=FALSE,preview=FALSE)
stopifnot(file.exists(png),file.info(png)$size>1000)
