library(tidyverse)
library(readxl)
# mothur "#count.groups with data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.denovo.vsearch.pick.pick.pick.count_table as input
# plot number of samples that have less than 1000, 1500, 5000, 10000 samples to determine the number of samples we want to resequence

planned_samples <- read_excel(path = "data/raw/cdi_sample_list_for_16S_plates.xlsx") %>%
  mutate(sample = `CDIS_Sample ID`) %>%
  select(sample, `CDIS_Aliquot ID`)

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
  filter(!str_detect(sample, "PBS")) #Removes 3 PBS aliquot samples

#Samples
missing_data_samples <- anti_join(planned_samples, data) #KR00245P, KR00442, KR01434, KR01457, KR01469, KR01481, KR01493, KR01505, KR01445
missing_planned_samples <- anti_join(data, planned_samples) #KR00245, KR00442M1, KR01437M12 (duplicate)
#9 observations, 2 of which are just label mismatches (for whatever reason my pattern matching to rename those 2 files didn't work)
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
