library(tidyverse)
library(readxl)
# mothur "#count.groups with data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.denovo.vsearch.pick.pick.pick.count_table as input
# plot number of samples that have less than 1000, 1500, 5000, 10000 samples to determine the number of samples we want to resequence

planned_samples <- read_excel(path = "data/raw/cdi_sample_list_for_16S_plates.xlsx") %>%
  mutate(sample = `CDIS_Sample ID`) %>%
  select(sample, `CDIS_Aliquot ID`) %>% 
#Correct label typo
  mutate(sample = replace(sample, sample == "KR00245P", "KR00245"))  

raw_data <- read_tsv("data/raw/cdi.files", col_names=c("sample", "read_1", "read_2"))
#4019 samples
#39 mock controls
#40 water controls
#3 PBS aliquot controls
#3937 KR# samples. Includes the 2 entries for KR01437, which was duplicated
#Means there are 7 samples that were not sequenced.

data <- read_tsv("data/process/cdi.trim.contigs.good.unique.good.filter.unique.precluster.denovo.vsearch.pick.pick.pick.count.summary", col_names=c("sample", "nseqs")) %>% #3980 samples
  filter(!str_detect(sample, "water")) %>% #Removes 40 water control samples
  filter(!str_detect(sample, "mock")) %>% #Makes sure mock samples were removed
  filter(!str_detect(sample, "PBS")) %>%#Removes 3 PBS aliquot samples 
  #Correct label error, not sure why my pattern matching missed this sample
  mutate(sample = replace(sample, sample == "KR00442M1", "KR00442")) %>% 
  #Remove duplicate of KR01437, this well should have been left empty
  filter(!sample == "KR01437M12")

#Samples
missing_data_samples <- anti_join(planned_samples, data) %>% select(sample) #KR01434, KR01457, KR01469, KR01481, KR01493, KR01505, KR01445
missing_planned_samples <- anti_join(data, planned_samples) #None
#9 observations, 
# 7 missing samples: KR01434, KR01457, KR01469, KR01481, KR01493, KR01505, KR01445.
#All 7 missing samples are from plate_20, column 12.
#No note about anything happening to these missing samples in the plate_layout file from Lucas
#Made a note when I was transferring files that water4 control (for plate_20) was also missing.
#Rechecked raw data folder in miseq_runs and all 7 sets of fastq.gz files are also missing.
#Also the samples are not listed on the SampleSheet.csv in the raw data folder of fastq.gz files
#Checked with Lucas and the sequences are likely still on the MiSeq, sample sheet just wasn't completely copied over. Once we're back in lab, Lucas will check. I can then run the 7 samples through mothur and determine whether any need to be resequenced based on the number of sequences per sample. Once all samples are resequenced, we will run all samples through motur again.


#Total # of samples
total <- data %>% count(sample)
#3937 samples, means 6 samples already lost...Check which samples these are later

data %>% ggplot(aes(x=nseqs)) + geom_histogram()

data %>% ggplot(aes(x=nseqs)) + geom_histogram() + scale_x_log10() +
  ggsave("exploratory/notebook/seq_per_sample_distribution.pdf")

data %>% select(sample, nseqs) %>% filter(nseqs < 1000) %>% count(sample)

#If I rarefy to 1000:
n_1000 <- data %>% filter(nseqs < 1000) %>% select(sample) %>% nrow()
#I'll lose 129 samples.

#If I rarefy to 1500:
n_1500 <- data %>% filter(nseqs < 1500) %>% select(sample) %>% nrow()
#I'll lose 156 samples.

#If I rarefy to 4000:
n_4000 <- data %>% filter(nseqs < 4000) %>% select(sample) %>% nrow()
#I'll lose 293 samples.

#If I rarefy to 5000:
n_5000 <- data %>% filter(nseqs < 5000) %>% select(sample) %>% nrow()
#I'll lose 378 samples.

#If I rarefy to 10000:
n_10000 <- data %>% filter(nseqs < 10000) %>% select(sample) %>% nrow()
#I'll lose 847 samples.

# Data frame of samples lost depending on sequences per sample cutoff
data_lost <- tibble("nseq" = c(1000, 1500, 4000, 5000, 10000), "n_samples_lost" = c(n_1000, n_1500, n_4000, n_5000, n_10000))

#Plot visualizing number of samples to be resequenced depending on the cutoff chosen for number of sequences per sample chosen
data_lost_plot <- data_lost %>%
  mutate(n_samples_lost = n_samples_lost+7) %>% #Add the 7 samples that were not sequenced. Check identities and reason by going through 16S sequencing excel file notes later.
  ggplot(aes(x=nseq, y= n_samples_lost))+
  geom_bar(stat = "identity")+
  labs(title=NULL,
     x="Minimum Number of Sequences Per Sample",
     y= "Number of Samples to Resequence")+
  theme_classic()+
  ggsave("exploratory/notebook/resequencing_cutoff.pdf")

#After discussing Pat, we've decided it'd be worthwhile to resequence 1 library of samples (382, plus ideally at least 1 mock and 1 water control).
# So we will aim for 5000 sequences per sample and resequence anything that falls below that cutoff
resequence_samples <- data %>% filter(nseqs < 5000)

#Export list of samples to resequence and there corresponding number of sequences
resequence_samples %>% 
  write_tsv("data/process/resequence_samples_CDI_16S")

#List of samples from plate_20 with missing data, likely still on the MiSeq
missing_data_samples %>% 
  write_tsv("data/process/plate20_missing_samples")

#Lucas found the missing fastqs on the Miseq and shared them with me on 6/11/20.
#I uploaded the missing fastq.gz files to the corresponding library on the Miseq_runs folder of the lab's turbo storage
#I ran the 7 samples through mothur locally to determine number of sequences per sample. Using the code/missing_get_good_seqs_shared_otus.batch file
missing_data <- read_tsv("data/test_mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.denovo.vsearch.pick.pick.count.summary", col_names=c("sample", "nseqs")) #3980 samples

#Check if any samples have < 5000 sequences
n_5000_missing <- missing_data %>% filter(nseqs < 5000) %>% select(sample) %>% nrow()
#0 of these samples need to be resequenced.