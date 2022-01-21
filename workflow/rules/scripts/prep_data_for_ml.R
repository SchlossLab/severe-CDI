library(tidyverse)
library(here)
library(data.table)

dat_shared <- fread(here('data', 'mothur', 'cdi.opti_mcc.shared'))
metadata <- read_tsv(here('data', 'process', 'final_CDI_16S_metadata.tsv')) %>% 
  rename(sample_id = `CDIS_Sample ID`, patient_id = `CDIS_Study ID`)

idsa_sra <-
  full_join(read_csv((here('data', 'process', 'case_idsa_severity.csv'))) %>%
              rename(sample_id = sample),
            read_csv(here('data', 'SraRunTable.csv')) %>% rename(sample_id = sample_title),
            by = "sample_id") %>% 
  select(sample_id, idsa_severity, Run, patient_id, collection_date) %>% 
  rename(Group = Run) %>% 
  left_join(metadata %>% select(sample_id, cdiff_case), 
            by = "sample_id")

multi_samples <- idsa_sra %>% group_by(patient_id) %>% filter(cdiff_case == "Case") %>% tally() %>% filter(n > 1)
# idsa_sra %>% filter(patient_id %in% multi_samples[["patient_id"]])
#TODO: get one sample per patient

cases_severity_OTUs <- left_join(idsa_sra, dat_shared, by = "Group") %>% 
  filter(cdiff_case == 'Case', !is.na(idsa_severity)) %>% 
  select(idsa_severity, starts_with("Otu")) %>% 
  rename(idsa=idsa_severity)

cases_severity_OTUs %>% write_csv(here('data', 'process', 'idsa_OTUs.csv'))
