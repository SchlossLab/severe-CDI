library(tidyverse)

#If we choose sequencing cutoff of 5000 sequences per sample, there will be 385 samples that need to be resequenced.
#This includes 7 samples that are currently missing from shared file, but the data for them are likely on the MiSeq.
#Sample IDs for the 7 missing samples (plate_20, column 12) # KR01434, KR01457, KR01469, KR01481, KR01493, KR01505, KR01445
#Lucas will check once labs are back open and then I will check to see how many sequences per sample there are for the 7 samples.

#Load in shared file
#A few sample names need to be corrected so that they will match their corresponding CDIS_Sample_ID
shared <- read_tsv("data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.pick.opti_mcc.shared") %>% 
  select(-label, -numOtus) %>% 
  mutate(CDIS_Sample_ID= as.character(Group)) 