library(tidyverse)
library(readxl)
library(writexl)
# mothur "#count.groups with data/test_mothur2/cdi.trim.contigs.good.unique.good.filter.unique.precluster.denovo.vsearch.pick.pick.pick.count_table as input
# plot number of samples that have less than 1000, 1500, 5000, 10000 samples to determine the number of samples we want to resequence

#List of samples to resequence:
reseq <- read_tsv("data/process/resequence_samples_CDI_16S")
#378 samples

#Plate numbers and locations of samples to resequence:
planned_samples <- read_excel(path = "data/raw/reseq_Sysdiff_plate48_51.xlsx") %>% 
  select(nseqs, sample, reseq_plate, reseq_plate_location, dna_conc, new_DNA_extracted, `CDIS_Aliquot ID`) %>% 
  rename(initial_nseqs = nseqs) #rename this column to reflect the number of sequences when each of the resequenced samples were initially sequenced

#7/2/20 MiSeq Run of resequenced sample library: Sequences per sample data
reseq_data <- read_tsv("data/test_mothur2/cdi.trim.contigs.good.unique.good.filter.unique.precluster.denovo.vsearch.pick.pick.count.summary", col_names=c("sample", "nseqs")) %>% 
  filter(!str_detect(sample, "water")) %>% #Removes water control samples
  filter(!str_detect(sample, "mock")) #Makes sure mock samples were removed
#375 samples, so 3 missing

missing <- anti_join(planned_samples, reseq_data, by = "sample")
#KR02027, KR03647, KR03798. All of which were on the sample sheet for the library
#Check the mothur log file for these sequences:
#KR02027 had only had 19 sequences 
#KR03647 had only 6 sequences
#KR03798 had only 9 sequences

#Check mock sequences:
#mock 48 had 17, mock51 had 39246, mock 51b had 10552
#Overall error rate: 0.000277196 from get_error.batch
# .02% sequencing errors

#Total # of samples
total <- reseq_data %>% count(sample)

reseq_data %>% ggplot(aes(x=nseqs)) + geom_histogram()

reseq_data %>% ggplot(aes(x=nseqs)) + geom_histogram() + scale_x_log10(limits = c(-1, 100000)) +
  ggsave("exploratory/notebook/reseq_seq_per_sample_distribution.pdf")

reseq_data %>% select(sample, nseqs) %>% filter(nseqs < 1000) %>% count(sample)

#If I rarefy to 1000:
n_1000 <- reseq_data %>% filter(nseqs < 1000) %>% select(sample) %>% nrow()+3 #Account for 3 samples that were dropped from table (<20 sequences)
#I'll lose 102 samples.

#If I rarefy to 1500:
n_1500 <- reseq_data %>% filter(nseqs < 1500) %>% select(sample) %>% nrow()+3
#I'll lose 121 samples.

#If I rarefy to 4000:
n_4000 <- reseq_data %>% filter(nseqs < 4000) %>% select(sample) %>% nrow()+3 #Account for 3 samples that were dropped from table (<20 sequences)
#I'll lose 241 samples.

#If I rarefy to 5000:
n_5000 <- reseq_data %>% filter(nseqs < 5000) %>% select(sample) %>% nrow()+3 #Account for 3 samples that were dropped from table (<20 sequences)
#I'll lose 275 samples.

#See if there are any patterns to the samples that had a low number of sequences:
reseq_data <- full_join(reseq_data, planned_samples, by = "sample")

less_1000_locations <- reseq_data %>% filter(nseqs < 1000) %>%
  count(reseq_plate)

less_5000_locations <- reseq_data %>% filter(nseqs < 5000) %>%
  count(reseq_plate)

less_5000_plate_locations <- reseq_data %>% filter(nseqs < 5000) %>%
  count(reseq_plate_location)

less_5000_new_DNA <- reseq_data %>% filter(nseqs < 5000) %>%
  count(new_DNA_extracted)

