# Add your own longitude/latitude locations to the Veneto map.
# These are illustrative coordinates, not actual monitoring stations.
library(italymapping)
library(sf)
library(ggplot2)

# Run from the repository root, or replace this path with your own CSV path.
# Edit the CSV to choose each location's name and coordinates.
csv_file <- "examples/custom_locations.csv"
locations <- read.csv(csv_file, stringsAsFactors = FALSE, fileEncoding = "UTF-8")
# For Excel CSV files using semicolons and decimal commas, use read.csv2().
stopifnot(
  all(c("label", "longitude", "latitude") %in% names(locations)),
  is.numeric(locations$longitude), is.numeric(locations$latitude),
  all(is.finite(locations$longitude)), all(is.finite(locations$latitude)),
  all(abs(locations$longitude) <= 180), all(abs(locations$latitude) <= 90)
)

# WGS84 decimal degrees: longitude FIRST, latitude SECOND.
# geom_sf transforms these coordinates into the map's projected CRS.
points <- st_as_sf(locations, coords = c("longitude", "latitude"),
                   crs = 4326, remove = FALSE)

# Suppress the preset city markers to give the custom locations more space.
empty_cities <- data.frame(label = character(), lon = numeric(), lat = numeric())
base_map <- italy_example("veneto", cities = empty_cities,
                          title = "VENETO - CUSTOM LOCATIONS")
map_with_points <- base_map +
  geom_sf(data = points, inherit.aes = FALSE, shape = 21,
          size = 3.4, stroke = 0.7, fill = "#c84435", color = "white",
          show.legend = FALSE) +
  geom_sf_label(data = points, aes(label = label), inherit.aes = FALSE,
                nudge_y = 4500, size = 3.3, color = "#842d25",
                fill = "#fffaf2", linewidth = 0, show.legend = FALSE) +
  base_map$coordinates

# Keep export metadata when extending the returned ggplot.
attr(map_with_points, "italy_mapping") <- attr(base_map, "italy_mapping")
print(map_with_points)
save_italy_map(map_with_points, "veneto_custom_locations",
               output_dir = "output/custom_locations")

# Replace the four coordinates with your locations. Points outside the map's
# frame are clipped; use plot_italy_map(..., bbox = ...) for a different extent.
# nudge_y is in projected map units (metres here), not latitude degrees.
