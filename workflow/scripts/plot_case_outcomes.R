library(tidyverse)
library(here)
dat <- read_csv(here('data','process', 'cases_metadata.csv'))

tally_outcome <- function(dat, outcome_col) {
  dat %>% 
    filter(!is.na({{outcome_col}})) %>% 
    group_by({{outcome_col}}) %>% 
    tally() %>% 
    mutate(severe = {{outcome_col}}) %>% 
    select(-{{outcome_col}}) %>% 
    rename({{outcome_col}} := n)
}

full_join(metadat_cases %>% tally_outcome(allcause), 
          metadat_cases %>% tally_outcome(attrib)) %>% 
  full_join(metadat_cases %>% tally_outcome(idsa)) %>% 
  select(severe, idsa, attrib, allcause) %>% 
  write_csv(here('data', 'process', 'outcomes_table.csv'))
