schtools::log_snakemake()
library(tidyverse)
doFuture::registerDoFuture()
future::plan(future::multicore, workers = snakemake@threads)

data_processed <- readRDS(snakemake@input[["rds"]])$dat_transformed
ml_results <- mikropml::run_ml(
  dataset = data_processed,
  method = snakemake@params[["method"]],
  outcome_colname = snakemake@wildcards[['outcome']],
  find_feature_importance = TRUE,
  kfold = as.numeric(snakemake@params[['kfold']]),
  seed = as.numeric(snakemake@params[["seed"]]),
  training_frac = as.numeric(snakemake@wildcards[['trainfrac']]),
  perf_metric_name = snakemake@wildcards[['metric']]
)
wildcards <- schtools::get_wildcards_tbl()
ml_results$performance %>%
  full_join(wildcards) %>%
  readr::write_csv(snakemake@output[["perf"]])
ml_results$feature_importance %>%
  full_join(wildcards) %>%
  readr::write_csv(snakemake@output[["feat"]])
ml_results$test_data %>%
  full_join(wildcards) %>%
  readr::write_csv(snakemake@output[['test']])
saveRDS(ml_results$trained_model, file = snakemake@output[["model"]])
