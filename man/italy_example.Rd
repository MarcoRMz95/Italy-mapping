\name{italy_example}
\alias{italy_example}
\title{Render a Curated Regional Example}
\description{Return a fully styled map of Veneto, Tuscany, Piedmont, or Sicily. Each preset specifies a suitable extent and English annotations. The Sicily preset focuses on the main island and surrounding coasts, rather than every outlying island.}
\usage{italy_example(name = c("veneto", "tuscany", "piedmont", "sicily"), ...)}
\arguments{
\item{name}{Example identifier.}
\item{...}{Named arguments overriding the preset values passed to \code{plot_italy_map()}.}
}
\value{A ggplot object, ready to print or save.}
\examples{
\dontrun{
p <- italy_example("veneto")
save_italy_map(p, "veneto")
p <- italy_example("sicily", municipalities = FALSE)
}
}
\seealso{\code{\link{plot_italy_map}}}
