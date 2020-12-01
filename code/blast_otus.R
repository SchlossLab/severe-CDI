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
#Not sure how to read in .fasta files into R/whether it's worth doing
otu_seqs <-  read.fasta("data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.pick.opti_mcc.0.03.rep.fasta", as.string = TRUE, forceDNAtolower = FALSE)
otu_seqs[41]
test <- otu_seqs %>% keep(str_detect(otu_seqs, "Otu00041"))
otu_seqs %>% pluck(Value)

library(devtools)
source_url("https://raw.githubusercontent.com/lrjoshi/FastaTabular/master/fasta_and_tabular.R")
FastaToTabular("data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.pick.opti_mcc.0.03.rep.fasta")
otu_seqs <- read_csv("dna_table.csv")

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
                          col_names = c("query acc.ver", "subject acc.ver", "% identity", "alignment", "length", "mismatches",
                                        "gap opens", "q.start", "q.end", "subject", "evalue", "bit score"))
#e value = Expect value parameter. Number of hits one can expect to see by chance
#bit score: sequence similarity independent of query sequence lenght and database size. Normalized based on the rawpairwise alignment score


#Check how abundant the potential C. difficile Otus are across each group
#see code/taxa.R



