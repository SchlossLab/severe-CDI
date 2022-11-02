library(tidyverse)
library(here)
library(schtools)

log_snakemake(quiet = TRUE)

otu_shared_dat <- read_tsv(snakemake@input[["shared"]])
otu_tax_dat <- read_tax(snakemake@input[["taxonomy"]])
taxon_level <- "genus"
genus_list <- pool_taxon_counts(otu_shared_dat, otu_tax_dat, taxon_level)
genus_list$shared %>% write_tsv(snakemake@output[["shared"]])
genus_list$tax %>% write_tsv(snakemake@output[["taxonomy"]])