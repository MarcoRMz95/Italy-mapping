# Italy mapping -- an installable R package.
# All rendering uses bundled data. No network request is made by this function.

italy_data_dir <- function(data_dir=system.file('extdata',package='italymapping'),
                           cache_dir=getOption('italymapping.cache_dir',file.path(tempdir(),'italymapping'))) {
  required <- c('regions_2023.gpkg','municipalities_2023.gpkg.zip',
                'elevation_italy_30as.tif','land_natural_earth.gpkg','rivers_osm.gpkg')
  missing <- required[!file.exists(file.path(data_dir,required))]
  if(length(missing)) stop('Missing bundled data: ',paste(missing,collapse=', '),
                           '. Reinstall the package or set data_dir.')
  cache <- cache_dir
  dir.create(cache,recursive=TRUE,showWarnings=FALSE)
  archive <- file.path(data_dir,'municipalities_2023.gpkg.zip')
  destination <- file.path(cache,'municipalities_2023.gpkg')
  stamp <- paste(file.info(archive)$size,as.numeric(file.info(archive)$mtime))
  marker <- file.path(cache,'municipalities_archive.txt')
  if(!file.exists(destination) || !file.exists(marker) || !identical(readLines(marker,warn=FALSE),stamp)) {
    listing <- utils::unzip(archive,list=TRUE)
    if(!identical(listing$Name,'municipalities_2023.gpkg')) stop('Unexpected municipality archive contents.')
    utils::unzip(archive,exdir=cache,overwrite=TRUE)
    writeLines(stamp,marker)
  }
  structure(normalizePath(data_dir,winslash='/',mustWork=TRUE),
            municipalities=normalizePath(destination,winslash='/',mustWork=TRUE))
}

italy_regions <- function(data_dir=system.file('extdata',package='italymapping')) {
  dictionary <- utils::read.csv(file.path(data_dir,'region_names.csv'),stringsAsFactors=FALSE)
  dictionary[,c('code','italian','english')]
}

