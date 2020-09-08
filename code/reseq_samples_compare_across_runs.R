library(tidyverse)
library(readxl)
library(writexl)
library(cowplot)

#Determine whether it is feasible to combine sequences of the same sample from different MiSeq runs
#Check paired distances of same sample across runs and examine on PCoA

#Samples that were sequenced across multiple runs:
reseq_samples <- read_excel(path = "data/process/reseq_samples_seqs_by_run.xlsx")  

#Filter out samples that had at least 5000 sequences on 1 of the resequencing runs
samples_low_seq <- reseq_samples %>% 
  filter(repeat_reseq_nseqs < 5000) %>% 
  filter(plate52_nseqs < 5000) 
#49 samples that we would lose if we decide not to combine sequencing runs

#Examine whether it's worth changing threshold:
samples_low_seq_max <- samples_low_seq %>% 
  mutate(max_seqs_1_run = pmax(initial_nseqs, repeat_reseq_nseqs, plate52_nseqs)) #Make a new column that will take the max number of seq. from either the initial, repeat_reseq, or plate_52 miseq run and puts that max number os sequences into a new column

t_5000 <- samples_low_seq_max %>% filter(max_seqs_1_run < 5000) %>% count()
#49 samples below cutoff of 5000 sequences per sample
t_4000 <- samples_low_seq_max %>% filter(max_seqs_1_run < 4000) %>% count()
#34 samples below cutoff of 4000 sequences per sample
t_3000 <- samples_low_seq_max %>% filter(max_seqs_1_run < 3000) %>% count()
#26 samples below cutoff of 3000 sequences per sample
t_2000 <- samples_low_seq_max %>% filter(max_seqs_1_run < 2000) %>% count()
#13 samples below cutoff of 2000 sequences per sample
t_1000 <- samples_low_seq_max %>% filter(max_seqs_1_run < 1000) %>% count()
#5 samples below cutoff of 1000 sequences per sample


count(samples_low_seq %>% filter)
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

pcoa_data <- read_tsv("data/combine_test_mothur/cdi.opti_mcc.thetayc.0.03.lt.pcoa.axes") %>%
  select(group, axis1, axis2) %>% #Limit to 2 PCoA axes
  rename(sample = group) %>% 
  separate(sample, into = c("miseq_run", "sample"), remove = TRUE, sep = -7) %>% #Separate # at the beginning of sample run to differentiate miseq runs and move to own column
  mutate_all(na_if, "") %>% #Transform blanks to NAs
  mutate(miseq_run = replace_na(miseq_run, "1")) #Transform NAs to 1 to indicate these samples were from initial MiSeq runs
unique(pcoa_data$miseq_run)

plot_pcoa <- ggplot(pcoa_data, aes(x=axis1, y=axis2, color = sample, shape = miseq_run)) +
    geom_point(size=2) +
#    coord_fixed() + 
    labs(x="PCoA 1",
         y="PCoA 2",
         color= "Sample",
         shape = "Miseq Run") +
    theme_classic()

#Function to read in distance matrix:
read_dist_df <- function(dist_file_name){
  linear_data <- scan(dist_file_name, what="character", quiet=TRUE)[-1]
  
  samples <- str_subset(linear_data, "K") #Pull out sample ids with K, all samples have a K in sample id.
  n_samples <- length(samples)
  distance_strings <- str_subset(linear_data, "\\.")
  
  distance_matrix <- matrix(0, nrow=n_samples, ncol=n_samples)
  colnames(distance_matrix) <- samples
  as_tibble(cbind(rows=samples, distance_matrix)) %>%
    gather(columns, distances, -rows) %>%
    filter(rows < columns) %>%
    arrange(columns, rows) %>%
    mutate(distances = as.numeric(distance_strings))
}

#26 unique samples. Make a vector numbered 1:26 to use as a shorter way of identifying samples
short_sample_id = 1:26
#Df of sample and short_sample_id
short_sample_ids <- samples_to_check %>% 
  select(sample) %>% 
  cbind(short_sample_id)

