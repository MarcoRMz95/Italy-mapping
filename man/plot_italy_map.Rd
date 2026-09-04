\name{plot_italy_map}
\alias{plot_italy_map}
\title{Draw a Relief Map of Italian Regions}
\description{Create an offline map with shaded elevation, a single detailed river network, regional boundaries and optional municipal boundaries. Only the elevation legend is displayed.}
\usage{
plot_italy_map(
  regions = "Veneto", data_dir = system.file("extdata", package = "italymapping"),
  bbox = NULL, margin_km = c(west = 45, east = 42, south = 33, north = 18),
  municipalities = TRUE, resolution_m = 400, crs = NULL,
  title = NULL,
  subtitle = "Relief and hydrography  /  Neighbouring regions and municipal boundaries",
  cities = NULL, region_labels = NULL, river_labels = NULL, extra_labels = NULL,
  green_lowlands = TRUE, show_north = TRUE, show_scale = TRUE
)
}
\arguments{
\item{regions}{One or more region names in Italian or English, or ISTAT region codes. See \code{italy_regions()}.}
\item{data_dir}{Directory containing the bundled GIS files. Defaults to the installed package data.}
\item{bbox}{Optional named vector \code{c(xmin, ymin, xmax, ymax)} in WGS84 degrees. Overrides automatic margins.}
\item{margin_km}{Four nonnegative margins in kilometres, ordered west, east, south, north.}
\item{municipalities}{Whether to draw municipal outlines for the selected regions.}
\item{resolution_m}{Projected grid spacing in metres. Interpolation does not improve the native 30-arc-second information content.}
\item{crs}{Projected coordinate reference system using metres. Defaults to UTM zone 32N or 33N according to the selected regions' longitude.}
\item{title, subtitle}{Map title and subtitle.}
\item{cities}{Data frame with \code{label}, \code{lon}, \code{lat} columns. NULL loads the curated city labels for the four examples; other regions have no default city labels. An empty data frame suppresses them.}
\item{region_labels}{Data frame with \code{label}, \code{lon}, \code{lat}. NULL automatically labels neighbouring Italian regions.}
\item{river_labels}{Data frame with \code{label}, \code{lon}, \code{lat}. Locations are snapped to the named river. NULL omits river labels.}
\item{extra_labels}{Additional English labels with \code{label}, \code{lon}, \code{lat}. Widely spaced uppercase titles are drawn in bold.}
\item{green_lowlands}{Use the green low-elevation palette. FALSE uses the earlier muted palette.}
\item{show_north, show_scale}{Whether to include a north arrow and scale bar.}
}
\value{A ggplot object with an \code{italy_mapping} metadata attribute.}
\details{Municipal data are unpacked into a session cache. Set \code{options(italymapping.cache_dir = "/a/writable/cache")} to reuse a cache across sessions. Coastlines define sea and coastal lagoons independently of elevation. Land below sea level is not automatically classified as water. The Natural Earth land mask does not delimit every inland lake. Boundaries refer to the supplied 2023 snapshot and are statistical boundaries. Rivers are an OpenStreetMap snapshot; no artificial links are inserted across disconnected branches.}
\examples{
italy_regions()
\dontrun{
p <- plot_italy_map("Tuscany")
print(p)
save_italy_map(p, "tuscany")
p <- plot_italy_map(c("Veneto", "Friuli Venezia Giulia"), municipalities = FALSE)
}
}
\seealso{\code{\link{italy_example}}, \code{\link{save_italy_map}}}
