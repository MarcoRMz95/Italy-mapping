library(italymapping)
p <- italy_example('tuscany')
print(p)
save_italy_map(p,'tuscany',output_dir='output/tuscany')
