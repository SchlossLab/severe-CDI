schtools::log_snakemake()
library(here)
library(mikropml)
library(schtools)
library(tidyverse)
source(here('workflow','scripts','calc_balanced_precision.R'))

doFuture::registerDoFuture()
future::plan(future::multicore, workers = snakemake@threads)

wildcards <- schtools::get_wildcards_tbl()
outcome_colname <- snakemake@wildcards[['outcome']]
ml_method <- snakemake@wildcards[["method"]]
seed <- as.numeric(snakemake@wildcards[["seed"]])
data_processed <- readRDS(snakemake@input[["rds"]])$dat_transformed 
prior <- data_processed %>% 
  calc_baseline_precision(outcome_colname = snakemake@wildcards[['outcome']],
                          pos_outcome = 'yes')

ml_results <- run_ml(
  dataset = data_processed  %>% 
    mutate(!!rlang::sym(outcome_colname) := factor(!!rlang::sym(outcome_colname), 
                                                   levels = c('yes','no'))
    ),
  method = ml_method,
  outcome_colname = outcome_colname,
  find_feature_importance = TRUE,
  kfold = as.numeric(snakemake@params[['kfold']]),
  seed = seed,
  training_frac = as.numeric(snakemake@wildcards[['trainfrac']]),
  perf_metric_name = snakemake@wildcards[['metric']],
  perf_metric_function = caret::multiClassSummary
)

ml_results$performance %>%
  mutate(baseline_precision = prior,
         balanced_precision = if_else(!is.na(Precision), 
                                      calc_balanced_precision(Precision, prior), 
                                      NA),
         aubprc = if_else(!is.na(prAUC), 
                          calc_balanced_precision(prAUC, prior), 
                          NA)) %>% 
  left_join(wildcards) %>%
  write_csv(snakemake@output[["perf"]])

ml_results$feature_importance %>%
  left_join(wildcards) %>%
  write_csv(snakemake@output[["feat"]])

ml_results$test_data %>%
  write_csv(snakemake@output[['test']])

saveRDS(ml_results$trained_model, file = snakemake@output[["model"]])
