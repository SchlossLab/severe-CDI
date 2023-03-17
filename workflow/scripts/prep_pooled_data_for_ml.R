library(dtplyr)
library(tidyverse)
library(here)
library(schtools)

log_snakemake(quiet = TRUE)

message('Reading shared file')
shared <- data.table::fread(snakemake@input[["shared"]]) %>% 
  rename(sample_id = Group)
message('Reading metadata and joining with shared file')
read_csv(snakemake@input[["metadata"]]) %>% 
  lazy_dt() %>% 
  inner_join(shared) %>% 
  select(snakemake@wildcards[['outcome']], starts_with("Otu"), starts_with("ASV")) %>% 
  as_tibble() %>% 
  write_csv(snakemake@output[['csv']])
