schtools::log_snakemake()
library(furrr)
library(mikropml)
library(rsample)
library(tidyverse)
doFuture::registerDoFuture()
future::plan(future::multicore, workers = snakemake@threads)

data_processed <- readRDS(snakemake@input[["rds"]])$dat_transformed
train_indices <- readRDS(snakemake@input[['train']])
outcome_colname <- snakemake@wildcards[['outcome']]
method <- snakemake@params[["method"]]
seed <- as.numeric(snakemake@params[["seed"]])
metric <- snakemake@wildcards[['metric']]

ml_results <- run_ml(
  dataset = data_processed,
  method = method,
  outcome_colname = outcome_colname,
  find_feature_importance = TRUE,
  kfold = as.numeric(snakemake@params[['kfold']]),
  seed = seed,
  training_frac = train_indices,
  perf_metric_name = metric
)

calc_perf <- function(split) {
  get_performance_tbl(
    ml_results$trained_model,
    split$data,
    outcome_colname = outcome_colname,
    perf_metric_function = caret::multiClassSummary,
    perf_metric_name = metric,
    class_probs = TRUE,
    method = method,
    seed = seed
  ) %>% 
    select(-c(method, seed)) %>% 
    pivot_longer(everything(), names_to = 'term', values_to = 'estimate')
}

test_dat <- ml_results$test_data
bootstrap_perf <- bootstraps(test_dat, times = 10000) %>% 
  mutate(perf = future_map(splits, ~ calc_perf(.x))) %>% 
  int_pctl(perf)

wildcards <- schtools::get_wildcards_tbl()
bootstrap_perf %>%
  bind_cols(wildcards) %>%
  readr::write_csv(snakemake@output[["perf"]])
ml_results$feature_importance %>%
  full_join(wildcards) %>%
  readr::write_csv(snakemake@output[["feat"]])
test_dat %>%
  readr::write_csv(snakemake@output[['test']])
saveRDS(ml_results$trained_model, file = snakemake@output[["model"]])
