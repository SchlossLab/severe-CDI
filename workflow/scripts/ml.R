source(snakemake@input[["logR"]])
add_cols <- function(dat) {
  dat %>%
    mutate(outcome = snakemake@wildcards[['outcome_colname']],
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
  outcome_colname = snakemake@wildcards[['outcome_colname']],
  find_feature_importance = TRUE,
  kfold = as.numeric(snakemake@params[['kfold']]),
  seed = as.numeric(snakemake@params[["seed"]]),
  training_frac = as.numeric(snakemake@wildcards[['trainfrac']])
)

ml_results$performance %>%
  add_cols() %>%
  readr::write_csv(snakemake@output[["perf"]])
ml_results$feature_importance %>%
  add_cols() %>%
  readr::write_csv(snakemake@output[["feat"]])
ml_results$test_data %>%
  add_cols() %>%
  readr::write_csv(snakemake@output[['test']])
saveRDS(ml_results$trained_model, file = snakemake@output[["model"]])
