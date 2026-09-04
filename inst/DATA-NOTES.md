# Data notes: sources, dates and links

The MIT software license applies to the R code and original package documentation.
It does **not** replace the terms of the following independent GIS datasets.

## ISTAT statistical administrative boundaries

`regions_2023.gpkg` and `municipalities_2023.gpkg.zip` are conversions of the
author-supplied ISTAT `Limiti01012023` snapshot, retaining the original geometry
detail and identifiers: 20 regions, 7,901 municipalities. Reference date:
1 January 2023. These are statistical boundaries, not cadastral survey data.

Source: https://www.istat.it/notizia/confini-delle-unita-amministrative-a-fini-statistici-al-1-gennaio-2018-2/

The national open-data catalogue describes the administrative-boundaries dataset
as CC BY 4.0: https://www.dati.gov.it/node/view-dataset/dataset?id=3f28b164-63b8-478b-8361-1e7f61b1f354

Attribution: Istat, statistical administrative boundaries, 2023 snapshot.
The supplied files are a historical snapshot; they are not claimed to be identical
to any subsequently revised 2023 download or to current boundaries.

## OpenStreetMap rivers

`rivers_osm.gpkg` is an extract of ways tagged `waterway=river` from OpenStreetMap,
queried through the public Overpass services. See `extdata/river_snapshots.csv`
for response timestamps. Shared ways from overlapping query windows are
deduplicated by OSM way ID. The database retains original geometry and identifiers.

Attribution: OpenStreetMap contributors. Database license: Open Database License
1.0 (ODbL). https://www.openstreetmap.org/copyright

## Natural Earth physical land

`land_natural_earth.gpkg` is a cropped, unioned land mask derived from the
Natural Earth 1:10m country polygons distributed with `rnaturalearthhires`.
Natural Earth data are public domain. https://www.naturalearthdata.com/about/terms-of-use/

This coastline includes coastal lagoons at a generalised regional-map scale.
It is not a high-resolution urban coastline and does not delineate all inland lakes.

## Author-supplied elevation raster: provenance not established

`elevation_italy_30as.tif` is a lossless format conversion of the supplied
`ITA_alt.grd/.gri/.vrt`: 1,416 rows, 1,452 columns, WGS84, 30 arc-seconds,
metres, source NoData -9999. The legacy header was created in 2011, which is
not necessarily the observation date. The header does not establish the original
provider or a redistribution license. It must not be attributed to a specific
DEM product solely from its filename.

This is the elevation file supplied for the original maps. Its original provider
and terms are not established by the available metadata. The MIT code license
does not relicense it. A custom `data_dir` can supply a replacement raster with
the same filename.

## Curated English labels

`region_names.csv` and `cities.csv` contain curated names and approximate label
locations, authored for this package by Marco Aurelio Ramirez Mauricio, 2026.
They are included under the software's MIT license. The city table is intended
for the four examples and is not a complete national gazetteer.
