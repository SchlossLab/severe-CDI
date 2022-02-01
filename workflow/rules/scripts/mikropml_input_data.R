source("workflow/rules/scripts/utilities.R") #Loads libraries, reads in metadata, functions

# Import otu_data for samples----
#Note: check for sub.sample version in data/mothur make sure that is the output from sub.sample
otu_data <- read_tsv("data/mothur/cdi.opti_mcc.0.03.subsample.shared", col_types=cols(Group=col_character())) %>%
  select(-label, -numOtus) %>%
  rename(sample = Group) %>% #group is the same as sample in the metadata data frame
  gather(-sample, key="otu", value="count") %>%
  mutate(rel_abund=count/5000) %>%  #Use 5000, because this is the subsampling parameter chosen.
  #using rel_abund also means the data will be normalized to between 0 and 1
  filter(!otu == "Otu00041") %>% #Remove most common C. difficile OTU, we want to determine C. diff status based on the rest of the microbiota
  pivot_wider(id_cols = sample, names_from = otu, values_from = rel_abund) %>% #Transform dataframe so that each OTU is a different column
  left_join(select(metadata, group, sample), by = "sample") %>%
  rename(outcome = group) %>%  #Rename group to outcome, this is what we will classify based on OTU relative abundances
  relocate(outcome, before = sample)

#Make sure no controls are included in data (should be dropped since we subsampled to 5000 sequences)
otu_data %>% filter(outcome == "pbs_control")
otu_data %>% filter(outcome == "water_control")
otu_data %>% filter(outcome == "mock_control")

#Create mikropml data to classify IDSA severity status with OTU level data ----
#Read in IDSA severity results & join to OTU data frame
idsa_status <- read_csv("data/process/case_idsa_severity.csv") %>%
  left_join(otu_data, by = "sample") %>% #Join to otu_data
  select(-sample, -outcome) %>% #Remove previous sample and outcome columns
  rename(outcome = idsa_severity) %>% #Indicate idsa_severity column is the outcome of interest
  write_csv(path = paste0("data/process/ml_idsa_severity.csv"))
