schtools::log_snakemake()
library(assertthat)
library(here)
library(mikropml)
library(purrr)
library(schtools)
library(tidyverse)
wildcards <- get_wildcards_tbl()

model <- read_rds(snakemake@input[["model"]])
test_dat <- read_csv(snakemake@input[["test"]])
outcome_colname <- snakemake@params[["outcome_colname"]]
data_processed <- read_rds(snakemake@input[["rds"]])$dat_transformed

get_threshold_performance <- function(dat, decision_threshold = 0.3) {
  preds <- dat %>% 
    mutate(pred = factor(case_when(yes > decision_threshold ~ 'yes', 
                                   TRUE ~ 'no'), 
                         levels = c('yes', 'no')),
           actual = factor(actual, levels = c('yes','no')))
  
  conf_mat <- caret::confusionMatrix(preds$actual, preds$pred)
  conf_mat$byClass %>% as_tibble_row()
  tp <- conf_mat$table[1,1]
  fp <- conf_mat$table[2,1]
  tn <- conf_mat$table[2,2]
  fn <- conf_mat$table[1,2]
  total <- nrow(dat)
  assert_that(total == tp+fp+tn+fn)
  return(conf_mat$byClass %>% 
           as_tibble_row() %>% 
           mutate(tp = tp,
                  fp = fp,
                  tn = tn,
                  fn = fn,
                  net_benefit = tp / total - (fp / total) * (decision_threshold / (1 - decision_threshold)),
                  nns = 1 / `Pos Pred Value`,
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

treat_all <- test_dat %>% 
  select(outcome_colname) %>% 
  rename(actual = outcome_colname) %>% 
  mutate(no = 0, yes = 1) %>% 
  compute_thresholds() %>% 
  mutate(strategy = 'all')

treat_none <- test_dat %>% 
  select(outcome_colname) %>% 
  rename(actual = outcome_colname) %>% 
  mutate(no = 1, yes = 0) %>% 
  compute_thresholds() %>% 
  mutate(strategy = 'none')

bind_rows(probs, treat_all, treat_none) %>% 
 ggplot(aes(decision_threshold, net_benefit, 
            color = strategy, linetype = strategy)) +
  geom_line(alpha = 0.6) +
  theme_sovacool()

