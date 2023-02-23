library(tidyverse)
library(here)
library(schtools)

log_snakemake(quiet = TRUE)

shared <- data.table::fread(snakemake@input[["shared"]]) %>% 
  rename(sample_id = Group)
read_csv(snakemake@input[["metadata"]]) %>% 
  inner_join(shared) %>% 
  select(snakemake@wildcards[['outcome']], starts_with("Otu")) %>% 
  write_csv(snakemake@output[['csv']])