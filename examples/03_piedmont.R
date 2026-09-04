library(italymapping)
p <- italy_example('piedmont')
print(p)
save_italy_map(p,'piedmont',output_dir='output/piedmont')
