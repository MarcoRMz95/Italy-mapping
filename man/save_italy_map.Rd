\name{save_italy_map}
\alias{save_italy_map}
\title{Export a Map for Screen and Print}
\description{Write a high-resolution PNG, optional lossless TIFF, optional lightweight PNG preview, and a text metadata file.}
\usage{save_italy_map(plot, name, output_dir = "output", dpi = 400, width = 13,
  tiff = TRUE, preview = TRUE)}
\arguments{
\item{plot}{A plot returned by \code{plot_italy_map()} or \code{italy_example()}.}
\item{name}{Filename stem containing letters, numbers, underscores, or hyphens.}
\item{output_dir}{Writable directory for outputs. Created if needed.}
\item{dpi}{Resolution of the full-size PNG and TIFF.}
\item{width}{Width in inches; height follows the map aspect ratio.}
\item{tiff}{Write an LZW-compressed TIFF.}
\item{preview}{Write a preview at 120 dpi.}
}
\value{Invisibly, the absolute path to the full-size PNG.}
\examples{\dontrun{save_italy_map(italy_example("veneto"), "veneto")}}
