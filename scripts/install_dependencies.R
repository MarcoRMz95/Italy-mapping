# Run from the repository root: Rscript scripts/install_dependencies.R
packages <- c('sf', 'terra', 'ggplot2', 'ragg', 'ggspatial', 'scales')
missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly=TRUE)]
if(length(missing)) install.packages(missing, repos='https://cloud.r-project.org')
message('All mapping dependencies are available.')
