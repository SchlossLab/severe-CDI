source("code/utilities.R") #Loads libraries, reads in metadata, functions
set.seed(19760620) #Same seed used for mothur analysis

#Perform PERMANOVA with adonis----
#Read in Bray-Curtis distance matrix
bc_dist <- read_dist("data/mothur/cdi.opti_mcc.braycurtis.0.03.lt.std.dist")
bc_variables <- tibble(sample = attr(bc_dist, "Labels")) %>%
  left_join(metadata, by = "sample")
detectCores()
detectCores("system")
detectCores("mc.cores")
bc_adonis <- adonis(bc_dist~group, data = bc_variables, permutations = 1000, parallel = 20)
bc_adonis
#Select the adonis results dataframe and transform rownames into effects column
bc_adonis_table <- as_tibble(rownames_to_column(bc_adonis$aov.tab, var = "effects")) %>%
  write_tsv("data/process/permanova_bc_group.tsv")#Write results to .tsv file
bc_adonis <- adonis(bc_dist~miseq_run, data = bc_variables, permutations = 1000, parallel = 20)
bc_adonis
#Select the adonis results dataframe and transform rownames into effects column
bc_adonis_table <- as_tibble(rownames_to_column(bc_adonis$aov.tab, var = "effects")) %>%
  write_tsv("data/process/permanova_bc_miseq_run.tsv")#Write results to .tsv file
bc_adonis <- adonis(bc_dist~plate, data = bc_variables, permutations = 1000, parallel = 20)
bc_adonis
#Select the adonis results dataframe and transform rownames into effects column
bc_adonis_table <- as_tibble(rownames_to_column(bc_adonis$aov.tab, var = "effects")) %>%
  write_tsv("data/process/permanova_bc_plate.tsv")#Write results to .tsv file
bc_adonis <- adonis(bc_dist~plate_location, data = bc_variables, permutations = 1000, parallel = 20)
bc_adonis
#Select the adonis results dataframe and transform rownames into effects column
bc_adonis_table <- as_tibble(rownames_to_column(bc_adonis$aov.tab, var = "effects")) %>%
  write_tsv("data/process/permanova_bc_plate_location.tsv")#Write results to .tsv file
bc_adonis <- adonis(bc_dist~pbs_added, data = bc_variables, permutations = 1000, parallel = 20)
bc_adonis
#Select the adonis results dataframe and transform rownames into effects column
bc_adonis_table <- as_tibble(rownames_to_column(bc_adonis$aov.tab, var = "effects")) %>%
  write_tsv("data/process/permanova_bc_pbs_added.tsv")#Write results to .tsv file


bc_adonis <- adonis(bc_dist~group/(miseq_run*plate*plate_location*pbs_added), data = bc_variables, permutations = 1000, parallel = 20)
bc_adonis
#Select the adonis results dataframe and transform rownames into effects column
bc_adonis_table <- as_tibble(rownames_to_column(bc_adonis$aov.tab, var = "effects")) %>%
  write_tsv("data/process/permanova_bc.tsv")#Write results to .tsv file
