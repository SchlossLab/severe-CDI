library(tidyverse)
library(here)
library(data.table)

dat_shared <- fread(here('data', 'mothur', 'cdi.opti_mcc.shared'))
metadata <- read_tsv(here('data', 'process', 'final_CDI_16S_metadata.tsv')) %>% 
  rename(sample_title = `CDIS_Sample ID`)

idsa_sra <-
  full_join(read_csv((here('data', 'process', 'case_idsa_severity.csv'))) %>%
              rename(sample_title = sample),
            read_csv(here('data', 'SraRunTable.csv')),
            by = "sample_title") %>%
  select(sample_title, idsa_severity, Run) %>% 
  rename(Group = Run) %>% 
  left_join(metadata %>% select(sample_title, cdiff_case), 
            by = "sample_title")

cases_severity_OTUs <- left_join(idsa_sra, dat_shared, by = "Group") %>% 
  filter(cdiff_case == 'Case', !is.na(idsa_severity)) %>% 
  select(idsa_severity, starts_with("Otu"))

cases_severity_OTUs %>% write_csv(here('data', 'process', 'cases_severity_OTUs.csv'))
