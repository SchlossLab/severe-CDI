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

#Remove large data frames no longer needed
rm(agg_taxa_data)

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

#Remove large data frames no longer needed
rm(agg_otu)

#List of C. difficile OTus
c_diff_otus <- agg_otu_data %>% 
  distinct(otu) %>% 
  filter(str_detect(otu, "Peptostreptococcaceae")) %>% 
  pull(otu)
  
#Function to plot a list of OTUs across sources of mice at a specific timepoint:
#Arguments: otus = list of otus to plot; timepoint = day of the experiment to plot
plot_otus <- function(otus){
  agg_otu_data %>%
    filter(otu %in% otus) %>%
    mutate(agg_rel_abund = agg_rel_abund + 1/10000) %>% # 10000 is 2 times the subsampling parameter of 1000
    ggplot(aes(x= otu_name, y=agg_rel_abund, color=group))+
    scale_colour_manual(name=NULL,
                        values=color_scheme,
                        breaks=legend_groups,
                        labels=legend_labels)+
    geom_hline(yintercept=1/5000, color="gray")+
    stat_summary(fun = 'median',
                 fun.max = function(x) quantile(x, 0.75),
                 fun.min = function(x) quantile(x, 0.25),
                 position = position_dodge(width = 1)) +
    labs(title=NULL,
         x=NULL,
         y="Relative abundance (%)")+
    scale_y_log10(breaks=c(1e-4, 1e-3, 1e-2, 1e-1, 1), labels=c(1e-2, 1e-1, 1, 10, 100), limits = c(1/10000, 1))+
    coord_flip()+
    theme_classic()+
    theme(plot.title=element_text(hjust=0.5),
          legend.position = "bottom",
          axis.text.y = element_markdown(), #Have only the OTU names show up as italics
          text = element_text(size = 16)) # Change font size for entire plot
}

c_diff_otu_plot <- plot_otus(c_diff_otus)
#OTU 41 blast results match C. difficile. The rest of the Peptostreptococcaceae are mostly below the limit of detection in most samples.
#For now just remove OTU 41 from features used in machine learning models.

#Lower abundance Peptostreptococccaceae
#Function to plot otu with individual sample relative abundances
#otu_plot = otu to plot in quotes. Ex: "Peptostreptococcaceae (OTU 41)"

indiv_otu_plot <- function(otu_plot){
  specify_otu_name <- agg_otu_data %>% #Formated for ggtext & glue to incorp. italics
    filter(otu == otu_plot) %>% 
    pull(otu_name)
  median_summary <- agg_otu_data %>% 
    group_by(group) %>% 
    mutate(median = median(agg_rel_abund + 1/10000)) %>% 
    ungroup() %>% 
    ggplot(aes(x =group, y = agg_rel_abund, color = group))+
    geom_jitter(shape=1, size=1, alpha =0.5, show.legend=FALSE)+
    geom_errorbar(aes(ymax=median, ymin = median), color = "black", size=1) + #Add line to indicate median relative abundance
    scale_colour_manual(name=NULL,
                        values=color_scheme,
                        breaks=legend_groups,
                        labels=legend_labels)+
    scale_shape_manual(name=NULL, 
                       values=shape_scheme,
                       breaks=legend_groups,
                       labels=legend_labels)+
    scale_x_discrete(label = c("Case", "Diarrheal Control", "Non-Diarrheal Control"))+
    geom_hline(yintercept=1/5000, color="gray")+
    labs(title=specify_otu_name,
         x=NULL,
         y="Relative abundance (%)") +
    scale_y_log10(breaks=c(1e-4, 1e-3, 1e-2, 1e-1, 1), labels=c(1e-2, 1e-1, 1, 10, 100))+
    theme_classic()+
    theme(plot.title=element_markdown(hjust = 0.5),
          panel.grid.minor.x = element_line(size = 0.4, color = "grey"),  # Add gray lines to clearly separate symbols by days)
          text = element_text(size = 18)) # Change font size for entire plot
}


for (o in c_diff_otus){
  plot <- indiv_otu_plot(o)
  name <- paste0("rel_abund_", o, ".png")
  save_plot(path = name, )
}
