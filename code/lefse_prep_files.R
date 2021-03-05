source("code/utilities.R") #Loads libraries, reads in metadata, functions

set.seed(19760620) #Same seed used for mothur analysis

#Goal is to create shared & design files for our 3 sets of binary comparisons
#These files will be used as input files for mothurs implementation of lefse (modeled after the LEfSe program from the Huttenhower lab)
#Citation for lefse: https://genomebiology.biomedcentral.com/articles/10.1186/gb-2011-12-6-r60

#Narrow down metadata to only the columns needed for lefse (sample and group)
design <- metadata %>% 
  select(sample, group) %>% 
  rename(sample_type = group, group = sample)  #For design file the individual sample IDs should be in the first column named group. Give group designation the alternative name: sample_type

#Import shared file for all samples:
#Note: check for sub.sample version in data/mothur make sure that is the output from sub.sample
shared <- read_tsv("data/mothur/cdi.opti_mcc.0.03.subsample.shared", col_types=cols(Group=col_character())) %>%
  left_join(design, by = c("Group" = "group")) %>% #Join to the design file
  filter(!Group %in% contam_samples) #Remove 2 contaminated samples from analysi

#Function to narrow down design & shared files to just the 2 groups of interest for the 3 sets of binary comparisons
#sample_type1, sample_type2 = names of the 2 sample types to be compared. Needs to be in quotes
#file_prefix = name to denote group comparison, will appear before .design and .shared files. Needs to be in quotes
subset_shared <- function(sample_type1, sample_type2, file_prefix){
  subset_shared <- shared %>% 
    filter(sample_type %in% c(sample_type1, sample_type2)) #Select only rows that are of the 2 sample types specified
  design <- subset_shared %>% 
    select(Group, sample_type) %>% #Only these columns needed for design file
    rename(group = Group) %>%  #According to mothur wiki, the group column in the design file should be lower case
    write_tsv(paste0("data/process/", file_prefix, ".design")) #Output as tsv file
  final_shared <- subset_shared %>% 
    select(-sample_type) %>% #This column is not needed for shared file
    write_tsv(paste0("data/process/", file_prefix, ".shared")) #Output as tsv file
}

#Create design & shared files for the 3 comparisons----

#Case v Diarrheal control
subset_shared("case", "diarrheal_control", "CvDC")
#Case v Nondiarrheal control
subset_shared("case", "nondiarrheal_control", "CvNDC")
#Diarrheal v Nondiarrheal control
subset_shared("diarrheal_control", "nondiarrheal_control", "DCvNDC")
