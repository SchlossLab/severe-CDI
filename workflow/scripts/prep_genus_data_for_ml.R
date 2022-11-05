library(tidyverse)
library(here)
library(schtools)

log_snakemake(quiet = TRUE)

shared <- data.table::fread(snakemake@input[["shared"]]) %>% 
  rename(sample_id = Group)
full_metadata <- read_csv(snakemake@input[["full_metadata"]]) %>% 
    inner_join(shared)
int_metadata <- read_csv(snakemake@input[["int_metadata"]]) %>% 
    inner_join(shared)

full_metadata %>% select("idsa", starts_with("Otu")) %>% write_csv('data/process/idsa_full_genus.csv')
int_metadata %>% select("idsa", starts_with("Otu")) %>% write_csv('data/process/idsa_int_genus.csv')
full_metadata %>% select("allcause", starts_with("Otu")) %>% write_csv('data/process/allcause_full_genus.csv')
int_metadata %>% select("allcause", starts_with("Otu")) %>% write_csv('data/process/allcause_int_genus.csv')
full_metadata %>% select("attrib", starts_with("Otu")) %>% write_csv('data/process/attrib_full_genus.csv')
int_metadata %>% select("attrib", starts_with("Otu")) %>% write_csv('data/process/attrib_int_genus.csv')