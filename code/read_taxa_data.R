source("code/utilities.R") #Loads libraries, reads in metadata, functions

#Read in shared and taxonomy files for all samples----
# Import taxonomy into data frame and clean up taxonomy names
taxonomy <- read_tsv(file="data/mothur/cdi.taxonomy") %>%
  rename_all(tolower) %>% #remove uppercase from column names
  # Split taxonomic information into separate columns for each taxonomic level
  mutate(taxonomy=str_replace_all(taxonomy, c("\\(\\d*\\)" = "", #drop digits with parentheses around them
                                              ';$' = "", #removes semi-colon at end of line
                                              'Bacteria_unclassified' = 'Unclassified',
                                              "Clostridium_" = "Clostridium ", #Remove underscores after Clostridium
                                              "_" = " ", #Removes all other underscores
                                              "unclassified" = "Unclassified"))) %>%
  # Separate taxonomic levels into separate columns according to semi-colon.
  separate(taxonomy, into=c("kingdom", "phylum", "class", "order", "family", "genus"), sep=';')

# Import otu_data for samples
#Note: check for sub.sample version in data/mothur make sure that is the output from sub.sample
otu_data <- read_tsv("data/mothur/cdi.opti_mcc.0.03.subsample.shared", col_types=cols(Group=col_character())) %>%
  select(-label, -numOtus) %>%
  rename(sample = Group) %>% #group is the same as sample in the metadata data frame
  gather(-sample, key="otu", value="count") %>%
  mutate(rel_abund=count/5000) #Use 5000, because this is the subsampling parameter chosen.

#Merge otu_data to taxonomy data frame
agg_taxa_data <- inner_join(otu_data, taxonomy)

# Function to summarize relative abundance level for a given taxonomic level (ex. genus, family, phlyum, etc.)
agg_taxonomic_data <- function(taxonomic_level) {
  agg_taxa_data %>%
    group_by(sample, {{ taxonomic_level }}) %>% #Embracing treats the taxonomic_level argument as a column name
    summarize(agg_rel_abund=sum(rel_abund)) %>%
    # Merge relative abundance data to specifci taxonomic_level data
    left_join(., metadata, by = "sample") %>%
    ungroup()
}

# Relative abundance data at the otu level:
agg_otu_data <- agg_taxonomic_data(otu)

#Rename otus to match naming convention used previously and add a column that will work with ggtext package:
agg_otu <- agg_otu_data %>%
  mutate(key=otu) %>%
  group_by(key)
#Remove large data frames no longer needed
rm(agg_otu_data)
rm(otu_data)
rm(taxonomy)
taxa_info <- read.delim('data/mothur/cdi.taxonomy', header=T, sep='\t') %>%
  select(-Size) %>%
  mutate(key=OTU) %>%
  select(-OTU)
agg_otu_data <- inner_join(agg_otu, taxa_info, by="key") %>%
  ungroup() %>%
  mutate(key=str_to_upper(key)) %>%
  mutate(taxa=gsub("(.*);.*","\\1",Taxonomy)) %>%
  mutate(taxa=gsub("(.*)_.*","\\1",Taxonomy)) %>%
  mutate(taxa=gsub("(.*);.*","\\1",Taxonomy)) %>%
  mutate(taxa=gsub(".*;","",taxa)) %>%
  mutate(taxa=gsub("(.*)_.*","\\1",taxa)) %>%
  mutate(taxa=gsub('[0-9]+', '', taxa)) %>%
  mutate(taxa=str_remove_all(taxa, "[(100)]")) %>%
  unite(key, taxa, key, sep=" (") %>%
  mutate(key = paste(key,")", sep="")) %>%
  select(-otu, -Taxonomy) %>%
  rename(otu=key) %>%
  mutate(otu=paste0(gsub('TU0*', 'TU ', otu))) %>%
  separate(otu, into = c("bactname", "OTUnumber"), sep = "\\ [(]", remove = FALSE) %>% #Add columns to separate bacteria name from OTU number to utilize ggtext so that only bacteria name is italicized
  mutate(otu_name = glue("*{bactname}* ({OTUnumber}")) #Markdown notation so that only bacteria name is italicized
