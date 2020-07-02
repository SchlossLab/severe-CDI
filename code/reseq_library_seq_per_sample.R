library(tidyverse)
library(readxl)
# mothur "#count.groups with data/test_mothur2/cdi.trim.contigs.good.unique.good.filter.unique.precluster.denovo.vsearch.pick.pick.pick.count_table as input
# plot number of samples that have less than 1000, 1500, 5000, 10000 samples to determine the number of samples we want to resequence

#List of samples to resequence:
reseq <- read_tsv("data/process/resequence_samples_CDI_16S")
#378 samples

data <- read_tsv("data/test_mothur2/cdi.trim.contigs.good.unique.good.filter.unique.precluster.denovo.vsearch.pick.pick.count.summary", col_names=c("sample", "nseqs")) %>% 
  filter(!str_detect(sample, "water")) %>% #Removes water control samples
  filter(!str_detect(sample, "mock")) #Makes sure mock samples were removed
#375 samples, so 3 missing

missing <- anti_join(reseq, data, by = "sample")
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
total <- data %>% count(sample)

data %>% ggplot(aes(x=nseqs)) + geom_histogram()

data %>% ggplot(aes(x=nseqs)) + geom_histogram() + scale_x_log10(limits = c(-1, 100000)) +
  ggsave("exploratory/notebook/reseq_seq_per_sample_distribution.pdf")

data %>% select(sample, nseqs) %>% filter(nseqs < 1000) %>% count(sample)

#If I rarefy to 1000:
n_1000 <- data %>% filter(nseqs < 1000) %>% select(sample) %>% nrow()+3 #Account for 3 samples that were dropped from table (<20 sequences)
#I'll lose 102 samples.

#If I rarefy to 1500:
n_1500 <- data %>% filter(nseqs < 1500) %>% select(sample) %>% nrow()+3
#I'll lose 121 samples.

#If I rarefy to 4000:
n_4000 <- data %>% filter(nseqs < 4000) %>% select(sample) %>% nrow()+3 #Account for 3 samples that were dropped from table (<20 sequences)
#I'll lose 241 samples.

#If I rarefy to 5000:
n_5000 <- data %>% filter(nseqs < 5000) %>% select(sample) %>% nrow()+3 #Account for 3 samples that were dropped from table (<20 sequences)
#I'll lose 275 samples.
