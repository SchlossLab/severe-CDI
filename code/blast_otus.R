source("code/utilities.R") #Loads libraries, reads in metadata, functions
#Identify the bacterial OTUs that correspond to C. difficile

#Read in taxonomy:
taxonomy <- read_tsv(file="data/mothur/cdi.taxonomy") %>% 
  select(-Size) %>%
  mutate(Taxonomy=str_replace_all(Taxonomy, "\\(\\d*\\)", "")) %>%
  mutate(Taxonomy=str_replace_all(Taxonomy, ";$", "")) %>%
  separate(Taxonomy, c("kingdom", "phylum", "class", "order", "family", "genus"), sep=';')

#Sequences for Potential C. difficile OTUs:
c_diff_otus <- taxonomy %>% 
  filter(genus == "Peptostreptococcaceae_unclassified") %>% 
  pull(OTU) 
#List of 59 OTUs

#File containing the representative sequences for the OTUs identified in the dataset
#Function to read in fasta files, based on library(devtools) source_url("https://raw.githubusercontent.com/lrjoshi/FastaTabular/master/fasta_and_tabular.R")
#I modified the function to remove the lines that export as .csv
FastaToTabular <- function (filename){
  
  #read fasta file
  
  file1 <- readLines(filename)
  
  #find the genename location by grepping >
  
  location <- which((str_sub(file1,1,1))==">")
  
  #start an empty vector to collect name and sequence 
  
  name=c()
  sequence =c()
  
  
  
  #number of genes= number of loops
  #extract name first
  for ( i in 1:length(location)){
    name_line = location[i]
    name1 = file1[name_line]
    name=c(name,name1)
    #extract sequence between the names
    #the last sequence will be missed using this strategy 
    #so, we are using if condition to extract last sequence 
    start= location[i]+1
    end = location[i+1]-1
    if ( i < length (location)){
      
      end=end
      
    } else {
      
      end=length(file1)
    }
    
    lines = start:end
    sequence1= as.character(paste(file1[lines],collapse = ""))
    sequence =c(sequence,sequence1)
  }
  
  #now create table using name and sequence vector 
  
  data <- tibble(name,sequence)
  
  
  #function ends
}

#Read in fasta file containing the representative sequences for each OTU in dataset
otu_seqs <- FastaToTabular("data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.pick.opti_mcc.0.03.rep.fasta")


#Subset otu_seqs to just the rows that have a potential c_diff otu in their name (c_diff_otus)
c_diff_seq_all <- map_df(c_diff_otus, function(c_diff_otus){
  c_diff_seq <- otu_seqs %>% 
    filter(str_detect(name, c_diff_otus)) 
})

#Remove otu_seqs variable
rm(otu_seqs)

c_diff_seq_all %>% pull(sequence)
c_diff_seq_all <- c_diff_seq_all %>% 
  mutate(ncbi_blast_result = "")

#Blast search for 1 OTU: 
#Select standard nucleotide BLAST
#For database: select rRNA/ITS databases and 16S ribosomal RNA sequences

#BLAST search for 59 Peptostreptococcaceae OTUs against C. difficile rRNA:
#Select align 2 or more sequences. Paste 59 OTU sequences in top box
#Place C. difficile rRNA gene in bottom box (used C. difficile ATCC 9689 Accession # NR_113132.1)
#Saved results in "data/process/59OTus_vs_C.diff_ATCC9689-Alignment-HitTable.csv"
blast_results <- read_csv("data/process/59OTus_vs_C.diff_ATCC9689-Alignment-HitTable.csv", 
                          col_names = c("query_acc.ver", "subject_acc.ver", "%identity", "alignment", "length", "mismatches",
                                        "gap opens", "q.start", "q.end", "subject", "evalue", "bit score")) %>% 
  mutate(otu_list_no = 1:59)
#e value = Expect value parameter. Number of hits one can expect to see by chance
#bit score: sequence similarity independent of query sequence length and database size. Normalized based on the rawpairwise alignment score
#C.diff OTU list:
c_diff_otu_list <- as.data.frame(c_diff_otus) %>% 
  mutate(otu_list_no = 1:59) 

percent_identity_dist <- blast_results %>% 
  left_join(c_diff_otu_list, by = "otu_list_no") %>% 
  mutate(c_diff_otus = str_replace_all(c_diff_otus, "Otu", ""),
         c_diff_otus = str_remove(c_diff_otus, "^0+")) %>% 
  ggplot(aes(x=query_acc.ver, y = `%identity`, color = c_diff_otus, shape=c_diff_otus, show.legend = FALSE))+
  geom_text(aes(label = c_diff_otus), position = position_jitter(width = 0.5, height = 0.5))+
  scale_shape_identity()+
  labs(title="Blastn to C. difficile 16S rRNA", 
       x=NULL,
       y="% Identity")+
  theme_classic()+
  theme(plot.title = element_text(hjust =0.5),
        legend.position = "none", #Remove legend
        axis.text.x = element_blank())
