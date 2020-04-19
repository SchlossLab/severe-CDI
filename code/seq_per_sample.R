# mothur "#count.groups with data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.denovo.vsearch.pick.pick.pick.count_table as input
# plot number of samples that have less than 1000, 1500, 5000, 10000 samples to determine the number of samples we want to resequence

data <- read_tsv("data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.denovo.vsearch.pick.pick.pick.count.summary", col_names=c("sample", "nseqs")) %>% 
  filter(!str_detect(sample, "water")) %>% #Remove water control samples
  filter(!str_detect(sample, "mock")) %>% #Remove mock samples
  filter(!str_detect(sample, "PBS")) #Remove PBS aliquot samples

#Total # of samples
data %>% count(sample)

data %>% ggplot(aes(x=nseqs)) + geom_histogram()
data %>% ggplot(aes(x=nseqs)) + geom_histogram() + scale_x_log10()

data %>% select(sample, nseqs) %>% filter(nseqs < 1000) %>% count(sample)


#If I rarefy to 1000:
data %>% filter(nseqs < 1000) %>% arrange(sample) %>% count(sample)
#I'll lose  samples.

#If I rarefy to 1500:
data %>% filter(nseqs < 1500) %>% arrange(sample) %>% count(sample)
#I'll lose  samples.

#If I rarefy to 5000:
data %>% filter(nseqs < 5000) %>% arrange(sample) %>% count(sample) 
#I'll lose  samples.

#If I rarefy to 10000:
data %>% filter(nseqs < 10000) %>% arrange(sample) %>% count(sample)
#I'll lose  samples.