new_DNA <- reseq_data %>%
  count(new_DNA_extracted)

#7/17/20 Repeat MiSeq Run of resequenced sample library: Sequences per sample data
# 7/2/20 Run had a MiSeq error so Illumina sent a service tech to fix MiSeq and a replacement kit to replace the library.
repeat_run_reseq_data <- read_tsv("data/reseq_repeat_mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.denovo.vsearch.pick.pick.count.summary", col_names=c("sample", "nseqs")) %>% 
  filter(!str_detect(sample, "water")) %>% #Removes water control samples
  filter(!str_detect(sample, "mock")) #Makes sure mock samples were removed
#378 samples

missing <- anti_join(planned_samples, repeat_run_reseq_data, by = "sample")
#0 samples missing

#Check mock sequences:
#mock 48 had 23, mock51 had 52021, mock 51b had 36235
#Overall error rate:  from get_error.batch


#Total # of samples
total <- repeat_run_reseq_data %>% count(sample)

repeat_run_reseq_data %>% ggplot(aes(x=nseqs)) + geom_histogram()

repeat_run_reseq_data %>% ggplot(aes(x=nseqs)) + geom_histogram() + scale_x_log10(limits = c(-1, 100000)) +
  ggsave("exploratory/notebook/reseq_seq_per_sample_distribution.pdf")

repeat_run_reseq_data %>% select(sample, nseqs) %>% filter(nseqs < 1000) %>% count(sample)

#If I rarefy to 1000:
n_1000 <- repeat_run_reseq_data %>% filter(nseqs < 1000) %>% select(sample) %>% nrow()
#I'll lose 46 samples.

#If I rarefy to 1500:
n_1500 <- repeat_run_reseq_data %>% filter(nseqs < 1500) %>% select(sample) %>% nrow()
#I'll lose 52 samples.

#If I rarefy to 4000:
n_4000 <- repeat_run_reseq_data %>% filter(nseqs < 4000) %>% select(sample) %>% nrow()
#I'll lose 87 samples.

#If I rarefy to 5000:
n_5000 <- repeat_run_reseq_data %>% filter(nseqs < 5000) %>% select(sample) %>% nrow()
#I'll lose 97 samples.

#See if there are any patterns to the samples that had a low number of sequences:
repeat_run_reseq_data <- full_join(repeat_run_reseq_data, planned_samples, by = "sample")

less_5000_locations <- repeat_run_reseq_data %>% filter(nseqs < 5000) %>%
  count(reseq_plate)

less_5000_plate_locations <- repeat_run_reseq_data %>% filter(nseqs < 5000) %>%
  count(reseq_plate_location)

less_5000_new_DNA <- repeat_run_reseq_data %>% filter(nseqs < 5000) %>%
  count(new_DNA_extracted)

#Join the planned_samples, reseq_data, and repeat_run_reseq_data together by sample
#Sum up how many total sequences we have per sample if we combine the data from the initial Miseq runs and the 2 runs of resequenced sample libraries:
reseq_data <- reseq_data %>% 
  rename(reseq_nseqs = nseqs) %>% #rename nseqs column to correspond to sequencing run
  select(sample, reseq_nseqs)
repeat_run_reseq_data <- repeat_run_reseq_data %>% 
  rename(repeat_reseq_nseqs = nseqs) %>% 
  select(sample, repeat_reseq_nseqs)

combined_miseq_runs <- full_join(planned_samples, reseq_data, by = "sample")
combined_miseq_runs <- full_join(combined_miseq_runs, repeat_run_reseq_data, by = "sample") %>% 
#Make a new column that totals number of sequences from intial MiSeq run, 1st run of resequencing library, and 2nd run of resequencing library
  mutate(total_nseqs = initial_nseqs + reseq_nseqs + repeat_reseq_nseqs)

