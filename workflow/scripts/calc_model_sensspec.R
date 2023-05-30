schtools::log_snakemake()
library(assertthat)
library(here)
#library(mikropml)
devtools::load_all('../mikropml')
library(purrr)
library(schtools)
library(tidyverse)
source(here('workflow','scripts','calc_balanced_precision.R'))

wildcards <- get_wildcards_tbl()
model <- read_rds(snakemake@input[["model"]])
test_dat <- read_csv(snakemake@input[["test"]])
outcome_colname <- snakemake@params[["outcome_colname"]]
data_processed <- read_rds(snakemake@input[["rds"]])$dat_transformed

calc_balanced_precision_v <- Vectorize(calc_balanced_precision)
prior_baseline <- calc_baseline_precision(data_processed, 
                                          outcome_colname = outcome_colname, 
                                          pos_outcome = 'yes')

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# performance for ROC/PRC curves
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

calc_model_sensspec <- function(trained_model, test_data, 
                                outcome_colname = NULL,
                                decision_threshold = 0.5,
                                pos_outcome = 'yes') {
  # adapted from https://github.com/SchlossLab/2021-08-09_ROCcurves/blob/8e62ff8b6fe1b691450c953a9d93b2c11ce3369a/ROCcurves.Rmd#L95-L109
  outcome_colname <- mikropml:::check_outcome_column(test_data, outcome_colname)
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
      precision = if (tp == 0 & fp == 0) {0} else {tp / (tp + fp)}
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
  bind_cols(wildcards) %>%
  write_csv(snakemake@output[["sensspec"]])


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# decision thresholds
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

get_threshold_performance <- function(dat, decision_threshold, 
                                      pos_outcome = 'yes') {
  preds <- dat %>% 
    mutate(pred = factor(case_when(yes > decision_threshold ~ 'yes', 
                                   TRUE ~ 'no'), 
                         levels = c('yes', 'no')),
           actual = factor(actual, levels = c('yes','no')))
  
  conf_mat <- caret::confusionMatrix(data = preds$pred, 
                                     reference = preds$actual,
                                     positive = pos_outcome,
                                     mode = 'everything')
  conf_mat$byClass %>% as_tibble_row()
  tp <- conf_mat$table[1,1]
  fp <- conf_mat$table[1,2]
  tn <- conf_mat$table[2,2]
  fn <- conf_mat$table[2,1]
  total <- nrow(dat)
  assert_that(total == tp+fp+tn+fn)
  return(conf_mat$byClass %>% 
           as_tibble_row() %>% 
           mutate(tp = tp,
                  fp = fp,
                  tn = tn,
                  fn = fn,
                  Precision = case_when(tp == 0 & fp == 0 ~ 0, TRUE ~ Precision),
                  net_benefit = tp / total - (fp / total) * (decision_threshold / (1 - decision_threshold)),
                  nns = 1 / Precision,
                  decision_threshold = decision_threshold
           )
  )
}

compute_thresholds <- function(dat, thresholds = seq.int(0, 0.999, 0.05)) {
  return(thresholds %>% 
           map(get_threshold_performance, dat = dat) %>% 
           list_rbind()
  )
}

probs <- stats::predict(model,
                        newdata = test_dat,
                        type = "prob"
) %>%
  dplyr::mutate(actual = test_dat %>%
                  dplyr::pull(outcome_colname)) %>% 
  compute_thresholds() %>% 
  mutate(strategy = 'model')

treat_all <- data_processed %>% 
  select(outcome_colname) %>% 
  rename(actual = outcome_colname) %>% 
  mutate(no = 0, yes = 1) %>% 
  compute_thresholds() %>% 
  mutate(strategy = 'all')

treat_none <- data_processed %>% 
  select(outcome_colname) %>% 
  rename(actual = outcome_colname) %>% 
  mutate(no = 1, yes = 0) %>% 
  compute_thresholds() %>% 
  mutate(strategy = 'none')

bind_rows(probs, treat_all, treat_none) %>% 
  bind_cols(wildcards) %>% 
  write_csv(snakemake@output[['thresholds']])
  
  
test_conf_mat <- function() {
    library(testthat)
    pos_outcome <- 1
    df <- tibble(actual = factor(c(1, 2, 1, 1, 1, 1, 2, 2, 2, 2),
                                 levels = c(1, 2)),
                 prediction = factor(c(1, 1, 1, 1, 2, 1, 2, 1, 2 , 2),
                                     levels = c(1, 2)))
    cm <- df %>%
      mutate(
        cm = case_when(
          actual == pos_outcome & actual == prediction ~ 'tp',
          actual == pos_outcome & actual != prediction ~ 'fn',
          actual != pos_outcome & actual == prediction ~ 'tn',
          actual != pos_outcome & actual != prediction ~ 'fp',
          TRUE ~ NA_character_
        )
      ) %>%
      count(cm) %>%
      pivot_wider(names_from = cm, values_from = n) %>%
      as_vector()
    conf_mat <-
      confusionMatrix(
        data = df$prediction,
        reference = df$actual,
        positive = as.character(pos_outcome)
      )
    test_that("confusion matrix values are accessed correctly", {
      expect_equal(cm[['tp']], conf_mat$table[1, 1])
      expect_equal(cm[['fp']], conf_mat$table[1, 2])
      expect_equal(cm[['tn']], conf_mat$table[2, 2])
      expect_equal(cm[['fn']], conf_mat$table[2, 1])
    })
}
  