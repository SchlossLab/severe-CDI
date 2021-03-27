source("code/utilities.R") #Loads libraries, reads in metadata, functions

set.seed(19760620) #Same seed used for mothur analysis

#Goal is to create shared & design files for our 3 sets of binary comparisons
#These files will be used as input files for mothurs implementation of lefse (modeled after the LEfSe program from the Huttenhower lab)
#Citation for lefse: https://genomebiology.biomedcentral.com/articles/10.1186/gb-2011-12-6-r60

#Lefse analysis based on IDSA severity scores----
idsa_severity <- read_csv("data/process/case_idsa_severity.csv")

#Narrow down metadata to samples with IDSA severity status and selectonly the columns needed for lefse (sample and idsa_severity)
design <- metadata %>% 
  right_join(idsa_severity, by = "sample") %>% 
  select(sample, idsa_severity) %>% 
  rename(sample_type = idsa_severity, group = sample)  #For design file the individual sample IDs should be in the first column named group. Give group designation the alternative name: sample_type

#Import shared file for all samples and join to IDSA design:
#Note: check for sub.sample version in data/mothur make sure that is the output from sub.sample
shared <- read_tsv("data/mothur/cdi.opti_mcc.0.03.subsample.shared", col_types=cols(Group=col_character())) %>%
  left_join(design, by = c("Group" = "group")) %>% #Join to the design file
  filter(!Group %in% contam_samples) %>%  #Remove 2 contaminated samples from analysis
  select(-sample_type) %>% #This column is not needed for shared file
  write_tsv(paste0("data/process/idsa.shared")) #Output as tsv file

#Create final IDSA design file: 
final_design <- shared %>% 
  select(Group, sample_type) %>% #Only these columns needed for design file
  rename(group = Group) %>%  #According to mothur wiki, the group column in the design file should be lower case
  write_tsv(paste0("data/process/idsa.design")) #Output as tsv file

