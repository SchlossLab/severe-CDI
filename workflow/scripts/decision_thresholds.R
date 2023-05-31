schtools::log_snakemake()
library(assertthat)
library(here)
library(mikropml)
library(schtools)
library(tidyverse)

thresh_dat <- read_csv(here('results','thresholds_results_aggregated.csv')) %>% 
  mutate(predicted_pos_frac = (tp + fp) / (tp + fp + tn + fn))
treat_all <- thresh_dat %>% 
  filter(strategy == 'all') %>% 
  select(strategy, decision_threshold, net_benefit, dataset, outcome) %>% 
  unique() %>% 
  pivot_wider(names_from = strategy, values_from = net_benefit, 
              names_prefix = "nb_treat_")
treat_none <- thresh_dat %>% filter(strategy == 'none') %>% 
  select(strategy, decision_threshold, net_benefit, dataset, outcome) %>% 
  unique() %>% 
  pivot_wider(names_from = strategy, values_from = net_benefit, 
              names_prefix = "nb_treat_")
thresh_dat <- thresh_dat %>% 
  filter(strategy == 'model') %>% 
  left_join(treat_all, by = join_by(decision_threshold, dataset, outcome)) %>% 
  left_join(treat_none, by = join_by(decision_threshold, dataset, outcome))

prc_risk_pct <- thresh_dat %>% 
  mutate(Recall = round(Recall, 2)) %>%
  group_by(Recall, dataset, outcome) %>%
  summarise(
    mean_precision = mean(Precision),
    mean_pred_pos_frac = mean(predicted_pos_frac)
  ) %>% 
  ungroup() %>%
  group_by(dataset, outcome) %>% 
  mutate(diff_95th_pct = abs(mean_pred_pos_frac - 0.05)) %>%
  slice_min(diff_95th_pct)

priors <- read_csv(here("results","sensspec_results_aggregated.csv")) %>% 
  select(outcome, dataset, prior) %>% 
  dplyr::distinct()

confmat_95th_pct <- thresh_dat %>% 
  filter(!is.na(Precision), !(outcome == 'pragmatic' & dataset == 'int')) %>% 
  mutate(Recall = round(Recall, 2)) %>% 
  inner_join(prc_risk_pct, by = join_by(Recall, dataset, outcome)) %>% 
  mutate(diff_mean_prec = abs(mean_precision - Precision)) %>% 
  group_by(dataset, outcome) %>% 
  slice_min(diff_mean_prec) %>% 
  select(-seed) %>% 
  unique() %>% 
  slice_max(net_benefit) %>% 
  left_join(priors, by = join_by(outcome, dataset)) %>% 
  mutate(balanced_precision = calc_balanced_precision(Precision, prior)) %>% 
  select(outcome, dataset, Precision, nns, balanced_precision, 
         Recall, Specificity, tp,fp,tn,fn) %>% 
  filter(outcome != 'idsa') %>% 
  mutate(outcome = case_when(outcome == 'idsa' ~ 'IDSA',
                             outcome == 'attrib' ~ 'Attributable',
                             outcome == 'allcause' ~ 'All-cause',
                             outcome == 'pragmatic' ~ 'Pragmatic',
                             TRUE ~ NA_character_),
         dataset = case_when(dataset == 'full' ~ 'Full',
                             dataset == 'int' ~ 'Intersection',
                             TRUE ~ NA_character_)) %>% 
  rename(Severity = outcome,
         Dataset = dataset,
         `Balanced Precision` = balanced_precision,
         NNS = nns,
         TP = tp,
         FP = fp,
         TN = tn,
         FN = fn) %>% 
  mutate(across(is.numeric, ~ round(.x, digits = 2)))

confmat_95th_pct %>% 
  write_csv('results/decision_thresholds.csv')