plot_italy_map <- function(
  regions='Veneto', data_dir=system.file('extdata',package='italymapping'),
  bbox=NULL, margin_km=c(west=45,east=42,south=33,north=18),
  municipalities=TRUE, resolution_m=400, crs=NULL,
  title=NULL, subtitle='Relief and hydrography  /  Neighbouring regions and municipal boundaries',
  cities=NULL, region_labels=NULL, river_labels=NULL, extra_labels=NULL,
  green_lowlands=TRUE, show_north=TRUE, show_scale=TRUE
) {
  packages <- c('sf','terra','ggplot2','ragg','ggspatial','scales')
  missing <- packages[!vapply(packages,requireNamespace,logical(1),quietly=TRUE)]
  if(length(missing)) stop('Install required packages: ',paste(missing,collapse=', '))
  stopifnot(length(regions)>0L,length(margin_km)==4L,all(is.finite(margin_km)),
            all(margin_km>=0),length(resolution_m)==1L,is.finite(resolution_m),resolution_m>0,
            length(municipalities)==1L,!is.na(municipalities))
  data_dir <- italy_data_dir(data_dir)
  municipalities_file <- attr(data_dir,'municipalities')
  dictionary <- italy_regions(data_dir)
  norm <- function(x) tolower(trimws(iconv(as.character(x),to='ASCII//TRANSLIT')))
  region_codes <- vapply(regions,function(x) {
    hit <- which(dictionary$code==as.character(x) | norm(dictionary$italian)==norm(x) |
                   norm(dictionary$english)==norm(x))
    if(length(hit)!=1L) stop('Unknown or ambiguous region: ',x,
      '. Available regions: ',paste(dictionary$english,collapse=', '))
    dictionary$code[hit]
  },integer(1))
  region_codes <- unique(region_codes)
  all_regions <- sf::st_read(file.path(data_dir,'regions_2023.gpkg'),quiet=TRUE)
  selected <- all_regions[all_regions$COD_REG %in% region_codes,]
  stopifnot(nrow(selected)==length(region_codes))
  ll_box <- sf::st_bbox(sf::st_transform(selected,4326))
  if(is.null(crs)) crs <- if(mean(ll_box[c('xmin','xmax')])<12) 32632 else 32633
  target_crs <- sf::st_crs(crs)
  if(is.na(target_crs) || isTRUE(target_crs$IsGeographic)) stop('Use a projected CRS in metres, e.g. EPSG:32632.')
  if(!is.null(target_crs$units_gdal) && !target_crs$units_gdal %in% c('metre','meter','metres','meters','m'))
    stop('The target CRS must use metres.')
  all_regions <- sf::st_transform(all_regions,target_crs)
  selected <- all_regions[all_regions$COD_REG %in% region_codes,]
  selected_union <- sf::st_union(sf::st_geometry(selected))
  if(is.null(bbox)) {
    bb <- sf::st_bbox(selected)
    m <- unname(margin_km)*1000
    bb <- sf::st_bbox(c(xmin=unname(bb['xmin'])-m[1],ymin=unname(bb['ymin'])-m[3],
                        xmax=unname(bb['xmax'])+m[2],ymax=unname(bb['ymax'])+m[4]),crs=target_crs)
  } else {
    if(length(bbox)!=4L || any(!is.finite(bbox))) stop('bbox must contain xmin, ymin, xmax, ymax in WGS84 degrees.')
    if(is.null(names(bbox))) names(bbox) <- c('xmin','ymin','xmax','ymax')
    if(!all(c('xmin','ymin','xmax','ymax') %in% names(bbox))) stop('Invalid bbox names.')
    bbox <- bbox[c('xmin','ymin','xmax','ymax')]
    if(bbox[1]>=bbox[3] || bbox[2]>=bbox[4]) stop('bbox minimum must be smaller than maximum.')
    bb <- sf::st_bbox(sf::st_transform(sf::st_as_sfc(sf::st_bbox(bbox,crs=4326)),target_crs))
    if(!lengths(sf::st_intersects(sf::st_as_sfc(bb),selected_union))) stop('The map extent does not intersect the selected regions.')
  }
  crop <- function(x) suppressWarnings(sf::st_crop(x,bb))
  read_local <- function(path) {
    x <- sf::st_read(file.path(data_dir,path),quiet=TRUE)
    if(is.na(sf::st_crs(x))) stop('Missing CRS: ',path)
    crop(sf::st_transform(x,target_crs))
  }
  visible_regions <- crop(all_regions)
  land <- read_local('land_natural_earth.gpkg')
  land_geom <- sf::st_union(sf::st_geometry(land))
  water <- sf::st_difference(sf::st_as_sfc(bb),land_geom)
  rivers <- read_local('rivers_osm.gpkg')
  river_lines <- if(nrow(rivers)) sf::st_line_merge(sf::st_union(sf::st_geometry(rivers))) else NULL
  municipal_edges <- NULL
  muni <- NULL
  if(municipalities) {
    # Attribute filter is executed by GDAL, so only selected municipalities load.
    query <- sprintf('SELECT * FROM municipalities WHERE COD_REG IN (%s)',paste(region_codes,collapse=','))
    muni <- sf::st_read(municipalities_file,query=query,quiet=TRUE)
    stopifnot(nrow(muni)>0L,!anyDuplicated(muni$PRO_COM_T))
    muni <- crop(sf::st_transform(muni,target_crs))
    municipal_edges <- sf::st_intersection(sf::st_union(sf::st_boundary(sf::st_geometry(muni))),land_geom)
  }
  regional_edges <- sf::st_union(sf::st_boundary(sf::st_geometry(visible_regions)))
  message('Rendering ',paste(dictionary$english[dictionary$code %in% region_codes],collapse=' + '),'...')
  dem <- terra::rast(file.path(data_dir,'elevation_italy_30as.tif'))
  template <- terra::rast(xmin=bb['xmin'],xmax=bb['xmax'],ymin=bb['ymin'],ymax=bb['ymax'],
                          resolution=resolution_m,crs=target_crs$wkt)
  if(terra::ncell(template)>5e6) stop('Map raster exceeds 5 million cells; increase resolution_m.')
  elev <- terra::mask(terra::project(dem,template,method='bilinear'),terra::vect(land_geom))
  slope <- terra::terrain(elev,'slope',unit='radians',neighbors=8)
  aspect <- terra::terrain(elev,'aspect',unit='radians',neighbors=8)
  shade <- (terra::shade(slope,aspect,angle=40,direction=315,normalize=TRUE)*.65 +
              terra::shade(slope,aspect,angle=50,direction=45,normalize=TRUE)*.35)/255
  z <- terra::values(elev,mat=FALSE)
  sh <- terra::values(shade,mat=FALSE);sh[!is.finite(sh)] <- .7
  breaks <- c(-70,0,100,300,600,1000,1600,2200,3000,4000,4600)
  colors <- c('#acd19a','#acd19a','#b6d49f','#d0d5a3','#e4d5aa',
              '#d7c297','#c6aa88','#bfa995','#c9beb0','#e7e1d6','#f7f4ee')
  if(!green_lowlands) colors[1:4] <- c('#d3e2c2','#d3e2c2','#cfdfb4','#deddb2')
  positions <- stats::approx(breaks,seq(0,1,length.out=length(breaks)),
                             xout=pmax(-70,pmin(4600,z)),rule=2)$y
  positions[is.na(positions)] <- 0
  rgb <- grDevices::colorRamp(colors,space='Lab')(positions)/255
  rgb[] <- pmin(1,pmax(0,rgb*(.77+.28*sh)))
  pixels <- grDevices::rgb(rgb[,1],rgb[,2],rgb[,3],alpha=ifelse(is.na(z),0,1))
  relief <- grDevices::as.raster(matrix(pixels,nrow=terra::nrow(elev),byrow=TRUE))
  label_sf <- function(x) {
    if(is.null(x) || !nrow(x)) return(NULL)
    if(!all(c('label','lon','lat') %in% names(x))) stop('Labels require label, lon and lat columns.')
    if(any(!is.finite(x$lon)) || any(!is.finite(x$lat))) stop('Label coordinates must be finite.')
    x <- sf::st_transform(sf::st_as_sf(x,coords=c('lon','lat'),crs=4326),target_crs)
    x[lengths(sf::st_intersects(x,sf::st_as_sfc(bb)))>0,]
  }
  if(is.null(cities)) {
    cities <- utils::read.csv(file.path(data_dir,'cities.csv'),stringsAsFactors=FALSE)
    cities <- cities[cities$region_code %in% region_codes,]
  }
  city_points <- label_sf(cities)
  if(is.null(region_labels)) {
    lbl <- visible_regions[!visible_regions$COD_REG %in% region_codes,]
    lbl$label <- toupper(dictionary$english[match(lbl$COD_REG,dictionary$code)])
    area <- as.numeric(sf::st_area(lbl))
    lbl <- lbl[area>1e9,]
    region_points <- suppressWarnings(sf::st_point_on_surface(lbl))
  } else region_points <- label_sf(region_labels)
  river_points <- label_sf(river_labels)
  if(!is.null(river_points) && nrow(river_points)) {
    river_name <- function(x) tolower(trimws(gsub('^(fiume|torrente|rio|river) +','',norm(x))))
    for(i in seq_len(nrow(river_points))) {
      candidates <- which(river_name(rivers$name)==river_name(river_points$label[i]) |
                            river_name(rivers$name_en)==river_name(river_points$label[i]))
      if(!length(candidates)) stop('No river geometry for label ',river_points$label[i])
      nearest <- sf::st_nearest_points(sf::st_geometry(river_points[i,]),sf::st_union(sf::st_geometry(rivers[candidates,])))
      xy <- utils::tail(sf::st_coordinates(nearest)[,1:2,drop=FALSE],1)
      sf::st_geometry(river_points)[[i]] <- sf::st_point(as.numeric(xy))
    }
  }
  extra_points <- label_sf(extra_labels)
  if(is.null(title)) title <- toupper(paste(dictionary$english[dictionary$code %in% region_codes],collapse=' + '))
  sea <- '#d5e8ed'
  p <- ggplot2::ggplot() +
    ggplot2::geom_sf(data=land_geom,fill='#e8e5d8',color=NA) +
    ggplot2::annotation_raster(relief,xmin=terra::xmin(elev),xmax=terra::xmax(elev),
                                ymin=terra::ymin(elev),ymax=terra::ymax(elev),interpolate=TRUE) +
    ggplot2::geom_sf(data=water,fill=sea,color=NA) +
    ggplot2::geom_sf(data=land_geom,fill=NA,color='#86a4a5',linewidth=.16)
  if(!is.null(municipal_edges)) p <- p + ggplot2::geom_sf(data=municipal_edges,color='#555c52',linewidth=.12,alpha=.65)
  p <- p + ggplot2::geom_sf(data=regional_edges,color='#676d5c',linewidth=.47) +
    ggplot2::geom_sf(data=selected_union,fill=NA,color='#fff9ed',linewidth=1.5) +
    ggplot2::geom_sf(data=selected_union,fill=NA,color='#58643d',linewidth=.8)
  if(!is.null(river_lines)) p <- p + ggplot2::geom_sf(data=river_lines,color='#4085a2',linewidth=.23,lineend='round',linejoin='round')
  if(!is.null(region_points) && nrow(region_points)) p <- p +
    ggplot2::geom_sf_text(data=region_points,ggplot2::aes(label=label),color='#56665f',size=3.3,fontface='italic',lineheight=1.1)
  if(!is.null(extra_points) && nrow(extra_points)) {
    main_label <- grepl('^[A-Z]( [A-Z]){3,}$',extra_points$label)
    p <- p + ggplot2::geom_sf_text(data=extra_points[!main_label,],ggplot2::aes(label=label),color='#56665f',size=3.5,fontface='italic') +
      ggplot2::geom_sf_text(data=extra_points[main_label,],ggplot2::aes(label=label),color='#485340',size=5,fontface='bold')
  }
  if(!is.null(river_points) && nrow(river_points)) p <- p +
    ggplot2::geom_sf_label(data=river_points,ggplot2::aes(label=label),size=3,color='#236785',fill='#f1f3e8',
                          linewidth=0,fontface='italic',label.padding=grid::unit(.07,'lines'),nudge_y=1800)
  if(!is.null(city_points) && nrow(city_points)) p <- p +
    ggplot2::geom_sf(data=city_points,shape=21,size=2.2,stroke=.45,fill='#fffdf4',color='#263f45') +
    ggplot2::geom_sf_label(data=city_points,ggplot2::aes(label=label),size=3.4,nudge_y=-4400,linewidth=0,
                          fill='#f6f4e8',color='#24383b',label.padding=grid::unit(.1,'lines'))
  p <- p + ggplot2::geom_point(data=data.frame(x=NA_real_,y=NA_real_,z=0),ggplot2::aes(x=x,y=y,fill=z),shape=22,na.rm=TRUE) +
    ggplot2::scale_fill_gradientn(name='Elevation (m)',colors=colors,
      values=scales::rescale(breaks,from=c(-70,4600)),limits=c(-70,4600),breaks=c(0,500,1000,2000,3000,4000),
      guide=ggplot2::guide_colorbar(barwidth=grid::unit(90,'mm'),barheight=grid::unit(3,'mm'),title.position='top'))
  if(show_scale) p <- p + ggspatial::annotation_scale(location='bl',width_hint=.18,pad_x=grid::unit(5,'mm'),pad_y=grid::unit(5,'mm'),text_cex=.8)
  if(show_north) p <- p + ggspatial::annotation_north_arrow(location='tr',which_north='true',height=grid::unit(10,'mm'),
                                      width=grid::unit(9,'mm'),style=ggspatial::north_arrow_minimal(text_size=9))
  crs_label <- if(!is.na(target_crs$epsg)) paste0('EPSG:',target_crs$epsg) else target_crs$Name
  p <- p + ggplot2::coord_sf(crs=target_crs,default_crs=target_crs,xlim=bb[c('xmin','xmax')],ylim=bb[c('ymin','ymax')],expand=FALSE) +
    ggplot2::labs(title=title,subtitle=subtitle,
      caption=paste0('Boundaries: ISTAT, 01 Jan 2023  |  Rivers: OpenStreetMap contributors  |  Coastline: Natural Earth 1:10m\n',
         'Elevation: supplied ITA_alt, native 30-arc-second grid  |  ',crs_label,'\n',
         'Municipal boundaries: 2023. Cream areas: missing elevation. Visual interpolation adds no new terrain detail.')) +
    ggplot2::theme_void(base_family='sans',base_size=11) +
    ggplot2::theme(panel.background=ggplot2::element_rect(fill=sea,color=NA),
      panel.border=ggplot2::element_rect(fill=NA,color='#93a2a0',linewidth=.5),
      plot.background=ggplot2::element_rect(fill='#fcfbf7',color=NA),
      plot.title=ggplot2::element_text(size=31,face='bold',color='#283f42',margin=ggplot2::margin(b=5)),
      plot.subtitle=ggplot2::element_text(size=12,color='#617377',margin=ggplot2::margin(b=16)),
      plot.caption=ggplot2::element_text(size=8,color='#677477',hjust=0,lineheight=1.4,margin=ggplot2::margin(t=12)),
      plot.margin=ggplot2::margin(20,24,16,24),legend.position='bottom',legend.justification='left',
      legend.text=ggplot2::element_text(size=9),legend.title=ggplot2::element_text(size=9),legend.margin=ggplot2::margin(3,0,0,0))
  attr(p,'italy_mapping') <- list(bbox=bb,crs=crs_label,regions=region_codes,
     municipalities=if(is.null(muni)) 0L else nrow(muni),rivers=nrow(rivers),
     native_dem_resolution=terra::res(dem),render_resolution_m=resolution_m,
     elevation_range=range(z,na.rm=TRUE))
  p
}

