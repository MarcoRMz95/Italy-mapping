library(italymapping)
p <- italy_example('veneto')
print(p)
save_italy_map(p,'veneto',output_dir='output/veneto')
