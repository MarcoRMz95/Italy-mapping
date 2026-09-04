# Rscript scripts/render_examples.R
library(italymapping)
dir.create('docs/images',recursive=TRUE,showWarnings=FALSE)
for(n in c('veneto','tuscany','piedmont','sicily')) {
  p <- italy_example(n)
  save_italy_map(p,n,output_dir=file.path('output',n))
  file.copy(file.path('output',n,paste0(n,'_preview.png')),
            file.path('docs/images',paste0(n,'.png')),overwrite=TRUE)
  rm(p);gc()
}
capture.output(sessionInfo(),file='docs/sessionInfo.txt')
