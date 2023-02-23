schtools::log_snakemake(quiet = TRUE)
library(tidyverse)
library(here)
devtools::install_github('SchlossLab/schtools', ref="pool-counts-refactor")
library(schtools)


otu_shared_dat <- data.table::fread(snakemake@input[["shared"]])
otu_tax_dat <- read_tax(snakemake@input[["taxonomy"]])
pooled_list <- pool_taxon_counts(otu_shared_dat, otu_tax_dat, snakemake@wildcards[['taxlevel']])
pooled_list$shared %>% write_tsv(snakemake@output[["shared"]])
pooled_list$tax %>% write_tsv(snakemake@output[["taxonomy"]])