#Number of samples with < 5000 after combining all sequence data for each sample:
#If I rarefy to 5000:
n_5000 <- combined_miseq_runs %>% filter(total_nseqs < 5000) %>% select(sample) %>% nrow()
#I'll lose 60 samples.

#List of samples with < 5000 sequences
below_5000 <- combined_miseq_runs %>% filter(total_nseqs < 5000) %>% 
  group_by(new_DNA_extracted) %>% count(n)
#2/6 M2 aliquots had M3 aliquot extracted. Could try resequencing from 3rd aliquot DNA
#Reextract 58 samples + reamplify 2/6 M2 above (KR00249 and KR03044_M2). 
#Hopefully DNA extraction will work better if less sample is aliquoted into DNA extraction plates. (Based on info Lucas got from rep, columns were likely being overloaded) 

#Make another column that combines sequences from just the initial run and the repeat run of the resequencing library
combined_miseq_runs_2runs <- combined_miseq_runs %>% 
  mutate(initial_and_repeat_nseqs = initial_nseqs + repeat_reseq_nseqs) %>% 
  filter(initial_and_repeat_nseqs < 5000)
#70 samples, 2 had M2 aliquot extracted.

below_5000_combined_miseq_runs_2runs <- combined_miseq_runs %>% 
  mutate(initial_and_repeat_nseqs = initial_nseqs + repeat_reseq_nseqs) %>% 
  filter(repeat_reseq_nseqs < 5000)


#Export list of samples to reextract/resequence and there corresponding number of sequences----
#This list will be plate_52 for the CDI clinical samples 16S plates
plate_52_unsorted <- below_5000_combined_miseq_runs_2runs %>% 
  select(new_DNA_extracted, `CDIS_Aliquot ID`, sample, reseq_plate, reseq_plate_location, initial_nseqs, reseq_nseqs, repeat_reseq_nseqs, initial_and_repeat_nseqs, total_nseqs) %>% 
  filter(repeat_reseq_nseqs < 5000) %>% 
#Remove 3 samples so that plate_52 will consist of 94 samples, 1 water control, and 1 mock
  filter(sample != "KR00842" & sample != "KR00468" & sample != "KR01111") #Chose samples that had at least 5000 sequences when initial sequencing run and repeat resequencing run sequences were combined. Also chose these because they had at least >4800 sequences from the initial sequencing run

#2 samples have no more aliquots to reextract. We will move these samples to the last 2 wells of the plate.
reuse_prev_DNA <- plate_52_unsorted %>% 
  filter(str_detect(`CDIS_Aliquot ID`, "M2") & new_DNA_extracted == "yes") %>% #The 3rd microbiome aliquot was already used for these 2 samples
  arrange(sample) %>% #Arrange by sample which were assigned chronologically 
  mutate(additional_DNA_extraction = "no") #Add a column to specify whether new DNA will be extracted
#Attempt to amplify the previously extracted DNA (resequencing library with new extracted DNA) for these 2 samples

#Remaining 92 samples will have new DNA extracted:
extract_new_DNA <- plate_52_unsorted %>% 
  anti_join(reuse_prev_DNA, by = "sample") %>% 
  arrange(sample) %>% #Arrange by sample which were assigned chronologically  
  mutate(additional_DNA_extraction = "yes") #Add a column to specify whether new DNA will be extracted

#Plate_52 final arrangement to export----
plate_52 <- rbind(extract_new_DNA, reuse_prev_DNA) %>% 
  write_tsv("data/process/resequence_plate52_CDI_16S")

#Sequences per sample for plate_52 sequencing data (completed 8/13/20)----
plate52_data <- read_tsv("data/plate52_mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.denovo.vsearch.pick.pick.count.summary", col_names=c("sample", "nseqs")) %>% 
  filter(!str_detect(sample, "water")) %>% #Removes water control samples
  filter(!str_detect(sample, "mock")) #Makes sure mock samples were removed
#378 samples

