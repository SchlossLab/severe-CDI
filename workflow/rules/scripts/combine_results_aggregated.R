source("workflow/rules/scripts/log_smk.R")
library(glue)
library(here)
library(tidyverse)

result_type <- snakemake@wildcards[["type"]]
outcomes <- snakemake@params[['outcomes']]

outcomes %>%
  map_dfr(function(x) { 
    here('results', glue('predict_{x}'), glue('{result_type}_results.csv')) %>% 
      read_csv() %>% 
      mutate(outcome = x) }) %>%
  write_csv(snakemake@output[["csv"]])