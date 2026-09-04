# Convert cached national Overpass responses into one small, portable database.
# Requests must contain full ways, node ids and geometry (`out body geom`).
suppressPackageStartupMessages({library(sf);library(jsonlite)})
files <- list.files('data/downloads',pattern='^rivers_.*[.]json$',full.names=TRUE)
if(!length(files)) stop('No river responses found. See scripts/download_rivers.R.')
responses <- lapply(files,fromJSON,simplifyVector=FALSE)
for(x in responses) if(!is.null(x$remark)) stop(x$remark)
ways <- unlist(lapply(responses,function(x) x$elements),recursive=FALSE)
ways <- Filter(function(x) x$type=='way' && length(x$geometry)>1,ways)
ids <- vapply(ways,function(x) as.character(x$id),character(1))
ways <- ways[!duplicated(ids)]
tag <- function(x,k) if(is.null(x$tags[[k]])) NA_character_ else as.character(x$tags[[k]])
geom <- st_sfc(lapply(ways,function(x) st_linestring(do.call(rbind,lapply(x$geometry,function(p) c(p$lon,p$lat))))),crs=4326)
rivers <- st_sf(osm_id=vapply(ways,function(x) as.character(x$id),character(1)),
 name=vapply(ways,tag,character(1),k='name'),
 name_en=vapply(ways,tag,character(1),k='name:en'),
 waterway=vapply(ways,tag,character(1),k='waterway'),
 intermittent=vapply(ways,tag,character(1),k='intermittent'),
 tunnel=vapply(ways,tag,character(1),k='tunnel'),
 geometry=geom)
stopifnot(nrow(rivers)>0L,!anyDuplicated(rivers$osm_id),all(st_is_valid(rivers)))
st_write(rivers,'inst/extdata/rivers_osm.gpkg',layer='rivers',delete_dsn=TRUE,quiet=TRUE)
provenance <- data.frame(file=basename(files),timestamp=vapply(responses,function(x) x$osm3s$timestamp_osm_base,character(1)))
write.csv(provenance,'inst/extdata/river_snapshots.csv',row.names=FALSE)
cat('Unique national river ways:',nrow(rivers),'\n')
