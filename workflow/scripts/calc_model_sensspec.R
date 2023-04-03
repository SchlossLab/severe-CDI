schtools::log_snakemake()
library(here)
library(tidyverse)
source(here('workflow','scripts','calc_balanced_precision.R'))

model <- read_rds(snakemake@input[["model"]])
test_dat <- read_csv(snakemake@input[["test"]])
outcome_colname <- snakemake@params[["outcome_colname"]]
data_processed <- read_rds(snakemake@input[["rds"]])$dat_transformed

calc_balanced_precision_v <- Vectorize(calc_balanced_precision)
prior_baseline <- calc_baseline_precision(data_processed, outcome_colname = outcome_colname, pos_outcome = 'yes')

mikropml::calc_model_sensspec(
  model,
  test_dat,
  outcome_colname
) %>%
  mutate(prior = prior_baseline,
         balanced_precision = calc_balanced_precision_v(precision, prior)) %>%
  bind_cols(schtools::get_wildcards_tbl()) %>%
  write_csv(snakemake@output[["csv"]])
