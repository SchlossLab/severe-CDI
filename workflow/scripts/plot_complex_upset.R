library(tidyverse)
library(ComplexUpset)
library(glue)
dat <- read_csv(snakemake@input[['csv']]) %>% 
  select(sample_id, idsa, attrib, allcause) %>% 
  pivot_longer(-sample_id, names_to = 'severity_metric', values_to = 'is_severe') %>% 
  mutate(is_severe = case_when(is_severe == 'yes' ~ TRUE,
                               is_severe == 'no' ~ FALSE,
                               TRUE ~ NA)) #%>% filter(severity_metric == 'allcause' & is.na(is_severe))

severity_metrics <- c("idsa_TRUE", "idsa_FALSE", "idsa_NA", 
                      "attrib_TRUE", "attrib_FALSE", "attrib_NA", 
                      "allcause_TRUE", "allcause_FALSE", "allcause_NA"
                      )

dat_upset <- dat %>% 
  mutate(severity_metric = glue("{severity_metric}_{is_severe}"),
         is_member = case_when(is_severe == TRUE ~ TRUE,
                               is_severe == FALSE ~ TRUE,
                               is.na(is_severe) ~ NA,
                               TRUE ~ NA)) %>% 
  select(-is_severe) %>% 
  pivot_wider(names_from = 'severity_metric', values_from = 'is_member') %>% 
  # TODO: find a DRY way to accomplish this task
  mutate(idsa_TRUE = case_when(idsa_TRUE == TRUE ~ TRUE,
                               idsa_FALSE == TRUE ~ FALSE,
                               is.na(idsa_FALSE) ~ FALSE),
         idsa_FALSE = case_when(idsa_FALSE == TRUE ~ TRUE,
                                idsa_TRUE == TRUE ~ FALSE,
                                is.na(idsa_FALSE) ~ FALSE),
         idsa_NA = case_when(idsa_TRUE == FALSE & idsa_FALSE == FALSE ~ TRUE,
                             idsa_TRUE == TRUE | idsa_FALSE == TRUE ~ FALSE,
                             TRUE ~ NA),
         attrib_TRUE = case_when(attrib_TRUE == TRUE ~ TRUE,
                               attrib_FALSE == TRUE ~ FALSE,
                               is.na(attrib_FALSE) ~ FALSE),
         attrib_FALSE = case_when(attrib_FALSE == TRUE ~ TRUE,
                                attrib_TRUE == TRUE ~ FALSE,
                                is.na(attrib_FALSE) ~ FALSE),
         attrib_NA = case_when(attrib_TRUE == FALSE & attrib_FALSE == FALSE ~ TRUE,
                               attrib_TRUE == TRUE | attrib_FALSE == TRUE ~ FALSE,
                               TRUE ~ NA),
         allcause_TRUE = case_when(allcause_TRUE == TRUE ~ TRUE,
                               allcause_FALSE == TRUE ~ FALSE,
                               is.na(allcause_FALSE) ~ FALSE),
         allcause_FALSE = case_when(allcause_FALSE == TRUE ~ TRUE,
                                allcause_TRUE == TRUE ~ FALSE,
                                is.na(allcause_FALSE) ~ FALSE),
         allcause_NA = case_when(allcause_TRUE == FALSE & allcause_FALSE == FALSE ~ TRUE,
                                 allcause_TRUE == TRUE | allcause_FALSE == TRUE ~ FALSE,
                                 TRUE ~ NA)
         ) %>% 
  select(sample_id, all_of(severity_metrics)) 

if (stringr::str_detect(snakemake@input[['csv']], 'int')) {
  dat_upset <- dat_upset %>% select(-ends_with('NA'))
  severity_metrics <- severity_metrics %>% 
    Filter(function(x) {!stringr::str_detect(x, 'NA')}, .)
}


upset_plot <- dat_upset %>% 
  upset(severity_metrics, name = 'severity_metric')

ggsave(filename = snakemake@output[['png']], plot = upset_plot)
