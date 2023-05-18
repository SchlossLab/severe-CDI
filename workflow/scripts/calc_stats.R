library(here)
library(tidyverse)

rel_diff <- function(final, init, percent = TRUE) {
  mult <- if (isTRUE(percent)) 100 else 1
  return((final - init) / init * mult)
}

otu_dat <- data.table::fread(here('data', 'mothur', 'alpha', 'cdi.opti_mcc.shared'))
metadat <- read_csv(here('data', 'process', 'cases_full_metadata.csv'))

n_cases_longitudinal <- nrow(otu_dat)
n_cases_first <- nrow(metadat)

save.image(file = here("results", "stats.RData"))