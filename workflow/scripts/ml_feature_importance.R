source("code/utilities.R") #Loads libraries, reads in metadata, functions

set.seed(19760620) #Same seed used for mothur analysis

#Function to read in feature importance from random forest model----
#Will also get the corresponding otu name from taxonomy file
#And format otu name to work with glue package for italicizing labels
#file_path = path to the file name
read_feat_imp <- function(file_path){
  feat_imp <- read_csv(file_path)
  taxa_info <- read.delim('data/mothur/cdi.taxonomy', header=T, sep='\t') %>%
    select(-Size) %>%
    mutate(names=OTU) %>%
    select(-OTU)
  final_feat_imp <- inner_join(feat_imp, taxa_info, by="names") %>%
    ungroup() %>%
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
  return(final_feat_imp)
}

#Function to get the top 20 features that have the largest impact on AUROC
#df = dataframe of feature importances for the 100 seeds
top_20 <- function(df){
  data_first_20 <- df %>% 
    group_by(otu) %>% 
    summarize(median = median(perf_metric_diff)) %>% #Get the median performance metric diff. for each feature
    arrange(desc(median)) %>% #Arrange from largest median to smallest
    head(20)
  
  return(data_first_20)
}

#Examine feature importance for random forest model that classifies IDSA severity status----
idsa_severe_rf <- read_feat_imp("results/idsa_severity/combined_feature-importance_rf.csv")

#Top 20 OTUs for each input dataset with the random forest model
idsa_severe_rf_top <- top_20(idsa_severe_rf) %>% pull(otu)
  
#Plot top 20 OTU results for IDSA severity random forest classification model----
idsa_sev_rf_feat_plot <- idsa_severe_rf %>% 
    filter(otu %in% idsa_severe_rf_top) %>% 
    ggplot(aes(fct_reorder(otu_name, -perf_metric_diff, .desc = TRUE), perf_metric_diff))+
    stat_summary(fun = 'median', 
                 fun.max = function(x) quantile(x, 0.75), 
                 fun.min = function(x) quantile(x, 0.25),
                 position = position_dodge(width = 1)) + 
    scale_color_manual(values = cols)+
    coord_flip()+
    labs(title=NULL, 
         x=NULL,
         y="Difference in AUROC")+
    theme_classic()+
    theme(plot.title=element_text(hjust=0.5),
          text = element_text(size = 15),# Change font size for entire plot
          axis.text.y = element_markdown(), #Have only the OTU names show up as italics
          strip.background = element_blank(),
          legend.position = "none")+
  ggsave("results/figures/feat_imp_rf_idsa_severity.png", height = 5, width = 8)

