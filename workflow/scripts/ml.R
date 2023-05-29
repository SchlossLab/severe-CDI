schtools::log_snakemake()
library(here)
library(mikropml)
library(tidyverse)

doFuture::registerDoFuture()
future::plan(future::multicore, workers = snakemake@threads)

wildcards <- schtools::get_wildcards_tbl()
outcome_colname <- snakemake@wildcards[['outcome']]
ml_method <- snakemake@params[["method"]]
seed <- as.numeric(snakemake@params[["seed"]])
data_processed <- readRDS(snakemake@input[["rds"]])$dat_transformed 

ml_results <- run_ml(
  dataset = data_processed %>% 
    mutate(!!rlang::sym(outcome_colname) := factor(!!rlang::sym(outcome_colname), 
                                                   levels = c('yes','no'))
           ),
  method = ml_method,
  outcome_colname = outcome_colname,
  find_feature_importance = FALSE,
  kfold = as.numeric(snakemake@params[['kfold']]),
  seed = seed,
  training_frac = as.numeric(snakemake@wildcards[['trainfrac']]),
  perf_metric_name = snakemake@wildcards[['metric']],
  perf_metric_function = caret::multiClassSummary
)

get_feature_importance(ml_results$trained_model,
                       ml_results$test_data %>% as_tibble(),
                       outcome_colname,
                       perf_metric_fn = caret::multiClassSummary,
                       perf_metric_name = snakemake@wildcards[['metric']],
                       class_probs = TRUE,
                       method = ml_method,
                       seed = seed) %>%
  left_join(wildcards, by = c("method", "seed")) %>%
  write_csv(snakemake@output[["feat"]])

ml_results$performance %>%
  left_join(wildcards, by = c("method", "seed")) %>%
  write_csv(snakemake@output[["perf"]])

ml_results$test_data %>%
  write_csv(snakemake@output[['test']])

saveRDS(ml_results$trained_model, file = snakemake@output[["model"]])

