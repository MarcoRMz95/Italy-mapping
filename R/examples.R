# Reusable regional presets. Coordinates are approximate label positions;
# river labels are snapped to the actual bundled river geometry.
italy_example <- function(name=c('veneto','tuscany','piedmont','sicily'), ...) {
  name <- match.arg(name)
  labels <- function(label,lon,lat) data.frame(label=label,lon=lon,lat=lat,stringsAsFactors=FALSE)
  common <- switch(name,
    veneto=list(regions='Veneto',crs=32632,
      region_labels=labels(c('LOMBARDY','TRENTINO-SOUTH TYROL','FRIULI VENEZIA\nGIULIA','EMILIA-ROMAGNA','AUSTRIA'),
                            c(10.20,11.15,13.16,11.42,12.50),c(45.67,46.56,46.12,44.62,46.79)),
      extra_labels=labels(c('V E N E T O','ADRIATIC SEA'),c(11.83,13.00),c(45.87,45.02)),
      river_labels=labels(c('Po','Adige','Piave','Brenta','Tagliamento'),
                           c(11.55,11.95,12.40,11.71,12.95),c(44.97,45.18,45.82,45.71,45.89))),
    tuscany=list(regions='Tuscany',crs=32632,margin_km=c(25,35,25,25),
      extra_labels=labels(c('T U S C A N Y','TYRRHENIAN SEA'),c(11.45,9.95),c(43.0,42.45)),
      river_labels=labels(c('Arno','Ombrone','Serchio'),c(10.85,11.30,10.45),c(43.70,42.85,43.95))),
    piedmont=list(regions='Piedmont',crs=32632,
      margin_km=c(west=0,east=35,south=20,north=20),
      extra_labels=labels(c('P I E D M O N T','FRANCE','SWITZERLAND'),c(7.85,6.85,8.25),c(44.57,44.00,46.36)),
      river_labels=labels(c('Po','Tanaro','Ticino'),c(7.90,8.15,8.75),c(45.12,44.78,45.60))),
    sicily=list(regions='Sicily',crs=32633,
      region_labels=labels(character(),numeric(),numeric()),
      bbox=c(xmin=12.0,ymin=36.45,xmax=16.00,ymax=38.80),
      subtitle='Main island and surrounding coasts  /  Relief, rivers and municipal boundaries',
      extra_labels=labels(c('S I C I L Y','TYRRHENIAN SEA','IONIAN SEA','STRAIT OF SICILY'),
                            c(14.0,13.75,15.55,12.90),c(37.50,38.55,37.20,36.75))))
  overrides <- list(...)
  if(length(overrides) && (is.null(names(overrides)) || any(!nzchar(names(overrides))))) stop('Use named overrides in ...')
  for(n in names(overrides)) common[n] <- overrides[n]
  do.call(plot_italy_map,common)
}
