schtools::log_snakemake()
library(tidyverse)
library(here)
library(data.table)

source(here('workflow', 'scripts', 'filter_first_samples.R'))
shared_otu <- fread(snakemake@input[['otu']]) %>% 
  rename(run_id = Group)
run_tab <- read_csv(here('data', 'SraRunTable.csv')) %>%
  filter(description == 'case') %>% 
  rename(run_id = Run,
         sample_id = sample_title) 
otu_dat <- right_join(run_tab, shared_otu)

seq_metadat <- read_tsv(here('data', 'process', 'final_CDI_16S_metadata.tsv')) %>%
              rename(sample_id = `CDIS_Sample ID`,
                     subject_id = `CDIS_Study ID`,
                     collection_date = `CDIS_collect date`) %>%
  full_join(read_csv(here('data', 'process', 'case_idsa_severity.csv')) %>%
              rename(sample_id = sample,
                     idsa_lab = idsa_severity),
            by = 'sample_id') %>% 
  filter(group == 'case')

attrib_dat <- read_csv(here('data', 'raw', 'mishare',
                            'clinical_outcomes.csv')) %>%
  select(-CDIFF_SAMPLE_DATE, -CDIFF_COLLECT_DTM) %>%
  mutate(chart_reviewed = TRUE)
unattrib_dat <- read_csv(here('data', 'raw', 'mishare',
                              'clinical_outcomes_pt2.csv'))  %>%
  select(-CDIFF_SAMPLE_DATE, -CDIFF_COLLECT_DTM) %>%
  mutate(chart_reviewed = FALSE)

metadat_cases <- bind_rows(attrib_dat, unattrib_dat) %>%
  rename(sample_id = SAMPLE_ID,
         idsa_chart = IDSA_severe,
         attrib = ATTRIB_SEVERECDI,
         unattrib = UNATTRIB_SEVERECDI) %>%
  select(-SUBJECT_ID) %>%
  full_join(seq_metadat,
            by = c('sample_id')) %>%
  filter(!is.na(cdiff_case)) %>%
  mutate(idsa = case_when(idsa_chart == 1 ~ 'yes',
                          idsa_chart == 0 ~ 'no',
                          TRUE ~ idsa_lab),
         attrib = case_when(attrib == 1 ~ 'yes',
                            attrib == 0 ~ 'no',
                            TRUE ~ NA_character_),
         unattrib = case_when(unattrib == 1 ~ 'yes',
                              unattrib == 0 ~ 'no',
                              TRUE ~ NA_character_),
         allcause = case_when(attrib == 'yes' | unattrib == 'yes' ~ 'yes',
                              attrib == 'no' & unattrib == 'no' ~ 'no',
                              is.na(attrib) ~ unattrib,
                              TRUE ~ NA_character_),
         pragmatic = case_when(attrib == 'yes' ~ 'yes',
                                    attrib == 'no'  ~ 'no',
                                    is.na(attrib) ~ unattrib,
                                    TRUE ~ NA_character_)
         ) %>%
  select(sample_id, subject_id, collection_date, cdiff_case,
         chart_reviewed, idsa, attrib, unattrib, allcause, pragmatic) %>% 
  filter_first_samples()
multi_samples <- metadat_cases %>%
  group_by(subject_id) %>%
  tally() %>%
  filter(n > 1)
metadat_cases %>% write_csv(here('data', 'process', 'cases_full_metadata.csv'))
shared_dat <- left_join(metadat_cases, otu_dat, by = 'sample_id')

shared_dat %>%
  filter(!is.na(idsa)) %>%
  select(idsa, starts_with("Otu")) %>%
  write_csv(here('data', 'process', 'idsa_full_OTU.csv'))
shared_dat %>%
  filter(!is.na(attrib)) %>%
  select(attrib, starts_with("Otu")) %>%
  write_csv(here('data', 'process', 'attrib_full_OTU.csv'))
shared_dat %>%
  filter(!is.na(allcause)) %>%
  select(allcause, starts_with("Otu")) %>%
  write_csv(here('data', 'process', 'allcause_full_OTU.csv'))
shared_dat %>%
  filter(!is.na(pragmatic)) %>%
  select(pragmatic, starts_with("Otu")) %>%
  write_csv(here('data', 'process', 'pragmatic_full_OTU.csv'))

metadat_cases_intersect <- metadat_cases %>% 
  filter(!is.na(idsa) & !is.na(attrib) & !is.na(allcause)) 
metadat_cases_intersect %>% 
  write_csv(here('data', 'process', 'cases_int_metadata.csv'))

shared_dat_intersect <- left_join(metadat_cases_intersect, 
                                  otu_dat, 
                                  by = 'sample_id')
shared_dat_intersect %>%
  select(idsa, starts_with("Otu")) %>%
  write_csv(here('data', 'process', 'idsa_int_OTU.csv'))
shared_dat_intersect %>%
  select(attrib, starts_with("Otu")) %>%
  write_csv(here('data', 'process', 'attrib_int_OTU.csv'))
shared_dat_intersect %>%
  select(allcause, starts_with("Otu")) %>%
  write_csv(here('data', 'process', 'allcause_int_OTU.csv'))
shared_dat_intersect %>%
  select(pragmatic, starts_with("Otu")) %>%
  write_csv(here('data', 'process', 'pragmatic_int_OTU.csv'))
