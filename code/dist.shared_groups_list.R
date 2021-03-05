#Create list of samples for generating distance matrices and ordinations
#This list will go in dist.shared() group argument in the following mothur batch files:
# code/jsd_ordination.batch
# code/braycurtis_ordination.batch

#Read in alpha diversity values from mothur to obtain list of samples
ord_samples <- read_tsv("data/mothur/cdi.opti_mcc.groups.ave-std.summary") %>%
  filter(method == "ave") %>% #Otherwise all samples will be listed twice
  rename(sample = group) %>% #group is the same as sample in the metadata data frame
  left_join(metadata, by = "sample") %>% #Match only the samples we have sequence data for
  filter(!sample %in% contam_samples) %>% #Remove 2 contaminated samples
  pull(sample) %>% 
  noquote() %>%  #Remove quotations from the characters
  glue_collapse(sep = "-") #Separate all samples with a -
