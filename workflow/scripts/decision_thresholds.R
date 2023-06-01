schtools::log_snakemake()
library(assertthat)
library(here)
library(mikropml)
library(schtools)
library(tidyverse)

thresh_dat <- read_csv(here('results','thresholds_results_aggregated.csv')) %>% 
  mutate(predicted_pos_frac = (tp + fp) / (tp + fp + tn + fn),
         diff_95th_pct = abs(predicted_pos_frac - 0.05))
# treat_all <- thresh_dat %>% 
#   filter(strategy == 'all') %>% 
#   select(strategy, decision_threshold, net_benefit, dataset, outcome) %>% 
#   unique() %>% 
#   pivot_wider(names_from = strategy, values_from = net_benefit, 
#               names_prefix = "nb_treat_")
# treat_none <- thresh_dat %>% filter(strategy == 'none') %>% 
#   select(strategy, decision_threshold, net_benefit, dataset, outcome) %>% 
#   unique() %>% 
#   pivot_wider(names_from = strategy, values_from = net_benefit, 
#               names_prefix = "nb_treat_")
# thresh_dat <- thresh_dat %>% 
#   filter(strategy == 'model') %>% 
#   left_join(treat_all, by = join_by(decision_threshold, dataset, outcome)) %>% 
#   left_join(treat_none, by = join_by(decision_threshold, dataset, outcome))

priors <- read_csv(here("results","sensspec_results_aggregated.csv")) %>% 
  select(outcome, dataset, prior) %>% 
  dplyr::distinct()


confmat_95th_pct <-
  thresh_dat %>% group_by(outcome, dataset) %>% slice_min(diff_95th_pct) %>% slice_min(nns) %>% slice_max(net_benefit) %>%  select(-seed) %>% unique() %>%
  left_join(priors, by = join_by(outcome, dataset)) %>%
  mutate(balanced_precision = calc_balanced_precision(prec, prior)) %>%
  select(outcome,
         dataset,
         prec,
         nns,
         balanced_precision,
         Recall,
         Specificity,
         tp,
         fp,
         tn,
         fn) %>%
  filter(outcome != 'idsa', !(outcome == 'pragmatic' & dataset == 'int')) %>%
  mutate(
    outcome = case_when(
      outcome == 'idsa' ~ 'IDSA',
      outcome == 'attrib' ~ 'Attributable',
      outcome == 'allcause' ~ 'All-cause',
      outcome == 'pragmatic' ~ 'Pragmatic',
      TRUE ~ NA_character_
    ),
    dataset = case_when(
      dataset == 'full' ~ 'Full',
      dataset == 'int' ~ 'Intersection',
      TRUE ~ NA_character_
    )
  ) %>%
  rename(
    Outcome = outcome,
    Dataset = dataset,
    TP = tp,
    FP = fp,
    TN = tn,
    FN = fn,
    Precision = prec,
    NNS = nns,
    `Balanced\nPrecision` = balanced_precision
  ) %>%
  mutate(across(is.numeric, ~ round(.x, digits = 2)))

confmat_95th_pct %>% 
  write_csv('results/decision_thresholds.csv')
