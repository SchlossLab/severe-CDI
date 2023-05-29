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
kfold <- as.numeric(snakemake@params[['kfold']])
metric <- snakemake@wildcards[['metric']]
training_frac <- as.numeric(snakemake@wildcards[['trainfrac']])

data_processed <- readRDS(snakemake@input[["rds"]])$dat_transformed 
prior <- data_processed %>% 
  calc_baseline_precision(outcome_colname = outcome_colname,
                          pos_outcome = 'yes')

ml_results <- run_ml(
  dataset = data_processed  %>% 
    mutate(!!rlang::sym(outcome_colname) := factor(!!rlang::sym(outcome_colname), 
                                                   levels = c('yes','no'))
    ),
  method = ml_method,
  outcome_colname = outcome_colname,
  find_feature_importance = FALSE,
  calculate_performance = FALSE,
  kfold = kfold,
  seed = seed,
  training_frac = training_frac,
  perf_metric_name = metric,
  perf_metric_function = caret::multiClassSummary
)

calc_perf_metrics(ml_results$test_data, 
                  ml_results$trained_model, 
                  outcome_colname = outcome_colname, 
                  perf_metric_function = caret::multiClassSummary, 
                  class_probs = TRUE) %>%
  mutate(baseline_precision = prior,
         balanced_precision = if_else(!is.na(Precision), 
                                      calc_balanced_precision(Precision, prior), 
                                      NA),
         aubprc = if_else(!is.na(prAUC), 
                          calc_balanced_precision(prAUC, prior), 
                          NA)) %>% 
  left_join(wildcards) %>%
  write_csv(snakemake@output[["perf"]])

get_feature_importance(ml_results$trained_model, 
                       ml_results$test_data, 
                       outcome_colname = outcome_colname, 
                       perf_metric_function = caret::multiClassSummary, 
                       perf_metric_name = metric, 
                       class_probs = TRUE, 
                       method = ml_method, 
                       seed = seed) %>%
  left_join(wildcards) %>%
  write_csv(snakemake@output[["feat"]])

ml_results$test_data %>%
  write_csv(snakemake@output[['test']])

saveRDS(ml_results$trained_model, file = snakemake@output[["model"]])
