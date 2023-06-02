library(schtools)
library(tidyverse)


cdiff_taxa <- schtools::read_tax("data/mothur/alpha/cdi.taxonomy") %>% 
  filter(str_detect(family, "Peptost"), str_detect(genus, 'Clostrid') | str_detect(genus, 'unclassified')) %>% 
  left_join(feat_dat, by = 'otu')

cdiff_relabun_dat <- data.table::fread(here('data', 'mothur', 'alpha', 
                                      'cdi.opti_mcc.shared')) %>% 
  calc_relabun() %>% 
  filter(otu %in% (cdiff_taxa %>% pull(otu))) %>% 
  right_join(left_join(read_csv(here('data', 'process', 'cases_full_metadata.csv')),
                       data.table::fread(here('data', 'SraRunTable.csv')) %>% 
                         select(-Group) %>% 
                         rename(sample_id = sample_title,
                                sample = Run) %>% 
                         select(sample_id, sample), by = 'sample_id')) %>% 
  select(sample_id, otu, rel_abun, idsa, attrib, allcause, pragmatic) %>% 
  pivot_longer(c(idsa, attrib, allcause, pragmatic), 
               names_to = 'outcome', values_to = 'is_severe') %>% 
  right_join(cdiff_taxa) %>% 
  filter(!is.na(is_severe)) %>% 
  left_join(
     read_csv("results/feature-importance_results_aggregated.csv") %>% 
      rename(otu = feat)
     )

tiny_constant <- cdiff_relabun_dat %>%
  filter(rel_abun > 0) %>%
  slice_min(rel_abun) %>%
  pull(rel_abun) %>% .[1]/100 # select tiniest non-zero relabun and divide


cdiff_relabun_dat %>% 
  group_by(otu, label_html, dataset, outcome, is_severe) %>% 
  summarize(med_rel_abun = median(rel_abun))

cdiff_relabun_dat %>% 
  pivot_longer(c(rel_abun, perf_metric_diff), names_to = 'abunperf') %>% 
  ggplot(aes(x = value, y = label_html, shape = is_severe, color = outcome)) +
  stat_summary(fun = median,
               geom = 'point',
               position = position_dodge(width = 0.5)) +
  facet_grid(dataset ~ abunperf)
