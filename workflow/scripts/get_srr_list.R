schtools::log_snakemake()
library(tidyverse)
run_tab <- read_csv(here('data', 'SraRunTable.csv')) %>%
              rename(sample_id = sample_title) 
run_tab %>% 
  filter(Group == 'case') %>% 
  pull(Run) %>% 
  write(file = here('data/SRR_Acc_List.txt'))