save_plot("results/figures/otus_peptostreptococcaceae_blast_results.png", percent_identity_dist, base_height =5, base_width = 6)


#Check how abundant the potential C. difficile OTUs are across each group
#see code/taxa.R

#Check individual sequences clustered into each OTU----
#Compared code & results with Nick for his restoreCR project
seq_by_otu <- read_tsv("data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.pick.opti_mcc.list")

c_diff_seq <- seq_by_otu %>% 
  select(one_of(c_diff_otus)) %>% 
  pivot_longer(cols = one_of(c_diff_otus), names_to = 'otu', values_to = 'sequences') %>% 
  group_by(otu) %>% 
  nest() %>% 
  mutate(sequence_name = map(data, ~unlist(strsplit(.$sequences, ',')))) %>% 
  unnest(sequence_name) %>% 
  select(-data) %>% 
  mutate(sequence_name = paste0('>', sequence_name))

seqs_fasta <- read_tsv('data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.pick.fasta', 
                       col_names = F)
c_diff_fasta <- seqs_fasta %>% 
  mutate(seq_num = rep(1:(nrow(seqs_fasta)/2), each = 2),
         data = rep(c('sequence_name', 'sequence'), nrow(seqs_fasta)/2)) %>% 
  pivot_wider(names_from = data, values_from = X1) %>% 
  inner_join(c_diff_seq, by = c('sequence_name')) %>% 
  mutate(sequence_name = paste(sequence_name, otu, sep = '_'),
         sequence = gsub('-', '', sequence)) %>% 
  pivot_longer(cols = c(sequence_name, sequence), names_to = 'data', values_to = 'sequence_info') %>% 
  select(sequence_info)

write.table(c_diff_fasta, "data/mothur/c_diff_unique_seqs.fasta",
            quote=F, col.names = F, row.names = F)

#BLAST search for C. difficile sequences against C. difficile rRNA:
#Select align 2 or more sequences. Upload c_diff_unique_seqs.fasta to top box
#Place C. difficile rRNA gene in bottom box (used C. difficile ATCC 9689 Accession # NR_113132.1)
#Saved results in "data/process/59OTus_vs_C.diff_ATCC9689-Alignment-HitTable.csv"
seq_blast_results <- read_csv("data/process/c_diff_seqs_vs_C.diff_ATCC9689-Alignment-HitTable.csv", 
                          col_names = c("query_acc.ver", "subject_acc.ver", "%identity", "alignment", "length", "mismatches",
                                        "gap opens", "q.start", "q.end", "subject", "evalue", "bit score")) %>% 
  mutate(seq_list_no = 1:1006)

seq_counts <- read_tsv("data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.denovo.vsearch.pick.pick.pick.count_table")

c_diff_seq_counts <- seq_blast_results %>% 
  group_by(query_acc.ver) %>% 
  summarize(percent_identity = max(`%identity`)) %>% 
  select(sequence_name_otu = query_acc.ver, percent_identity) %>% 
  mutate(sequence_name = gsub('_Otu\\d*', '', sequence_name_otu),
         otu = as.numeric(gsub('.*_Otu', '', sequence_name_otu))) %>%
  select(otu, percent_identity, sequence_name) %>% 
  left_join(select(seq_counts, Representative_Sequence, total),
            by = c('sequence_name' = 'Representative_Sequence'))
                                   
otu_41 <- c_diff_seq_counts %>% 
  filter(otu == 41) %>% 
  arrange(desc(total))
#Most common OTU 41 seq has 100% identity with C. difficile ATCC 9689

#Checked 2nd most common OTU 41 seq (M00967_199_000000000-J7LFV_1_2110_7389_13284) with Blast
#Top hit with 100% identity was Intestinibacter bartlettii strain WAL 16138

#3rd most common OTU 41 seq (M00967_194_000000000-CP4FK_1_1113_6651_10291)
#Top hit has 98.81% identity with C. difficile ATCC 9689

#4th most common OTU 41 seq (M00967_193_000000000-CRJK7_1_2106_15194_22562) 
#Top hit with 98.81% % identity with C. difficile ATCC 9689

#5th most common OTU 41 seq (M00967_194_000000000-CP4FK_1_1114_15707_13440)
#Top hit with 98.81% % identity with C. difficile ATCC 9689