all_dist <- read_dist_df("data/combine_test_mothur/cdi.opti_mcc.thetayc.0.03.lt.dist") %>% 
  separate(rows, into = c("row_miseq_run", "row_sample"), remove = TRUE, sep = -7) %>% #Separate # at the beginning of sample run to differentiate miseq runs and move to own column
  separate(columns, into = c("col_miseq_run", "col_sample"), remove = TRUE, sep = -7) %>% #Separate # at the beginning of sample run to differentiate miseq runs and move to own column
  mutate_all(na_if, "") %>% #Transform blanks to NAs
  mutate(row_miseq_run = replace_na(row_miseq_run, "1")) %>% #Transform NAs to 1 to indicate these samples were from initial MiSeq runs
  mutate(col_miseq_run = replace_na(col_miseq_run, "1")) %>% #Transform NAs to 1 to indicate these samples were from initial MiSeq runs
  filter(row_sample == col_sample) %>% #Just plot distances that compare a sample across runs
  unite(miseq_run_comp, c("row_miseq_run", "col_miseq_run"), remove = FALSE, sep = "vs") %>% 
  left_join(samples_to_check, by = c("row_sample" = "sample")) %>% 
  #rename nseqs per miseq run columns to match above number notations for each run (1 for intial, 2 for repeat_reseq, 3 for plate52)
  rename(nseqs_1 = initial_nseqs, 
        nseqs_2 =  repeat_reseq_nseqs,
        nseqs_3 = plate52_nseqs) %>% 
  select(-total_nseqs) %>% #Don't need the total number of sequences across all runs
  arrange(row_sample) %>% #Arrange row
  group_by(row_sample) %>% 
  left_join(short_sample_ids, by = c("row_sample" = "sample")) %>% #Add a new column with a shorter sample id to plot
  ungroup()
  
#Plot of theta yc distances

#Initial (col) vs reseq (row) run
i_vs_reseq <- all_dist %>% 
  filter(col_miseq_run == 1 & row_miseq_run == 2) %>% 
  ggplot(aes(x = row_sample, y = distances, color = row_sample)) +
  geom_jitter(size=2) +
#  scale_x_discrete(guide = guide_axis(n.dodge = 2))+
  labs(title = "Initial vs reseq", x = NULL, y = "Theta YC Distance between MiSeq runs")+
  coord_flip()+ #flip axis
  theme_classic()+
  theme(plot.title = element_text(hjust = 0.5), #Center plot title
        legend.position = "none") 
  

#Initial (col) vs plate 52 (row) run
i_vs_p52 <- all_dist %>% 
  filter(col_miseq_run == 1 & row_miseq_run == 3) %>% 
  ggplot(aes(x = row_sample, y = distances, color = row_sample)) +
  geom_jitter(size=2) +
  #  scale_x_discrete(guide = guide_axis(n.dodge = 2))+
  labs(title = "Initial vs plate 52", x = NULL, y = "Theta YC Distance between MiSeq runs")+
  coord_flip()+ #flip axis
  theme_classic()+
  theme(plot.title = element_text(hjust = 0.5), #Center plot title
        legend.position = "none") 

#Reseq (row) vs plate 52 (col)
reseq_vs_p52 <- all_dist %>% 
  filter(col_miseq_run == 3 & row_miseq_run == 2) %>% 
  ggplot(aes(x = row_sample, y = distances, color = row_sample)) +
  geom_jitter(size=2) +
  #  scale_x_discrete(guide = guide_axis(n.dodge = 2))+
  labs(title = "Reseq vs plate 52", x = NULL, y = "Theta YC Distance between MiSeq runs")+
  coord_flip()+ #flip axis
  theme_classic()+
  theme(plot.title = element_text(hjust = 0.5), #Center plot title
        legend.position = "none") 

under_.25 <- all_dist %>% 
  filter(distances < 0.25)
#40
unique_under_.25 <- under_.25 %>% distinct(row_sample, .keep_all = TRUE)
#21 samples

#Plot of samples with low theta yc distances
plot_under_.25 <- under_.25 %>% 
  ggplot(aes(x = row_sample, y = distances, color = row_sample, shape = miseq_run_comp)) +
  geom_jitter(size=2) +
  labs(title = "Under 0.25", x = NULL, y = "Theta YC Distance between MiSeq runs")+
  coord_flip()+ #flip axis
  theme_classic()+
  ylim(0, 1)+
  theme(plot.title = element_text(hjust = 0.5), #Center plot title
        legend.position = "none")+
  geom_vline(xintercept = c((1:21) - 0.5 ), color = "grey")

#Samples with over .25 theta yc distances:
over_.25 <- anti_join(samples_to_check, unique_under_.25, by = c("sample" = "row_sample"))
#5 samples: 
over_.25_ids <- over_.25 %>% pull(sample)

#Plot of distances for samples with over .25 theta yc distances
plot_over_.25 <- all_dist %>% 
  filter(row_sample %in% over_.25_ids) %>%
  ggplot(aes(x = row_sample, y = distances, color = row_sample), show.legend = FALSE) +
  geom_jitter(size=2,aes(shape = miseq_run_comp)) +
  labs(title = "Over 0.25", x = NULL, y = "Theta YC Distance between MiSeq runs", shape = "MiSeq Runs")+
  coord_flip()+ #flip axis
  theme_classic()+
  guides(color = "none")+ #get rid of color legend
  ylim(0, 1)+
  geom_vline(xintercept = c((1:5) - 0.5 ), color = "grey")+
  theme(plot.title = element_text(hjust = 0.5), #Center plot title
        legend.position = "bottom")

