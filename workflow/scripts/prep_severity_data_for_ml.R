library(tidyverse)
library(here)
library(data.table)

source(here('workflow', 'scripts', 'filter_first_samples.R')) 
otu_dat <- read_csv(here('data', 'SraRunTable.csv')) %>% 
              rename(sample_id = sample_title) %>% 
  left_join(fread(here('data', 'mothur', 'cdi.opti_mcc.shared')) %>% 
  rename(Run = Group), by = 'Run')
seq_metadat <- read_tsv(here('data', 'process', 'final_CDI_16S_metadata.tsv')) %>% 
              rename(sample_id = `CDIS_Sample ID`, 
                     subject_id = `CDIS_Study ID`,
                     collection_date = `CDIS_collect date`) %>% 
  full_join(read_csv(here('data', 'process', 'case_idsa_severity.csv')) %>% 
              rename(sample_id = sample,
                     idsa_lab = idsa_severity),
            by = 'sample_id')

attrib_dat <- read_csv(here('data', 'raw', 'mishare', 
                            'clinical_outcomes.csv')) %>% 
  select(-CDIFF_SAMPLE_DATE, -CDIFF_COLLECT_DTM) %>% 
  mutate(chart_reviewed = TRUE)
unattrib_dat <- read_csv(here('data', 'raw', 'mishare', 
                              'clinical_outcomes_pt2.csv'))  %>% 
  select(-CDIFF_SAMPLE_DATE, -CDIFF_COLLECT_DTM) %>% 
  mutate(chart_reviewed = FALSE) 
metadat <- bind_rows(attrib_dat, unattrib_dat) %>% 
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
                              TRUE ~ NA_character_)
         ) %>% 
  select(sample_id, subject_id, collection_date, cdiff_case, 
         chart_reviewed, idsa, attrib, unattrib, allcause) 
multi_samples <- metadat %>% 
  group_by(subject_id) %>% 
  tally() %>% 
  filter(n > 1)
metadat_1s <- filter_first_samples(metadat)
metadat_cases <- metadat_1s %>% filter(cdiff_case == 'Case')
shared_dat <- left_join(metadat_cases, otu_dat, by = 'sample_id')

shared_dat %>% 
  filter(!is.na(idsa)) %>% 
  select(idsa, starts_with("Otu")) %>% 
  write_csv(here('data', 'process', 'idsa_OTUs.csv'))


shared_dat %>% 
  filter(!is.na(attrib)) %>% 
  select(attrib, starts_with("Otu")) %>% 
  write_csv(here('data', 'process', 'attrib_OTUs.csv'))

shared_dat %>% 
  filter(!is.na(allcause)) %>% 
  select(allcause, starts_with("Otu")) %>% 
  write_csv(here('data', 'process', 'allcause_OTUs.csv'))
