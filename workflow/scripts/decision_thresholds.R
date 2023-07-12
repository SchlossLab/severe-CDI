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

confmat_95th_pct_tbl <- thresh_dat %>% 
  filter(strategy == 'model', outcome != 'idsa', !(outcome == 'pragmatic' & dataset == 'int')) %>%
  group_by(outcome, dataset) %>% 
  slice_min(diff_95th_pct) %>% slice_min(nns) %>% slice_max(net_benefit) %>% select(-seed) %>% unique() %>%
  left_join(priors, by = join_by(outcome, dataset)) %>%
  mutate(balanced_precision = calc_balanced_precision(prec, prior)) %>%
  select(outcome,
         dataset,
         decision_threshold,
         tp,
         fp,
         tn,
         fn,
         prec,
         nns,
         #balanced_precision,
         Recall,
         Specificity) %>%
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
    `Risk threshold` = decision_threshold,
    TP = tp,
    FP = fp,
    TN = tn,
    FN = fn,
    Precision = prec,
    NNS = nns
  ) %>%
  mutate(across(where(is.numeric), ~ round(.x, digits = 2)))

med_nns <- thresh_dat %>% 
  filter(strategy == 'model', outcome != 'idsa', dataset != 'int') %>%
  mutate(nns2 = nns,
         nns = 1/Precision) %>% # use version of precision where it's NA when tp=0 so NNS isn't overoptimistic
  group_by(outcome, dataset, decision_threshold) %>% 
  summarize(median_nns = median(nns),
            median_nns2 = median(nns2))
nns_95th_pct <- thresh_dat %>% 
  filter(strategy == 'model', outcome != 'idsa', dataset != 'int') %>%
  group_by(outcome, dataset) %>% 
  slice_min(diff_95th_pct) %>% 
  right_join(med_nns) %>% 
  mutate(diff_med_nns = abs(nns - median_nns)) %>% 
  slice_min(diff_med_nns) %>% 
  filter(!is.na(nns), nns < Inf) %>% 
  select(outcome,
         dataset,
         decision_threshold,
         nns,
         median_nns, diff_med_nns, diff_95th_pct, decision_threshold, predicted_pos_frac) %>% 
  unique()

data.frame(outcome = c('allcause','attrib','pragmatic'),
           nns = c(5, 12, 5.5),
           decision_threshold = c(0.20, 0.142, 0.15),
           dataset = c('full', 'full', 'full')) %>% 
  write_csv(here('results/decision_thresholds.csv'))

            