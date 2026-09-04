\name{italy_regions}
\alias{italy_regions}
\title{List Supported Italian Regions}
\description{Return ISTAT codes and Italian and English names for the 20 regions.}
\usage{italy_regions(data_dir = system.file("extdata", package = "italymapping"))}
\arguments{\item{data_dir}{Directory containing the bundled data and region dictionary.}}
\value{A data frame with columns \code{code}, \code{italian}, and \code{english}.}
\examples{italy_regions()}
