schtools::log_snakemake()
library(here)
library(tidyverse)
make_table <- function(metadat) {
  metadat_cases <- metadat %>% 
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
  
  return(
    totals %>% 
      rename(Severity = severity_definition,
             n = total,
             '% severe' = percent
             ) %>% 
      mutate(Severity = case_when(Severity == 'idsa' ~ 'IDSA',
                                  Severity == 'allcause' ~ 'All-cause',
                                  Severity == 'attrib' ~ 'Attributable',
                                  Severity == 'pragmatic' ~ 'Pragmatic',
                                  TRUE ~ NA_character_))
  )
}
read_csv(here('data','process','cases_full_metadata.csv')) %>% 
  make_table() %>% write_csv(here('results','count_table_full.csv'))
read_csv(here('data','process','cases_int_metadata.csv')) %>% 
  make_table() %>% write_csv(here('results','count_table_int.csv'))