plot_grid(plot_under_.25, plot_over_.25, labels = NULL, nrow = 1)+
  ggsave("exploratory/notebook/thetayc_btwn_runs.pdf")

#Per Pat's suggestions: plot the distance by the number of sequences in the smallest library
#Make a data frame with new columns of the number of sequences in the MiSeq run that had the smallest number of sequences for each comparison
distance_vs_nseqs <- all_dist %>% 
  mutate(min_nseqs_2vs1 = pmin(nseqs_1, nseqs_2),
         min_nseqs_3vs1 = pmin(nseqs_1, nseqs_3),
         min_nseqs_2vs3 = pmin(nseqs_3, nseqs_2)) #Make new columns of the number of sequences in the MiSeq run that had the smallest number of sequences for each comparison
  
#Match up miseq_run_comp comparisons with min_nseqs
subset_2vs3 <- distance_vs_nseqs %>% 
  filter(miseq_run_comp == "2vs3") %>% 
  select(-min_nseqs_2vs1, -min_nseqs_3vs1) %>% #Get rid of min_nseqs columns that do not correspond to 2vs3
  rename(min_nseqs = min_nseqs_2vs3) %>% #rename comparison specific to min_nseqs so we can rejoin the 3 comparison subsets later
  select(-nseqs_1, -nseqs_2, -nseqs_3) #Get rid of extra columns that are no longer needed

subset_2vs1 <- distance_vs_nseqs %>% 
  filter(miseq_run_comp == "2vs1") %>% 
  select(-min_nseqs_3vs1, -min_nseqs_2vs3) %>% #Get rid of min_nseqs columns that do not correspond to 2vs3
  rename(min_nseqs = min_nseqs_2vs1) %>% #rename comparison specific to min_nseqs so we can rejoin the 3 comparison subsets later
  select(-nseqs_1, -nseqs_2, -nseqs_3) #Get rid of extra columns that are no longer needed

subset_3vs1 <- distance_vs_nseqs %>% 
  filter(miseq_run_comp == "3vs1") %>% 
  select(-min_nseqs_2vs1, -min_nseqs_2vs3) %>% #Get rid of min_nseqs columns that do not correspond to 2vs3
  rename(min_nseqs = min_nseqs_3vs1) %>% #rename comparison specific to min_nseqs so we can rejoin the 3 comparison subsets later
  select(-nseqs_1, -nseqs_2, -nseqs_3) #Get rid of extra columns that are no longer needed

plot_dist_vs_nseqs <- rbind(subset_2vs1, subset_3vs1, subset_2vs3) %>%
  ggplot(aes(x = min_nseqs, y = distances, color = row_sample, shape = miseq_run_comp, label = short_sample_id)) +
  geom_text(aes(label = short_sample_id))+
  labs(title = NULL, x = "Minimum Number of Sequences", y = "Theta YC Distance between MiSeq runs", shape = "MiSeq Runs")+
  theme_classic()+
  guides(color = "none")+ #get rid of color legend
  ylim(0, 1)+
  theme(plot.title = element_text(hjust = 0.5), #Center plot title
        text = element_text(size = 16), #Change font size of entire plot
        legend.position = "bottom")+
  ggsave("exploratory/notebook/thetayc_btwn_runs_vs_nseqs.pdf")

#Same plot with symbols instead of number labels  
plot_dist_vs_nseqs <- rbind(subset_2vs1, subset_3vs1, subset_2vs3) %>%
  ggplot(aes(x = min_nseqs, y = distances, color = row_sample, shape = miseq_run_comp, label = short_sample_id)) +
  geom_jitter(size=2,aes(shape = miseq_run_comp)) +
  labs(title = NULL, x = "Minimum Number of Sequences", y = "Theta YC Distance between MiSeq runs", shape = "MiSeq Runs")+
  theme_classic()+
  guides(color = "none")+ #get rid of color legend
  ylim(0, 1)+
  theme(plot.title = element_text(hjust = 0.5), #Center plot title
        text = element_text(size = 16), #Change font size of entire plot
        legend.position = "bottom")+
  ggsave("exploratory/notebook/thetayc_btwn_runs_vs_nseqs_symbol.pdf")

dist_vs_nseqs <- rbind(subset_2vs1, subset_3vs1, subset_2vs3)
cor.test(dist_vs_nseqs$min_nseqs, y =  dist_vs_nseqs$distances, method = "spearman")
#R of =0.255, p = 0.033

#After discussing with Pat and the lab, decided not to combine sequences across runs because this would only be for 26 samples and
# the theta yc for 5 of the samples are quite large between runs