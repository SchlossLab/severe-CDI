library(tidyverse)

#Load in shared file (has not been sub sampled)
#11 samples have less than 5000 sequences per sample despite several attempts at resequencing. 
#Includes 45 water controls and 3 PBS aliquots (all have < 5000 sequences and will be dropped after sub sampling to 5000 sequences)

shared <- read_tsv("data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.pick.opti_mcc.shared") %>% 
  select(-label, -numOtus) %>% 
  mutate(CDIS_Sample_ID= as.character(Group)) 
