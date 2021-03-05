source("code/utilities.R") #Loads libraries, reads in metadata, functions

#Create OTU-level input data based on only OTUs that were significant based on lefse analysis
#Note: Peptostreptococcaceae OTU 41 was included in lefse analysis but will be excluded from ML input data

#Read in OTU-level results from lefse analysis----
lefse_otu_results <- read_csv("data/process/lefse_combined_results_ml_input.csv")

#Function that will read in OTU data for all samples,
#Remove Peptostreptococcaceae OTU,
#Filter to only OTUs for the comparison selected
#Subset the data to just the samples in the comparison selected,
#Write out the subsetted data to a .csv file to be used as input data for mikropml
#Arguments:
#outcome1, outcome2: (in quotes)
#comparison_name: name of comparison that will also be included in the filename (in quotes)
subset_data_lefse <- function(outcome1, outcome2, comparison_name){
  subset_lefse_otus <- lefse_otu_results %>% 
    filter(comparison == comparison_name) %>% #Select only the rows for the specified comparison
    pull(OTU) #Pull only list of OTUs
  otu_data <- read_tsv("data/mothur/cdi.opti_mcc.0.03.subsample.shared", col_types=cols(Group=col_character())) %>%
    select(-label, -numOtus) %>%
    rename(sample = Group) %>% #group is the same as sample in the metadata data frame
    filter(!sample %in% contam_samples) %>%  #Remove 2 contaminated samples
    gather(-sample, key="otu", value="count") %>%
    mutate(rel_abund=count/5000) %>%  #Use 5000, because this is the subsampling parameter chosen.
    #using rel_abund also means the data will be normalized to between 0 and 1
    filter(!otu == "Otu00041") %>% #Remove most common C. difficile OTU, we want to determine C. diff status based on the rest of the microbiota
    filter(otu %in% subset_lefse_otus) %>% #Select only OTUs that were significant for the lefse analysis of that comparison
    pivot_wider(id_cols = sample, names_from = otu, values_from = rel_abund) %>% #Transform dataframe so that each OTU is a different column
    left_join(select(metadata, group, sample), by = "sample") %>% 
    rename(outcome = group) %>%  #Rename group to outcome, this is what we will classify based on OTU relative abundances
    relocate(outcome, before = sample) %>% 
    select(-sample) %>% #drop sample since we no longer need this column
    filter(outcome %in% c(outcome1, outcome2)) %>% 
    write_csv(path = paste0("data/process/ml_input_lefse_", comparison_name, ".csv"))
}

#Create 3 sets of input data at the OTU level for only OTUs that were significant based on lefse analysis----
#Create input data for Cases vs nondiarrheal controls 
subset_data_lefse("case", "nondiarrheal_control", "CvNDC")
#Create input data for Cases vs diarrheal controls
subset_data_lefse("case", "diarrheal_control", "CvDC")
#Create input data for diarrheal controls vs nondiarrheal controls
subset_data_lefse("diarrheal_control", "nondiarrheal_control", "DCvNDC")

