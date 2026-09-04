library(italymapping)
p <- italy_example('sicily')
print(p)
save_italy_map(p,'sicily',output_dir='output/sicily')
