
filter_first_samples <- function(idsa_sra) {
  sort_by_patient <- idsa_sra %>% group_by(patient_id)
  sorted <- sort_by_patient[with(sort_by_patient, order(patient_id, collection_date)),]
  count <- 2
  my_entry <- sorted[1, "patient_id"]
  for (entry in sorted) {
    if (sorted[count, "patient_id"] == my_entry) {
      sorted <- sorted %>% slice(-c(count))
      my_entry <- sorted[count, "patient_id"]
    }
    else {
      my_entry <- sorted[count, "patient_id"]
      ++count
    }
  }
  return(sorted)
}