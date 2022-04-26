#' filter a dataframe to just one sample per patient, selecting the earliest sample
filter_first_samples <- function(metadat, 
                                 patient_col = subject_id,
                                 date_col = collection_date) {
  # modified from https://www.statology.org/select-first-row-in-group-dplyr/
  metadat %>% 
    group_by({{ patient_col }}) %>% 
    arrange({{ date_col }}) %>% 
    filter(row_number() == 1) %>% 
    arrange({{ patient_col }}) %>% 
    ungroup()
}
