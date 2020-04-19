library(tidyverse)
# mothur "#count.groups with data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.denovo.vsearch.pick.pick.pick.count_table as input
# plot number of samples that have less than 1000, 1500, 5000, 10000 samples to determine the number of samples we want to resequence

data <- read_tsv("data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.denovo.vsearch.pick.pick.pick.count.summary", col_names=c("sample", "nseqs")) %>% 
  filter(!str_detect(sample, "water")) %>% #Remove water control samples
  filter(!str_detect(sample, "mock")) %>% #Remove mock samples
  filter(!str_detect(sample, "PBS")) #Remove PBS aliquot samples

#Total # of samples
total <- data %>% count(sample)

data %>% ggplot(aes(x=nseqs)) + geom_histogram()
data %>% ggplot(aes(x=nseqs)) + geom_histogram() + scale_x_log10()

data %>% select(sample, nseqs) %>% filter(nseqs < 1000) %>% count(sample)


#If I rarefy to 1000:
total_1000 <- data %>% filter(nseqs < 1000) %>% arrange(sample) %>% count(sample)
n_1000 = total- total_1000 
#I'll lose  samples.

#If I rarefy to 1500:
total_1500 <- data %>% filter(nseqs < 1500) %>% arrange(sample) %>% count(sample)
n_1500 = total- total_1500 
#I'll lose  samples.

#If I rarefy to 5000:
total_5000 <- data %>% filter(nseqs < 5000) %>% arrange(sample) %>% count(sample) 
n_5000 = total- total_5000 
#I'll lose  samples.

#If I rarefy to 10000:
total_10000 <- data %>% filter(nseqs < 10000) %>% arrange(sample) %>% count(sample)
n_10000 = total- total_10000 
#I'll lose  samples.

# Data frame of samples lost depending on sequences per sample cutoff
data_lost <- tibble("nseq" = c(1000, 1500, 5000, 10000), "n_samples_lost" = c(n_1000, n_1500, n_5000, n_10000))

#Plot visualizing number of samples to be resequenced depending on the cutoff chosen for number of sequences per sample chosen
data_lost_plot <- data_lost %>% 
  ggplot(aes(x=nseq, y= n_samples_lost))+
  geom_bar(stat = "identity")+
  labs(title=NULL,
     x="Minimum Number of Sequences Per Sample",
     y= "Number of Samples to Resequence")+
  theme_classic()+
  ggsave("exploratory/notebook/resequencing_cutoff.pdf")
