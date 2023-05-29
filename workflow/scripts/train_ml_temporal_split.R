schtools::log_snakemake()
library(furrr)
#library(mikropml)
devtools::load_all('../mikropml') # TODO remove after debugging finished
library(rsample)
library(tidyverse)
doFuture::registerDoFuture()
future::plan(future::multicore, workers = snakemake@threads)

wildcards <- schtools::get_wildcards_tbl()
data_processed <- readRDS(snakemake@input[["rds"]])$dat_transformed %>% 
  mutate(!!rlang::sym(outcome_colname) := factor(!!rlang::sym(outcome_colname), 
                                                 levels = c('yes','no'))
  )
train_indices <- readRDS(snakemake@input[['train']])
outcome_colname <- snakemake@wildcards[['outcome']]
method <- snakemake@wildcards[["method"]]
seed <- as.numeric(snakemake@wildcards[["seed"]])
metric <- snakemake@wildcards[['metric']]
kfold <- as.numeric(snakemake@params[['kfold']])

set.seed(seed)
ml_results <- run_ml(
  dataset = data_processed,
  method = method,
  outcome_colname = outcome_colname,
  find_feature_importance = FALSE,
  calculate_performance = FALSE,
  kfold = kfold,
  seed = seed,
  training_frac = train_indices,
  perf_metric_name = metric
)

trained_model <- ml_results$trained_model
calc_perf <- function(split) {
  get_performance_tbl(
    trained_model,
    analysis(split),
    outcome_colname = outcome_colname,
    perf_metric_function = caret::multiClassSummary,
    perf_metric_name = metric,
    class_probs = TRUE,
    method = method,
    seed = seed
  ) %>% 
    select(-c(method, seed)) %>% 
    mutate(across(everything(), as.numeric)) %>% 
    pivot_longer(everything(), names_to = 'term', values_to = 'estimate')
}

test_dat <- ml_results$test_data
bootstrap_perf <- bootstraps(test_dat, times = 10000) %>% 
  mutate(perf = future_map(splits, ~ calc_perf(.x))) %>% 
  int_pctl(perf)

bootstrap_perf %>%
  bind_cols(wildcards) %>%
  readr::write_csv(snakemake@output[["perf"]])

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

test_dat %>%
  readr::write_csv(snakemake@output[['test']])

trained_model %>% saveRDS(file = snakemake@output[["model"]])
