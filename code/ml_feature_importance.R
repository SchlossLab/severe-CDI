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
CvDC_rf <- read_feat_imp("results/CvDC/combined_feature-importance_rf.csv")
CvNDC_rf <- read_feat_imp("results/CvNDC/combined_feature-importance_rf.csv")
DCvNDC_rf <- read_feat_imp("results/DCvNDC/combined_feature-importance_rf.csv")


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

#Top 20 OTUs for each input dataset with the random forest model
CvDC_rf_top <- top_20(CvDC_rf) %>% pull(otu)
CvNDC_rf_top <- top_20(CvNDC_rf) %>% pull(otu)
DCvNDC_rf_top <- top_20(DCvNDC_rf) %>% pull(otu)

#Overlap between 3 pairwise comparisons
all <- intersect_all(CvDC_rf_top, CvNDC_rf_top,
              DCvNDC_rf_top)
#Otu15 & 24

#Overlap between case comparisons
case <- intersect_all(CvDC_rf_top, CvNDC_rf_top)

#Overlap between diarrheal control comparisons
dc <- intersect_all(CvDC_rf_top, DCvNDC_rf_top)

#Overlap between non diarrheal control comparisons
ndc <- intersect_all(CvNDC_rf_top, DCvNDC_rf_top)

#Define colors for overlapping OTUs
cols <- c("all" = "goldenrod", "case" = "red", "dc" = "blue", "ndc" = "grey50", "no overlap" = "black")

#Create data frame of top OTUs that overlap between at least 2 random forest models:
CvDC_rf %>% 
  add_row(CvNDC_rf) %>% 
  add_row(DCvNDC_rf) %>% 
  select(otu, bactname, OTUnumber) %>% 
  filter(otu %in% c(all, case, dc, ndc)) %>%
  distinct(otu, bactname, OTUnumber) %>% 
  mutate(color = case_when(otu %in% all ~ "goldenrod",
                                 otu %in% case ~ "red",
                                 otu %in% dc ~ "blue",
                                 otu %in% ndc ~ "grey50",
                                 TRUE ~ "black")) %>% 
  mutate(overlap = case_when(otu %in% all ~ "all",
                             otu %in% case ~ "case",
                             otu %in% dc ~ "dc",
                             otu %in% ndc ~ "ndc",
                             TRUE ~ "no overlap")) %>% 
  mutate(otu_color_name = glue("<i style='color:{color}'>{bactname}</i> ({OTUnumber}")) %>% #Markdown notation so that only bacteria name is italicized and colors will be incorporated into name
  select(-bactname, -OTUnumber) %>% 
  write_csv(path = "data/process/ml_rf_top_otus_overlap.csv")

#Create data frame of top OTUs that do not overlap between at least 2 random forest models:
CvDC_rf %>% 
  add_row(CvNDC_rf) %>% 
  add_row(DCvNDC_rf) %>% 
  select(otu, bactname, OTUnumber) %>% 
  distinct(otu, bactname, OTUnumber) %>% 
  filter(otu %in% c(CvDC_rf_top, CvNDC_rf_top, DCvNDC_rf_top)) %>% 
  mutate(color = "black") %>% 
  mutate(model = case_when(otu %in% CvDC_rf_top ~ "CvDC",
                             otu %in% CvNDC_rf_top ~ "CvNDC",
                             otu %in% DCvNDC_rf_top ~ "DCvNDC",
                             TRUE ~ "NA")) %>% 
  mutate(overlap = case_when(otu %in% all ~ "all",
                             otu %in% case ~ "case",
                             otu %in% dc ~ "dc",
                             otu %in% ndc ~ "ndc",
                             TRUE ~ "no overlap")) %>% 
  mutate(otu_color_name = glue("<i style='color:{color}'>{bactname}</i> ({OTUnumber}")) %>% #Markdown notation so that only bacteria name is italicized and colors will be incorporated into name
  filter(overlap == "no overlap") %>% #Remove all features that overlap between models
  select(-overlap, -bactname, -OTUnumber) %>% 
  write_csv(path = "data/process/ml_rf_top_otus_no_overlap.csv")  
