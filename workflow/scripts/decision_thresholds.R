schtools::log_snakemake()
library(assertthat)
library(here)
library(mikropml)
library(tidyverse)

sensspec_dat <- read_csv(here('results','sensspec_results_aggregated.csv'))
dat_med <- sensspec_dat %>% filter(dataset == 'full', outcome == 'allcause', seed == 100) 
dat_med

get_threshold_performance <- function(dat, decision_threshold = 0.3) {
  preds <- dat_med %>% select(
    yes, no, actual
  ) %>% 
    mutate(pred = factor(if_else(yes > decision_threshold, 'yes', 'no'), 
                         levels = c('yes', 'no')),
           actual = factor(actual, levels = c('yes','no')))
  
  conf_mat <- caret::confusionMatrix(preds$actual, preds$pred)
  conf_mat$byClass %>% as_tibble_row()
  tp <- conf_mat$table[1,1]
  fp <- conf_mat$table[1,2]
  tn <- conf_mat$table[2,2]
  fn <- conf_mat$table[2,1]
  total <- nrow(dat_med)
  assert_that(total == tp+fp+tn+fn)
  return(conf_mat$byClass %>% 
           as_tibble_row() %>% 
           mutate(tp = tp,
                  fp = fp,
                  tn = fn,
                  fn = fn,
                  net_benefit = tp / total - (fp / total) * (decision_threshold / (1 - decision_threshold)),
                  nns = 1 / `Pos Pred Value`,
                  decision_threshold = decision_threshold
                  )
         )
}
