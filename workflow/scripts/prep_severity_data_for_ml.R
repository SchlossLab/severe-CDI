library(tidyverse)
library(here)
library(data.table)

source(here('workflow', 'rules', 'scripts', 'filter_first_samples.R')) 

dat_shared <- fread(here('data', 'mothur', 'cdi.opti_mcc.shared')) %>% rename(Run = Group)
metadat <- read_tsv(here('data', 'process', 'final_CDI_16S_metadata.tsv')) %>% 
  rename(sample_id = `CDIS_Sample ID`, patient_id = `CDIS_Study ID`)


# idsa

idsa_sra <-
  full_join(
    read_csv((
      here('data', 'process', 'case_idsa_severity.csv')
    )) %>%
      rename(sample_id = sample),
    read_csv(here('data', 'SraRunTable.csv')) %>% 
      rename(sample_id = sample_title),
    by = "sample_id"
  ) %>%
  select(sample_id, idsa_severity, Run, patient_id, collection_date) %>%
  left_join(metadat %>% select(sample_id, cdiff_case),
            by = "sample_id")

multi_samples <-
  idsa_sra %>% 
  group_by(patient_id) %>% 
  filter(cdiff_case == "Case") %>% 
  tally() %>% 
  filter(n > 1)

one_sample_per_patient_idsa <- filter_first_samples(idsa_sra)

cases_severity_OTUs_idsa <-
  left_join(one_sample_per_patient_idsa, dat_shared, 
            by = "Run") %>%
  filter(cdiff_case == 'Case', !is.na(idsa_severity)) %>%
  select(idsa_severity, starts_with("Otu")) %>%
  rename(idsa = idsa_severity)

cases_severity_OTUs_idsa %>% write_csv(here('data', 'process', 'idsa_OTUs.csv'))


# attrib

attrib_dat <-
  full_join(read_csv((here('data', 'raw', 'mishare', 'clinical_outcomes.csv'))) %>%
              rename(sample_id = SAMPLE_ID),
            read_csv(here('data', 'SraRunTable.csv')) %>% 
              rename(sample_id = sample_title), by = "sample_id") %>% 
  rename(attrib = ATTRIB_SEVERECDI) %>% 
  mutate(attrib = case_when(attrib == 0 ~ "no",
                            attrib == 1 ~ "yes",
                            TRUE ~ NA_character_)) %>% 
  select(sample_id, patient_id, collection_date, attrib, Run) %>% 
  left_join(metadat %>% 
              select(sample_id, cdiff_case), by = "sample_id") 

multi_samples_attrib <- attrib_dat %>% 
  group_by(patient_id) %>% 
  filter(cdiff_case == "Case") %>% 
  tally() %>% 
  filter(n > 1)

one_sample_per_patient_attrib <- filter_first_samples(attrib_dat)

cases_severity_OTUs_attrib <- 
  left_join(one_sample_per_patient_attrib, dat_shared, by = "Run") %>% 
  filter(cdiff_case == 'Case', !is.na(attrib)) %>% 
  select(attrib, starts_with("Otu")) 

cases_severity_OTUs_attrib %>% write_csv(here('data', 'process', 'attrib_OTUs.csv'))


# allcause

allcause_dat <-
  full_join(read_csv((here('data', 'raw', 'mishare', 'clinical_outcomes_pt2.csv'))) %>%
              rename(sample_id = SAMPLE_ID),
            read_csv(here('data', 'SraRunTable.csv')) %>% rename(sample_id = sample_title),
            by = "sample_id") %>% 
  rename(unattrib = UNATTRIB_SEVERECDI) %>% 
  mutate(unattrib = case_when(unattrib == 0 ~ "no",
                              unattrib == 1 ~ "yes",
                              TRUE ~ NA_character_)) %>% 
  select(sample_id, patient_id, collection_date, unattrib, Run) %>% 
  left_join(metadat %>% 
              select(sample_id, cdiff_case),by = "sample_id") %>% 
  left_join(attrib_dat, 
            by = c("sample_id", "patient_id", "collection_date", "cdiff_case", "Run")) %>% 
  mutate(allcause = case_when((attrib=="yes") | (unattrib=="yes") ~ "yes", 
                              (attrib=="no") | (unattrib=="no") ~ "no",
                              is.na(attrib) | is.na(unattrib) ~ NA_character_)
         )

multi_samples_allcause <- allcause_dat %>% 
  group_by(patient_id) %>% 
  filter(cdiff_case == "Case") %>% 
  tally() %>% 
  filter(n > 1)

one_sample_per_patient_allcause <- filter_first_samples(allcause_dat)

cases_severity_OTUs_allcause <-
  left_join(one_sample_per_patient_allcause, dat_shared, by = "Run") %>%
  filter(cdiff_case == 'Case', !is.na(allcause)) %>%
  select(allcause, starts_with("Otu")) 

cases_severity_OTUs_allcause %>% write_csv(here('data', 'process', 'allcause_OTUs.csv'))
