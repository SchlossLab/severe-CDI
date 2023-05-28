schtools::log_snakemake()
library(here)
library(mikropml)
library(tidyverse)
source(here('workflow','scripts','calc_balanced_precision.R'))
add_cols <- function(dat) {
  dat %>%
    mutate(outcome = snakemake@wildcards[['outcome']],
           taxlevel = snakemake@wildcards[['taxlevel']],
           metric = snakemake@wildcards[['metric']],
           dataset = snakemake@wildcards[['dataset']],
           trainfrac = snakemake@wildcards[['trainfrac']])
}

doFuture::registerDoFuture()
future::plan(future::multicore, workers = snakemake@threads)

outcome_colname <- snakemake@wildcards[['outcome']]
ml_method <- snakemake@params[["method"]]
seed <- as.numeric(snakemake@params[["seed"]])
data_processed <- readRDS(snakemake@input[["rds"]])$dat_transformed 
prior <- data_processed %>% 
  calc_baseline_precision(outcome_colname = outcome_colname,
                          pos_outcome = 'yes')
message(paste('prior:', prior))

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
head(ml_results$performance)
ml_results$performance %>%
  mutate(baseline_precision = prior,
         balanced_precision = if_else(!is.na(Precision), 
                                      calc_balanced_precision(Precision, prior), 
                                      NA),
         aubprc = if_else(!is.na(prAUC), 
                          calc_balanced_precision(prAUC, prior), 
                          NA)) %>% 
  add_cols() %>%
  write_csv(snakemake@output[["perf"]])

ml_results$test_data %>%
  write_csv(snakemake@output[['test']])

saveRDS(ml_results$trained_model, file = snakemake@output[["model"]])

get_feature_importance(ml_results$trained_model,
                       ml_results$test_data %>% as_tibble(),
                       outcome_colname,
                       perf_metric_fn = caret::multiClassSummary,
                       perf_metric_name = "AUC",
                       class_probs = TRUE,
                       method = ml_method,
                       seed = seed) %>%
  add_cols() %>%
  write_csv(snakemake@output[["feat"]])
