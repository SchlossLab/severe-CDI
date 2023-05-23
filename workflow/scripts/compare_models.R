schtools::log_snakemake()
library(doFuture)
library(future)
library(future.apply)
library(glue)
library(here)
library(mikropml)
library(schtools)
library(tidyverse)

doFuture::registerDoFuture()
nworkers <- if (exists('snakemake')) {
  snakemake@threads
} else {
  4
}
message(glue("Using {nworkers} cores for parallelization"))
future::plan(future::multicore, workers = nworkers)

dat <- read_csv(here('results','performance_results_aggregated.csv')) %>% 
  rename(AUROC = AUC,
         AUBPRC = aubprc)

datasets <- dat %>% pull(dataset) %>% unique()
metrics <- c('AUROC', 'AUBPRC')
param_grid1 <- expand.grid(dataset = datasets, metric = metrics) %>% 
  mutate(across(where(is.factor), as.character))

results_outcome <- map2(param_grid1$dataset, param_grid1$metric, 
                \(x, y) {
                  dat %>% 
                    filter(dataset == x) %>% 
                    compare_models(metric = y, 
                                   group_name = 'outcome',
                                   nperm = 10000) %>% 
                    mutate(metric = y, dataset = x)
                }) %>% 
  list_rbind() 

outcomes <- dat %>% pull(outcome) %>% unique()
param_grid2 <- expand_grid(outcome = outcomes, 
                           metric = metrics) %>% 
  mutate(across(where(is.factor), as.character))

results_dataset <- pmap(param_grid2,
                        \(metric, outcome) {
                          dat %>% 
                            filter(outcome == outcome) %>% 
                            compare_models(metric = metric, 
                                           group_name = 'dataset',
                                           nperm = 10000) %>% 
                            mutate(metric = metric, 
                                   outcome = outcome,)
                        }) %>% 
  list_rbind()

results <- bind_rows(results_outcome, results_dataset)

results %>% 
  write_csv(here('results', 'model_comparisons.csv'))
