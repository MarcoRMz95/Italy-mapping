# Optional maintainer update. Normal map generation is entirely offline.
# Install curl first: install.packages('curl'). Requests run sequentially.
if(!requireNamespace('curl',quietly=TRUE)) stop('Install the curl package.')
dir.create('data/downloads',recursive=TRUE,showWarnings=FALSE)
bands <- list(north_west=c(44.3,5.5,47.25,9.75),north_east=c(44.35,9.75,47.25,13.9),
              north_east_edge=c(44.3,13.9,47.25,14.3),central=c(41.5,7,44.35,16.5),south=c(34.5,7.5,41.5,19))
for(n in names(bands)) {
 target <- file.path('data/downloads',paste0('rivers_',n,'.json'))
 if(file.exists(target)) {message('Using cached ',target);next}
 q <- sprintf('[out:json][timeout:60];way["waterway"="river"](%s);out body geom;',paste(bands[[n]],collapse=','))
 writeLines(q,file.path('data/downloads',paste0('rivers_',n,'.overpassql')))
 h <- curl::new_handle(postfields=q,timeout=90)
 message('Downloading ',n,' Italy rivers...')
 result <- curl::curl_fetch_disk('https://overpass-api.de/api/interpreter',target,handle=h)
 if(result$status_code!=200L) stop('Overpass failed with HTTP ',result$status_code,'. Remove the failed response before retrying.')
}
source('scripts/prepare_rivers.R')
