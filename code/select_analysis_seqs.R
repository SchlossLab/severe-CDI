library(tidyverse)
library(readxl)
library(writexl)

#Select 1 pair of sequences for all CDI samples for analysis. Make sure all water and mock controls plus 3 PBS aliquots are included in the analysis.
#Choose run that yielded the most sequences per sample.

#Initial sequencing runs for all 3,943 samples:
initial_runs <- read_tsv("data/process/cdi.trim.contigs.good.unique.good.filter.unique.precluster.denovo.vsearch.pick.pick.pick.count.summary", col_names=c("sample", "nseqs")) %>% #3980 samples
  rename(initial_nseqs = nseqs) %>% 
  filter(!sample == "KR01437M12")  #Drop this sample. KR01437 is a duplicate and will be removed before running mothur again (well should have been left empty). 
  
#Sequences that were initially missing from initial sequencing runs. They weren't transferred over from the MiSeq because of a pasting error but were sequenced with the above samples:
missing_7 <- read_tsv("data/test_mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.denovo.vsearch.pick.pick.count.summary", col_names=c("sample", "nseqs")) %>% 
  rename(initial_missing_nseqs = nseqs)

#Library of resequenced samples (note this library was sequenced twice, due to a MiSeq clustering error during the first run. We will only utilize sequencing data from the 2nd run)
reseq_run_repeat <- read_tsv("data/reseq_repeat_mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.denovo.vsearch.pick.pick.count.summary", col_names=c("sample", "nseqs")) %>% 
  rename(reseq_run_repeat_nseqs = nseqs)

# plate_52 resequenced samples:
plate52_data <- read_tsv("data/plate52_mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.denovo.vsearch.pick.pick.count.summary", col_names=c("sample", "nseqs")) %>% 
  rename(plate52_nseqs = nseqs)

# plate_53 resequenced samples:
plate53_data <- read_tsv("data/plate53_mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.denovo.vsearch.pick.pick.count.summary", col_names=c("sample", "nseqs")) %>% 
  rename(plate53_nseqs = nseqs) %>% 
  #drop samples that are duplicates mentioned above. These samples already had enough sequences per samples from a previous run
  filter(!sample == "KR03652v2") %>% 
  filter(!sample == "KR01326v2") %>%
  filter(!sample == "KR00655v2")
  

#Combine dataframes of all sequenced samples including resequenced samples:----
all_seq_data <- full_join(initial_runs, missing_7, by = "sample") %>% 
  full_join(reseq_run_repeat, by = "sample") %>% 
  full_join(plate52_data, by = "sample") %>% 
  full_join(plate53_data, by = "sample")
# 4000 samples total (includes 5 mocks, 45 water controls, and 3 PBS aliquot controls).

#Figure out which sequencing runs yielded the most sequences for each sample:----
best_seq_data <- all_seq_data %>% 
  pivot_longer(cols = c("initial_nseqs", "initial_missing_nseqs", "reseq_run_repeat_nseqs", "plate52_nseqs", "plate53_nseqs"), 
             names_to = "best_miseq_run", values_to = "nseqs") %>% 
  #Figure out which run yielded the largest number of sequences for each sample:
  group_by(sample) %>% 
  filter(!is.na(nseqs)) %>% #drop rows with NAs (not all samples were sequenced multiple times)
  filter(nseqs == max(nseqs)) %>% 
  arrange(sample) 
#Outputs a data frame listing the sample, the best sequencing run, and the number of sequences from the best sequencing run

#Check how many CDI samples fall below 5000 seqs per sample cutoff:
best_seq_data %>% 
  filter(!str_detect(sample, "water")) %>% #Removes 40 water control samples
  filter(!str_detect(sample, "mock")) %>% #Makes sure mock samples were removed
  filter(!str_detect(sample, "PBS")) %>%#Removes 3 PBS aliquot samples 
  filter(nseqs < 5000) 
# 11 samples with less than 5000 sequences

#Organizing files that will be used from initial sequencing run (currently in data/raw)----
best_initial_run <- best_seq_data %>% 
  filter(best_miseq_run == "initial_nseqs")

#Samples that were successfully resequenced to remove from data/raw. These files will be replaced with files generated from the resequencing runs
remove_initial_run_files <- initial_runs %>% 
  anti_join(best_initial_run, by = "sample") %>% 
  #Add columns to use pattern matching to remove these samples with a for loop from the command line
  mutate(grep_prefix = "'^", # ^ indicates the start of a string
         grep_suffix = "_.*'") %>%  #Add columns to construct regexp to remove these sequences from the project data/raw folder to exclude contaminated samples from 16S gene rRNA sequencing analysis. . in _.* is to avoid matching to files that don't have an underscore after pattern is matched
  unite(col = "grep_name", grep_prefix, sample, grep_suffix, sep = "", remove = TRUE) %>% #merge the 3 columns into 1 column to create the bash commands
  pull(grep_name) %>%
  noquote