plate52_data %>% ggplot(aes(x=nseqs)) + geom_histogram()

plate52_data %>% ggplot(aes(x=nseqs)) + geom_histogram() + scale_x_log10(limits = c(-1, 100000)) +
  ggsave("exploratory/notebook/plate52_seq_per_sample_distribution.pdf")

plate52_data %>% select(sample, nseqs) %>% filter(nseqs < 1000) %>% count(sample)
#17 samples with < 1000 sequences

#If I rarefy to 1000:
n_1000 <- plate52_data %>% filter(nseqs < 1000) %>% select(sample) %>% nrow()
#I'll lose 17 samples.

#If I rarefy to 1500:
n_1500 <- plate52_data %>% filter(nseqs < 1500) %>% select(sample) %>% nrow()
#I'll lose 25 samples.

#If I rarefy to 4000:
n_4000 <- plate52_data %>% filter(nseqs < 4000) %>% select(sample) %>% nrow()
#I'll lose 41 samples.

#If I rarefy to 5000:
n_5000 <- plate52_data %>% filter(nseqs < 5000) %>% select(sample) %>% nrow()
#I'll lose 46 samples.

#Join the planned_samples, reseq_data, repeat_run_reseq_data, and plate52_data together by sample
#Sum up how many total sequences we have per sample if we combine the data from the initial Miseq runs and the 3 runs of resequenced sample libraries:
plate52_data <- plate52_data %>% 
  rename(plate52_nseqs = nseqs) %>% #rename nseqs column to correspond to sequencing run
  select(sample, plate52_nseqs) 

#Combine plate52_data with sequencing data per sample from initial runs and the other 2 resequencing runs
combined_reseq_runs <- full_join(combined_miseq_runs, plate52_data, by = "sample") %>% 
  select(-total_nseqs) %>% #remove previous total_nseqs column and replace with new column that incorporates plate52
  mutate(plate52_nseqs = replace_na(plate52_nseqs, 0)) %>%  #Replace nas with 0s so columns can be added together
  #Make a new column that totals number of sequences from initial MiSeq run, 1st run of resequencing library, and 2nd run of resequencing library
  mutate(total_nseqs = initial_nseqs + repeat_reseq_nseqs + plate52_nseqs)

#If we rarefy to 5000:
n_5000 <- combined_reseq_runs %>% filter(total_nseqs < 5000) %>% select(sample) %>% nrow()
#I'll lose 23 samples.

#Including the resequencing data from the MiSeq run that had a clustering error:
combined_reseq_runs_all <- combined_reseq_runs %>% 
  mutate(total_all_nseqs = initial_nseqs + reseq_nseqs + repeat_reseq_nseqs + plate52_nseqs)

#If we rarefy to 5000:
n_5000 <- combined_reseq_runs_all %>% filter(total_all_nseqs < 5000) %>% select(sample) %>% nrow()
#I'll lose 21 samples.

#Plate_52 samples with < 5000 sequences----
plate_52_below_5000 <- plate52_data %>% filter(plate52_nseqs < 5000) 

#Plate number and locations of plate_52 samples to (re)sequence:
planned_plate52_samples <- read_excel(path = "data/raw/CDI_plate_52_Motility_plates_11-13.xlsx") %>% 
  select(`CDIS_Sample ID`, reseq_plate, reseq_plate_location) %>% 
  rename(sample = `CDIS_Sample ID`) %>% #rename this column to reflect how sample id is labeled in plate_52_below_5000
  left_join((combined_reseq_runs %>% select(sample, total_nseqs)), by = "sample") #Join to combined_reseq_runs_all just to get tontal_nseqs column

#Join plate number and location info to plate_52_below_5000
plate_52_below_5000 <- plate_52_below_5000 %>% 
  left_join(planned_plate52_samples, by = "sample") %>% 
  write_xlsx(path = "data/process/plate52_CDI_below_5000.xlsx")
