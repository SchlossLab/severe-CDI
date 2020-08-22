#Determine whether it is feasible to combine sequences of the same sample from different MiSeq runs
#Check paired distances of same sample across runs and examine on PCoA

#Samples that were sequenced across multiple runs:
reseq_samples <- read_excel(path = "data/process/reseq_samples_seqs_by_run.xlsx")  

#Filter out samples that had at least 5000 sequences on 1 of the resequencing runs
samples_low_seq <- reseq_samples %>% 
  filter(repeat_reseq_nseqs < 5000) %>% 
  filter(plate52_nseqs < 5000) 
#49 samples that we would lose if we decide not to combine sequencing runs

#Number of samples we'd lose if we combine sequencing runs
samples_low_seq_after_combining <- reseq_samples %>% 
  filter(total_nseqs < 5000) 
#23 samples with < 5000 sequences if we combine sequencing runs

#List of samples to check if combining sequences across runs is feasible
samples_to_check <- samples_low_seq %>% 
  filter(total_nseqs > 5000) #Don't check the samples that still wouldn't make cut off despite combining across runs
#Process these 26 samples in mothur, see how they compare on PCoA and via Theta YC distances
#No # before KR# corresponds to initial MiSeq Run
#2 before KR# corresponds to repeat_reseq MiSeq Run
#3 before KR# corresponds to plate_52 MiSeq Run
#List of KR samples IDs without quotes
samples_to_check_ids <- samples_to_check %>% 
  pull(sample) %>% noquote()


