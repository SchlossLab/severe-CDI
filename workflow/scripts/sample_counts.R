schtools::log_snakemake()
library(here)
library(tidyverse)
make_table <- function(dat) {
  metadat_cases <- dat %>% 
    filter(!(is.na(idsa) & is.na(allcause) & is.na(attrib) & is.na(pragmatic)))
  
  counts <- metadat_cases %>%
    pivot_longer(c(idsa,attrib,allcause,pragmatic),
                 names_to = 'severity_definition', values_to = 'is_severe') %>%
    count(severity_definition, is_severe) %>%
    filter(!is.na(is_severe))
  
  counts_wide <- counts %>%
    pivot_wider(names_from = severity_definition, values_from = n) %>%
    select(is_severe, idsa, attrib, allcause, pragmatic)
  
  totals <- counts %>%
    left_join(counts %>%
                group_by(severity_definition) %>%
                summarise(total = sum(n))) %>%
    mutate(percent = round(n / total * 100, 1)) %>%
    filter(is_severe == 'yes') %>%
    select(severity_definition, total, percent)
  percents <- totals %>% select(severity_definition, percent) %>%
    pivot_wider(names_from = severity_definition, values_from = percent)%>%
    mutate(stat = '% Severe', .before = allcause)
  totals_percents <- totals %>%
    select(-percent) %>%
    pivot_wider(names_from = severity_definition, values_from = total) %>%
    mutate(stat = 'n', .before = allcause) %>%
    add_row(percents) %>%
    select(stat, idsa, allcause, attrib, pragmatic)
  return(totals_percents)
}

read_csv(here('data','process','cases_full_metadata.csv')) %>% 
  make_table() %>% 
  write_csv(here('results','count_table_full.csv'))
read_csv(here('data','process','cases_int_metadata.csv')) %>% 
  make_table()  %>% 
  write_csv(here('results','count_table_int.csv'))
