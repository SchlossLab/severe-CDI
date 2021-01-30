source("code/utilities.R") #Loads libraries, reads in metadata, functions

set.seed(19760620) #Same seed used for mothur analysis

CvDC_results <- read_tsv("data/process/CvDC.0.03.lefse_summary", col_types=cols(Group=col_character()), na = ".") %>% 
  mutate(comparison = "CvDC")

CvNDC_results <- read_tsv("data/process/CvNDC.0.03.lefse_summary", col_types=cols(Group=col_character()), na = ".") %>% 
  mutate(comparison = "CvNDC")

DCvNDC_results <- read_tsv("data/process/DCvNDC.0.03.lefse_summary", col_types=cols(Group=col_character()), na = ".") %>% 
  mutate(comparison = "DCvNDC")

#Read in taxonomy info: 
taxa_info <- read.delim('data/mothur/cdi.taxonomy', header=T, sep='\t') %>%
  select(-Size)

#Combine the results for all 3 comparisons
lefse_results <- CvDC_results %>% 
  add_row(CvNDC_results) %>% 
  add_row(DCvNDC_results) %>% 
  rename(group = Class) %>% #Rename this column so we can use the same color scheme as other plots
  filter(!is.na(pValue)) %>%  #Remove all OTUs that did not have a calculated p-value
  left_join(taxa_info, by = "OTU") %>% 
  rename(names = OTU) %>% 
  mutate(names=str_to_upper(names)) %>%
  mutate(taxa=gsub("(.*);.*","\\1",Taxonomy)) %>%
  mutate(taxa=gsub("(.*)_.*","\\1",Taxonomy)) %>%
  mutate(taxa=gsub("(.*);.*","\\1",Taxonomy)) %>%
  mutate(taxa=str_replace_all(taxa, c("Clostridium_" = "Clostridium "))) %>% 
  mutate(taxa=gsub(".*;","",taxa)) %>%
  mutate(taxa=gsub("(.*)_.*","\\1",taxa)) %>%
  mutate(taxa=gsub('[0-9]+', '', taxa)) %>%
  mutate(taxa=str_remove_all(taxa, "[(100)]")) %>%
  unite(names, taxa, names, sep=" (") %>%
  mutate(names = paste(names,")", sep="")) %>%
  select(-Taxonomy) %>%
  rename(otu=names) %>%
  mutate(otu=paste0(gsub('TU0*', 'TU ', otu))) %>%
  separate(otu, into = c("bactname", "OTUnumber"), sep = "\\ [(]", remove = FALSE) %>% #Add columns to separate bacteria name from OTU number to utilize ggtext so that only bacteria name is italicized
  mutate(otu_name = glue("*{bactname}* ({OTUnumber}")) #Markdown notation so that only bacteria name is italicized


#Plots of LDA values
CvDC_plot <- lefse_results %>% 
  filter(comparison == "CvDC") %>% 
  ggplot(aes(x = otu_name, y = LDA, color = group, fill = group))+
  geom_col()+
  coord_flip()+
  scale_colour_manual(name=NULL,
                      values=color_scheme,
                      breaks=legend_groups,
                      labels=legend_labels)+
  scale_fill_manual(name=NULL,
                    values=color_scheme,
                    breaks=legend_groups,
                    labels=legend_labels)+
  labs(x = NULL)+
  theme_classic()+
  theme(plot.title=element_text(hjust=0.5),
        text = element_text(size = 15),# Change font size for entire plot
        axis.text.y = element_markdown(), #Have only the OTU names show up as italics
        strip.background = element_blank(),
        legend.position = "none") 
  
