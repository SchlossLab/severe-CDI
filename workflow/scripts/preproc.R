source(snakemake@input[["logR"]])
doFuture::registerDoFuture()
future::plan(future::multicore, workers = snakemake@threads)

data_raw <- readr::read_csv(snakemake@input[["csv"]])
data_processed <- mikropml::preprocess_data(data_raw, outcome_colname = snakemake@wildcards[["outcome"]])

saveRDS(data_processed, file = snakemake@output[["rds"]])
