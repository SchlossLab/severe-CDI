schtools::log_snakemake()
library(here)
library(mikropml)
library(tidyverse)
source(here('workflow','scripts','calc_balanced_precision.R'))

model <- read_rds(snakemake@input[["model"]])
test_dat <- read_csv(snakemake@input[["test"]])
outcome_colname <- snakemake@params[["outcome_colname"]]
data_processed <- read_rds(snakemake@input[["rds"]])$dat_transformed
decision_threshold <- 0.5

calc_balanced_precision_v <- Vectorize(calc_balanced_precision)
prior_baseline <- calc_baseline_precision(data_processed, 
                                          outcome_colname = outcome_colname, 
                                          pos_outcome = 'yes')
calc_model_sensspec <- function(trained_model, test_data, 
                                outcome_colname = NULL,
                                decision_threshold = 0.5,
                                pos_outcome = 'yes') {
  # adapted from https://github.com/SchlossLab/2021-08-09_ROCcurves/blob/8e62ff8b6fe1b691450c953a9d93b2c11ce3369a/ROCcurves.Rmd#L95-L109
  outcome_colname <- check_outcome_column(test_data, outcome_colname)
  actual <- is_pos <- tp <- fp <- fpr <- NULL
  probs <- stats::predict(trained_model,
                          newdata = test_data,
                          type = "prob"
  ) %>%
    dplyr::mutate(actual = test_data %>%
                    dplyr::pull(outcome_colname))
  
  total <- probs %>%
    dplyr::count(actual) %>%
    tidyr::pivot_wider(names_from = "actual", values_from = "n") %>%
    as.list()
  
  neg_outcome <- names(total) %>%
    # assumes binary outcome
    Filter(function(x) {
      x != pos_outcome
    }, .)
  
  sensspec <- probs %>%
    dplyr::arrange(dplyr::desc(!!rlang::sym(pos_outcome))) %>%
    dplyr::mutate(is_pos = actual == pos_outcome) %>%
    dplyr::mutate(
      tp = cumsum(is_pos),
      fp = cumsum(!is_pos),
      sensitivity = tp / total[[pos_outcome]],
      fpr = fp / total[[neg_outcome]]
    ) %>%
    dplyr::mutate(
      specificity = 1 - fpr,
      precision = tp / (tp + fp)
    ) %>%
    dplyr::select(-is_pos)
  return(sensspec)
}


calc_model_sensspec(
  model,
  test_dat,
  outcome_colname
) %>%
  mutate(prior = prior_baseline,
         balanced_precision = calc_balanced_precision_v(precision, prior)) %>%
  bind_cols(schtools::get_wildcards_tbl()) %>%
  write_csv(snakemake@output[["csv"]])
