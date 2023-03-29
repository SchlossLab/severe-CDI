source(snakemake@input[["logR"]])
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

prior <- data_processed %>% 
  calc_baseline_precision(outcome_colname = snakemake@wildcards[['outcome']],
                          pos_outcome = 'yes')

ml_results$performance %>%
  mutate(baseline_precision = prior,
         balanced_precision = calc_balanced_precision(Precision, prior),
         aubprc = calc_balanced_precision(prAUC, prior)) %>% 
  add_cols() %>%
  readr::write_csv(snakemake@output[["perf"]])
ml_results$feature_importance %>%
  add_cols() %>%
  readr::write_csv(snakemake@output[["feat"]])
ml_results$test_data %>%
  readr::write_csv(snakemake@output[['test']])
saveRDS(ml_results$trained_model, file = snakemake@output[["model"]])