#Function to filter to top OTUs for each pairwise comparison & plot results
#df = dataframes of feature importances for all seeds
#top_otus = dataframes of top otus
#comp_name = name of comparison to title the plot (in quotes)
plot_feat_imp <- function(df, top_otus, comp_name){
  df %>% 
  filter(otu %in% top_otus) %>% 
    mutate(common_otus = case_when(otu %in% all ~ "all",
                                   otu %in% case ~ "case",
                                   otu %in% dc ~ "dc",
                                   otu %in% ndc ~ "ndc",
                                   TRUE ~ "no overlap")) %>%
    ggplot(aes(fct_reorder(otu_name, -perf_metric_diff, .desc = TRUE), perf_metric_diff, color=factor(common_otus)))+
    stat_summary(fun = 'median', 
                 fun.max = function(x) quantile(x, 0.75), 
                 fun.min = function(x) quantile(x, 0.25),
                 position = position_dodge(width = 1)) + 
    scale_color_manual(values = cols)+
    coord_flip()+
    labs(title=comp_name, 
         x=NULL,
         y="Difference in AUROC")+
    theme_classic()+
    theme(plot.title=element_text(hjust=0.5),
          text = element_text(size = 15),# Change font size for entire plot
          axis.text.y = element_markdown(), #Have only the OTU names show up as italics
          strip.background = element_blank(),
          legend.position = "none")   
}

#Plot feature importances for the top OTUs for each comparison----
plot_feat_imp(CvDC_rf, CvDC_rf_top, "Cases vs Diarrheal Controls")+
  ggsave("results/figures/feat_imp_rf_CvDC.png", height = 5, width = 8)
plot_feat_imp(CvNDC_rf, CvNDC_rf_top, "Cases vs Non-Diarrheal Controls")+
  ggsave("results/figures/feat_imp_rf_CvNDC.png", height = 5, width = 8)
plot_feat_imp(DCvNDC_rf, DCvNDC_rf_top, "Diarrheal Controls vs Non-Diarrheal Controls")+
  ggsave("results/figures/feat_imp_rf_DCvNDC.png", height = 5, width = 8)

#Function to read in feature importance from random forest model at the genus level----
#Will also get the corresponding genus name from taxonomy file
#file_path = path to the file name
read_feat_imp_genus <- function(file_path){
  feat_imp <- read_csv(file_path)
  taxa_info <- read.delim('data/process/cdi.genus.taxonomy', header=T, sep='\t') %>%
    select(-Size) %>%
    mutate(names=OTU) %>%
    select(-OTU)
  final_feat_imp <- inner_join(feat_imp, taxa_info, by="names") %>%
    ungroup() %>%
    mutate(names=str_to_upper(names)) %>%
    mutate(genus=gsub("(.*);.*","\\1",Taxonomy)) %>%
    mutate(genus=gsub("(.*)_.*","\\1",Taxonomy)) %>%
    mutate(genus=gsub("(.*);.*","\\1",Taxonomy)) %>% 
    mutate(genus=str_replace_all(genus, c("_" = " ", #Removes all other underscores
                                             "unclassified" = "Unclassified"))) %>% 
    select(-Taxonomy)
  return(final_feat_imp)
}
CvDC_rf <- read_feat_imp_genus("results/CvDC/genus_level/combined_feature-importance_rf.csv")
CvNDC_rf <- read_feat_imp_genus("results/CvNDC/genus_level/combined_feature-importance_rf.csv")
DCvNDC_rf <- read_feat_imp_genus("results/DCvNDC/genus_level/combined_feature-importance_rf.csv")

#Function to get the top 20 features that have the largest impact on AUROC
#df = dataframe of feature importances for the 100 seeds
top_20_genus <- function(df){
  data_first_20 <- df %>% 
    group_by(genus) %>% 
    summarize(median = median(perf_metric_diff)) %>% #Get the median performance metric diff. for each feature
    arrange(desc(median)) %>% #Arrange from largest median to smallest
    head(20)
  
  return(data_first_20)
}

