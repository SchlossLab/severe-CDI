schtools::log_snakemake()
library(mikropml)
library(tidyverse)

dat <- read_csv("results/performance_results_aggregated.csv") %>%
    rename(AUROC = AUC,
           AUPRC = prAUC) %>% 
    filter(metric == 'AUC', method == 'rf', trainfrac == 0.8) %>%
  mutate(
    outcome = factor(case_when(outcome == 'idsa' ~ 'IDSA\n severity',
                        outcome == 'attrib' ~ 'Attributable\n severity',
                        outcome == 'allcause' ~ 'All-cause\n severity',
                        outcome == 'pragmatic' ~ 'Pragmatic\n all-cause\n severity',
                        TRUE ~ NA_character_),
                    levels = c('IDSA\n severity',
                           'Attributable\n severity',
                           'All-cause\n severity',
                           'Pragmatic\n all-cause\n severity')
  )

# TODO