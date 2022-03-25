library(tidyverse)
library(here)
library(data.table)

source(here('workflow', 'rules', 'scripts', 'filter_first_samples.R')) 

dat_shared <- fread(here('data', 'mothur', 'cdi.opti_mcc.shared')) %>% rename(Run = Group)
metadata <- read_tsv(here('data', 'process', 'final_CDI_16S_metadata.tsv')) %>% 
  rename(sample_id = `CDIS_Sample ID`, patient_id = `CDIS_Study ID`)

attrib_dat <-
  full_join(read_csv((here('data', 'raw', 'mishare', 'clinical_outcomes.csv'))) %>%
              rename(sample_id = SAMPLE_ID),
            read_csv(here('data', 'SraRunTable.csv')) %>% rename(sample_id = sample_title),
            by = "sample_id") %>% 
  rename(attrib = ATTRIB_SEVERECDI) %>% 
  select(sample_id, patient_id, collection_date, attrib, Run) %>% 
  left_join(metadata %>% select(sample_id, cdiff_case), 
            by = "sample_id") 

multi_samples <- attrib_dat %>% group_by(patient_id) %>% filter(cdiff_case == "Case") %>% tally() %>% filter(n > 1)

one_sample_per_patient <- filter_first_samples(attrib_dat)

cases_severity_OTUs <- left_join(one_sample_per_patient, dat_shared, by = "Run") %>% 
  filter(cdiff_case == 'Case', !is.na(attrib)) %>% 
  select(attrib, starts_with("Otu")) %>% mutate(attrib=case_when(attrib == 0 ~ "no", attrib == 1 ~ "yes", TRUE ~ NA_character_))

cases_severity_OTUs %>% write_csv(here('data', 'process', 'attrib_OTUs.csv'))


allcause_dat <-
  full_join(read_csv((here('data', 'raw', 'mishare', 'clinical_outcomes_pt2.csv'))) %>%
              rename(sample_id = SAMPLE_ID),
            read_csv(here('data', 'SraRunTable.csv')) %>% rename(sample_id = sample_title),
            by = "sample_id") %>% 
  rename(unattrib = UNATTRIB_SEVERECDI) %>% 
  select(sample_id, patient_id, collection_date, unattrib, Run) %>% 
  left_join(metadata %>% select(sample_id, cdiff_case), 
            by = "sample_id") %>% 
  left_join(attrib_dat, by = c("sample_id", "patient_id", "collection_date", "cdiff_case", "Run")) %>% 
  mutate(allcause=case_when((attrib==1) | (unattrib==1) ~ "yes", 
                            (attrib==0) | (unattrib==0) ~ "no",
                            is.na(attrib) | is.na(unattrib) ~ NA_character_))

multi_samples <- allcause_dat %>% group_by(patient_id) %>% filter(cdiff_case == "Case") %>% tally() %>% filter(n > 1)

one_sample_per_patient <- filter_first_samples(allcause_dat)

cases_severity_OTUs <- left_join(one_sample_per_patient, dat_shared, by = "Run") %>% 
  filter(cdiff_case == 'Case', !is.na(allcause)) %>% 
  select(allcause, starts_with("Otu")) 

cases_severity_OTUs %>% write_csv(here('data', 'process', 'allcause_OTUs.csv'))
