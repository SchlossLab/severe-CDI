library(tidyverse)
library(janitor)
r21 <- read_csv('data/process/cases.csv') %>% 
  left_join(read_csv('data/raw/mishare/r21_fullcohort_edited.csv') %>% 
  clean_names()) %>% 
  select(subject_id, medical_record_number, date_of_stool_sample_collection) %>% 
  filter(!is.na(medical_record_number))

r21 %>% write_csv('data/raw/mishare/data_for_EHR_extraction.csv')
