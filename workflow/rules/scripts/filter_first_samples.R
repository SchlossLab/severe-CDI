#' filter a dataframe to just one sample per patient, selecting the earliest sample
filter_first_samples <- function(idsa_sra) {
  # modified from https://www.statology.org/select-first-row-in-group-dplyr/
  idsa_sra %>% 
    group_by(patient_id) %>% 
    arrange(collection_date) %>% 
    filter(row_number() == 1) %>% 
    arrange(patient_id) %>% 
    ungroup() %>% 
    return()
}