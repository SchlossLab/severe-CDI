library(tidyverse)
library(readxl)

final_counts <- read_tsv("data/process/final/cdi.trim.contigs.good.unique.good.filter.unique.precluster.denovo.vsearch.pick.pick.pick.count.summary", col_names=c("sample", "nseqs")) #3980 samples

#Check water controls
water_counts <- final_counts %>% 
  filter(str_detect(sample, "water")) %>% 
  filter(nseqs < 5000)
#45 water controls. All with < 5000 sequences
#Number of water controls with > 1000 sequences
water_1000 <- water_counts %>% 
  filter(nseqs > 1000)
# 3 water controls with > 1000 sequences (range: 1077-2632). Water controls from plates 14, 37, and 51.

#Check PBS controls (added to samples that were not initially able to pipette out of tube)
pbs_counts <- final_counts %>% 
  filter(str_detect(sample, "PBS")) %>% 
  filter(nseqs < 5000)
#3 PBS aliquots, all with < 1000 sequences (range: 108-725)


#Confirm sequences per sample
sample_counts <- final_counts %>% 
  filter(!str_detect(sample, "water")) %>%   
  filter(!str_detect(sample, "PBS")) 
#3943 samples total
sample_under_5000 <- sample_counts %>% 
  filter(nseqs < 5000) %>% 
  arrange(nseqs)
#11 samples with < 5000 sequences (range: 2453-4373). 