save_italy_map <- function(plot,name,output_dir='output',dpi=400,width=13,tiff=TRUE,preview=TRUE) {
  info <- attr(plot,'italy_mapping')
  if(is.null(info)) stop('Expected a plot returned by plot_italy_map().')
  if(length(name)!=1L || !grepl('^[A-Za-z0-9_-]+$',name)) stop('Use a simple filename stem for name.')
  stopifnot(length(dpi)==1L,is.finite(dpi),dpi>0,length(width)==1L,is.finite(width),width>0)
  dir.create(output_dir,recursive=TRUE,showWarnings=FALSE)
  bb <- info$bbox
  height <- width*as.numeric((bb['ymax']-bb['ymin'])/(bb['xmax']-bb['xmin']))+2.1
  ggplot2::ggsave(file.path(output_dir,paste0(name,'.png')),plot,width=width,height=height,dpi=dpi,device=ragg::agg_png)
  if(tiff) ggplot2::ggsave(file.path(output_dir,paste0(name,'.tiff')),plot,width=width,height=height,dpi=dpi,device=ragg::agg_tiff,compression='lzw')
  if(preview) ggplot2::ggsave(file.path(output_dir,paste0(name,'_preview.png')),plot,width=width,height=height,dpi=120,device=ragg::agg_png)
  utils::capture.output(info,file=file.path(output_dir,paste0(name,'_metadata.txt')))
  invisible(normalizePath(file.path(output_dir,paste0(name,'.png')),winslash='/'))
}
