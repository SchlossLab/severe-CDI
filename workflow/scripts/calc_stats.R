library(glue)
library(here)
library(tidyverse)

rel_diff <- function(final, init, percent = TRUE) {
  mult <- if (isTRUE(percent)) 100 else 1
  return((final - init) / init * mult)
}

otu_dat <- data.table::fread(here('data', 'mothur', 'alpha', 'cdi.opti_mcc.shared'))
metadat <- read_csv(here('data', 'process', 'cases_full_metadata.csv'))
meta_int <- read_csv(here('data', 'process', 'cases_int_metadata.csv'))

n_cases_first <- nrow(metadat)
n_cases_int <- nrow(meta_int)
num_otus <- otu_dat %>% pull(numOtus) %>% .[1]

param_grid <- expand_grid(outcome = c('idsa','attrib','allcause','pragmatic'),
                          dataset = c('full','int'))
count_feats <- function(outcome, dataset) {
  dat_proc <- read_rds(here('data','process', glue('dat-proc_{outcome}_{dataset}_OTU.Rds')))
  tibble_row(
    nfeats = ncol(dat_proc$dat_transformed) - 1,
    ngroups = length(dat_proc$grp_feats),
    nremoved = length(dat_proc$removed_feats),
    dataset = dataset,
    outcome = outcome
  )
}
preproc_info <- map2(param_grid$outcome, param_grid$dataset, count_feats) %>% 
  list_rbind()
preproc_ranges <- preproc_info %>% 
  summarize(min_removed = min(nremoved), 
            max_removed = max(nremoved),
            min_feats = min(nfeats),
            max_feats = max(nfeats)) %>% 
  as.list()

# 95th percentile of risk / decision thresholds
confmat_95th_pct <- read_csv('results/decision_thresholds.csv')
attrib_nns <- confmat_95th_pct %>% filter(Dataset == 'Full', Outcome == 'Attributable') %>% pull(NNS)
allcause_nns <- confmat_95th_pct %>% filter(Dataset == 'Full', Outcome == 'All-cause') %>% pull(NNS)
pragmatic_nns <- confmat_95th_pct %>% filter(Dataset == 'Full', Outcome == 'Pragmatic') %>% pull(NNS)

ehr_nns <- 1/0.417
curated_nns <- 1/0.167

# NNT
fdx_nnt <- 10 # [@long_oral_2022;@tashiro_oral_2022]

# NNB
allcause_fdx_nnb <- fdx_nnt * allcause_nns
attrib_fdx_nnb <- fdx_nnt * attrib_nns
pragmatic_fdx_nnb <- fdx_nnt * pragmatic_nns

min_fdx_nnb <- min(c(allcause_fdx_nnb, attrib_fdx_nnb, pragmatic_fdx_nnb))
max_fdx_nnb <- max(c(allcause_fdx_nnb, attrib_fdx_nnb, pragmatic_fdx_nnb))
min_screen <- min_fdx_nnb * 100/5 # 95th percentile of risk
max_screen <- max_fdx_nnb * 100/5 # 95th percentile of risk

ehr_fdx_nnb <- ehr_nns * fdx_nnt
ehr_screen <- ehr_fdx_nnb * 100/5
# clean up objects not used in paper
remove(otu_dat, metadat, preproc_info, confmat_95th_pct)

save.image(file = here("results", "stats.RData"))