library(tidyverse)
library(here)
devtools::install_github('SchlossLab/schtools', ref="pool-counts-refactor")
library(schtools)

log_snakemake(quiet = TRUE)

otu_shared_dat <- data.table::fread(snakemake@input[["shared"]])
otu_tax_dat <- read_tax(snakemake@input[["taxonomy"]])
genus_list <- pool_taxon_counts(otu_shared_dat, otu_tax_dat, "genus")
genus_list$shared %>% write_tsv(snakemake@output[["shared"]])
genus_list$tax %>% write_tsv(snakemake@output[["taxonomy"]])