#Top 20 OTUs for each input dataset with the random forest model
CvDC_rf_top <- top_20_genus(CvDC_rf) %>% pull(genus)
CvNDC_rf_top <- top_20_genus(CvNDC_rf) %>% pull(genus)
DCvNDC_rf_top <- top_20_genus(DCvNDC_rf) %>% pull(genus)

#Overlap between 3 pairwise comparisons
all <- intersect_all(CvDC_rf_top, CvNDC_rf_top,
                     DCvNDC_rf_top)

#Overlap between case comparisons
case <- intersect_all(CvDC_rf_top, CvNDC_rf_top)

#Overlap between diarrheal control comparisons
dc <- intersect_all(CvDC_rf_top, DCvNDC_rf_top)

#Overlap between non diarrheal control comparisons
ndc <- intersect_all(CvNDC_rf_top, DCvNDC_rf_top)

#Define colors for overlapping OTUs
cols <- c("all" = "goldenrod", "case" = "red", "dc" = "blue", "ndc" = "grey50", "no overlap" = "black")

#Create data frame of top genera that overlap between at least 2 random forest models:
tibble("genus" = all) %>% 
  add_row(tibble("genus" = case)) %>% 
  add_row(tibble("genus" = dc)) %>% 
  add_row(tibble("genus" = ndc)) %>% 
  distinct(genus) %>% 
  mutate(color = case_when(genus %in% all ~ "goldenrod",
                           genus %in% case ~ "red",
                           genus %in% dc ~ "blue",
                           genus %in% ndc ~ "grey50",
                           TRUE ~ "black")) %>% 
  mutate(overlap = case_when(genus %in% all ~ "all",
                             genus %in% case ~ "case",
                             genus %in% dc ~ "dc",
                             genus %in% ndc ~ "ndc",
                             TRUE ~ "no overlap")) %>% 
  write_csv(path = "data/process/ml_rf_top_genera_overlap.csv")

#Function to filter to top genuss for each pairwise comparison & plot results
#df = dataframes of feature importances for all seeds
#top_genus = dataframes of top genera
#comp_name = name of comparison to title the plot (in quotes)
plot_feat_imp_genus <- function(df, top_genus, comp_name){
  df %>% 
    filter(genus %in% top_genus) %>% 
    mutate(common_genera = case_when(genus %in% all ~ "all",
                                   genus %in% case ~ "case",
                                   genus %in% dc ~ "dc",
                                   genus %in% ndc ~ "ndc",
                                   TRUE ~ "no overlap")) %>%
    ggplot(aes(fct_reorder(genus, -perf_metric_diff, .desc = TRUE), perf_metric_diff, color=factor(common_genera)))+
    stat_summary(fun = 'median', 
                 fun.max = function(x) quantile(x, 0.75), 
                 fun.min = function(x) quantile(x, 0.25),
                 position = position_dodge(width = 1)) + 
    scale_color_manual(values = cols)+
    coord_flip()+
    labs(title=comp_name, 
         x=NULL,
         y="Difference in AUROC")+
    theme_classic()+
    theme(plot.title=element_text(hjust=0.5),
          text = element_text(size = 15),# Change font size for entire plot
          axis.text.y = element_text(face = "italic"), #Have only the OTU names show up as italics
          strip.background = element_blank(),
          legend.position = "none")   
}

#Plot feature importances for the top OTUs for each comparison----
plot_feat_imp_genus(CvDC_rf, CvDC_rf_top, "Cases vs Diarrheal Controls")+
  ggsave("results/figures/feat_imp_rf_genus_CvDC.png", height = 5, width = 8)
plot_feat_imp_genus(CvNDC_rf, CvNDC_rf_top, "Cases vs Non-Diarrheal Controls")+
  ggsave("results/figures/feat_imp_rf_genus_CvNDC.png", height = 5, width = 8)
plot_feat_imp_genus(DCvNDC_rf, DCvNDC_rf_top, "Diarrheal Controls vs Non-Diarrheal Controls")+
  ggsave("results/figures/feat_imp_rf_genus_DCvNDC.png", height = 5, width = 8)

