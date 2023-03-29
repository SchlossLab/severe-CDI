schtools::log_snakemake()
library(tidyverse)

model <- read_rds(snakemake@input[["model"]])
test_dat <- read_csv(snakemake@input[["test"]])
outcome_colname <- snakemake@params[["outcome_colname"]]
data_processed <- read_rds(snakemake@input[["rds"]])$dat_transformed

prior <- data_processed %>%
  calc_baseline_precision(outcome_colname = outcome_colname,
                          pos_outcome = 'yes')

mikropml::calc_model_sensspec(
  model,
  test_dat,
  outcome_colname
) %>%
  mutate(balanced_precision = calc_balanced_precision(precision, prior)) %>%
  bind_cols(schtools::get_wildcards_tbl()) %>%
  write_csv(snakemake@output[["csv"]])
