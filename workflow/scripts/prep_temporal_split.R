schtools::log_snakemake()
library(tidyverse)
metadat <- snakemake@input[['metadat']]
train_frac <- as.numeric(snakemake@wildcards[['train_frac']])

train_indices <- metadat %>% 
  slice_min(order_by = collection_date, prop = train_frac) %>%
  mutate(rn = row_number()) %>% 
  pull(rn)

train_indices %>% write_rds(snakemake@output[['rds']])