# print all rows, use this list with for loop from the command line to remove these sequence files
paste(remove_initial_run_files, sep =" \n", collapse = " ") 

#Samples that were initially missing from initial sequencing run data----
best_missing <- best_seq_data %>% 
  filter(best_miseq_run == "initial_missing_nseqs")
#7 samples
#Note these samples have already been transferred to data/raw

#Samples from reseq_run_repeat that need to be copied into data/raw----
best_reseq_run_repeat <- best_seq_data %>% 
  filter(best_miseq_run == "reseq_run_repeat_nseqs")
#288 samples

#Remove the following samples from reseq_run_repeat raw data folder from the command line with a for loop
remove_reseq_run_repeat_files <- reseq_run_repeat %>% 
  anti_join(best_reseq_run_repeat, by = "sample") %>% 
  #Add columns to use pattern matching to remove these samples with a for loop from the command line
  mutate(grep_prefix = "'^", # ^ indicates the start of a string
         grep_suffix = "_.*'") %>%  #Add columns to construct regexp to remove these sequences from the project data/raw folder to exclude contaminated samples from 16S gene rRNA sequencing analysis. . in _.* is to avoid matching to files that don't have an underscore after pattern is matched
  unite(col = "grep_name", grep_prefix, sample, grep_suffix, sep = "", remove = TRUE) %>% #merge the 3 columns into 1 column to create the bash commands
  pull(grep_name) %>%
  noquote
# print all rows, use this list with for loop from the command line to remove these sequence files
paste(remove_reseq_run_repeat_files, sep =" \n", collapse = " ") 

#Samples from plate52 that need to be copied into data/raw----
best_plate52 <- best_seq_data %>% 
  filter(best_miseq_run == "plate52_nseqs")

#Remove the following samples from plate52_raw data folder from the command line with a for loop
remove_plate52_files <- plate52_data %>% 
  anti_join(best_plate52, by = "sample") %>% 
  #Add columns to use pattern matching to remove these samples with a for loop from the command line
  mutate(grep_prefix = "'^", # ^ indicates the start of a string
         grep_suffix = "_.*'") %>%  #Add columns to construct regexp to remove these sequences from the project data/raw folder to exclude contaminated samples from 16S gene rRNA sequencing analysis. . in _.* is to avoid matching to files that don't have an underscore after pattern is matched
  unite(col = "grep_name", grep_prefix, sample, grep_suffix, sep = "", remove = TRUE) %>% #merge the 3 columns into 1 column to create the bash commands
  pull(grep_name) %>%
  noquote
# print all rows, use this list with for loop from the command line to remove these sequence files
paste(remove_plate52_files, sep =" \n", collapse = " ") 

#Samples from plate53 that need to be copied into data/raw----
best_plate53 <- best_seq_data %>% 
  filter(best_miseq_run == "plate53_nseqs")

#Remove the following samples from plate53_raw data folder from the command line with a for loop
remove_plate53_files <- plate53_data %>% 
  anti_join(best_plate53, by = "sample") %>% 
  #Add columns to use pattern matching to remove these samples with a for loop from the command line
  mutate(grep_prefix = "'^", # ^ indicates the start of a string
         grep_suffix = "_.*'") %>%  #Add columns to construct regexp to remove these sequences from the project data/raw folder to exclude contaminated samples from 16S gene rRNA sequencing analysis. . in _.* is to avoid matching to files that don't have an underscore after pattern is matched
  unite(col = "grep_name", grep_prefix, sample, grep_suffix, sep = "", remove = TRUE) %>% #merge the 3 columns into 1 column to create the bash commands
  pull(grep_name) %>%
  noquote
# print all rows, use this list with for loop from the command line to remove these sequence files
paste(remove_plate53_files, sep =" \n", collapse = " ") 

#Read in .files output to get a list of mock samples from all sequencing runs-----
cdi.files <- read_tsv("data/raw/cdi.files", col_names=c("sample", "read_1", "read_2")) #no columns in .files format

#Check how many samples after excluding water, mock and PBS controls
cdi.files %>% 
  filter(!str_detect(sample, "water")) %>% #Removes 40 water control samples
  filter(!str_detect(sample, "mock")) %>% #Makes sure mock samples were removed
  filter(!str_detect(sample, "PBS")) #Removes 3 PBS aliquot samples 
#3943 samples, as expected

#Generate a string of mock samples to use as input for mothur get_error.batch script for getting the sequencing error rate----
mock_sample_list <- cdi.files %>% 
  filter(str_detect(sample, "mock")) %>% 
  pull(sample) %>% 
  noquote() %>% #Remove quotations from the characters
  paste(., collapse = "-")
#Paste this list of mock samples into get_error.batch and get_good_seqs_shared_otus.batch for the group = arguments
