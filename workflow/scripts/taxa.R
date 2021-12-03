source("code/utilities.R") #Loads libraries, reads in metadata, functions
source("code/read_taxa_data.R") #Read in taxa data

agg_genus_data <- agg_taxonomic_data(genus)

#Remove large data frames no longer needed
rm(agg_taxa_data)
rm(agg_otu)

idsa_severity <- read_csv("data/process/case_idsa_severity.csv") 
agg_otu_data <- agg_otu_data %>% 
  right_join(idsa_severity, by = "sample")

#List of C. difficile OTus
c_diff_otus <- agg_otu_data %>% 
  distinct(otu) %>% 
  filter(str_detect(otu, "Peptostreptococcaceae")) %>% 
  pull(otu)

#Function to plot a heatmap of the median relative abundances of a list of OTUs across groups
#Arguments: otus = list of otus to plot
hm_plot_otus <- function(otus){
  agg_otu_data %>%
    filter(otu %in% otus) %>%
    group_by(idsa_severity, otu_name) %>% 
    summarize(median=median(agg_rel_abund + 1/10000),`.groups` = "drop") %>%  #Add small value (1/2Xsubssampling parameter) so that there are no infinite values with log transformation
    ggplot()+
    geom_tile(aes(x = idsa_severity, y=otu_name, fill=median))+
    labs(title=NULL,
         x=NULL,
         y=NULL)+
    scale_fill_distiller(trans = "log10",palette = "YlGnBu", direction = 1, name = "Relative \nAbundance", breaks=c(1e-4, 1e-3, 1e-2, 1e-1, 1), labels=c(1e-2, 1e-1, 1, 10, 100), limits = c(1/10000, 1))+
    theme_classic()+
    scale_x_discrete(label = c("Not Severe", "IDSA Severe"))+
    theme(plot.title=element_text(hjust=0.5),
          axis.text.x = element_text(angle = 45, hjust = 1), #Angle axis labels
          axis.text.y = element_markdown(), #Have only the OTU names show up as italics
          text = element_text(size = 16)) # Change font size for entire plot
}

c_diff_otu_hm_plot <- hm_plot_otus(c_diff_otus)
#OTU 41 blast results match C. difficile. The rest of the Peptostreptococcaceae are mostly below the limit of detection in most samples.
#For now just remove OTU 41 from features used in machine learning models.

#Function to plot a the median relative abundances of a list of OTUs across groups
#Arguments: otus = list of otus to plot
plot_otus <- function(otus){
  agg_otu_data %>%
    filter(otu %in% otus) %>%
    mutate(agg_rel_abund = agg_rel_abund + 1/10000) %>% # 10000 is 2 times the subsampling parameter of 1000
    ggplot(aes(x= otu_name, y=agg_rel_abund, color=idsa_severity))+
    scale_colour_manual(name=NULL,
                        values=color_scheme,
                        breaks=legend_idsa,
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
save_plot("results/figures/otus_peptostreptococcaceae.png", c_diff_otu_plot, base_height =8, base_width = 6)
#OTU 41 blast results match C. difficile. The rest of the Peptostreptococcaceae are mostly below the limit of detection in most samples.
#For now just remove OTU 41 from features used in machine learning models.

#Plot top 20 OTUs for IDSA severity random forest model-----
#Examine feature importance for random forest model that classifies IDSA severity status----
idsa_severe_rf <- read_feat_imp("results/idsa_severity/combined_feature-importance_rf.csv")
#Top 20 OTUs for each input dataset with the random forest model
idsa_severe_rf_top <- top_20(idsa_severe_rf) %>% pull(otu)
#Plot top 20 OTUs
idsa_severe_otus_hm <- agg_otu_data %>% 
      filter(otu %in% idsa_severe_rf_top) %>% #Select only otus for a specific model
      group_by(idsa_severity, otu_name) %>% 
      mutate(median=median(agg_rel_abund + 1/10000),`.groups` = "drop") %>%  #Add small value (1/2Xsubssampling parameter) so that there are no infinite values with log transformation
      ggplot()+
      geom_tile(aes(x = idsa_severity, y=otu_name, fill=median))+
      labs(title=NULL,
           x=NULL,
           y=NULL)+
      scale_fill_distiller(trans = "log10",palette = "YlGnBu", direction = 1, name = "Relative \nAbundance", breaks=c(1e-4, 1e-3, 1e-2, 1e-1, 1), labels=c(1e-2, 1e-1, 1, 10, 100), limits = c(1/10000, 1))+
      theme_classic()+
      scale_x_discrete(label = c("Not Severe", "IDSA Severe"))+
      theme(plot.title=element_text(hjust=0.5),
            axis.text.x = element_text(angle = 45, hjust = 1), #Angle axis labels
            legend.position = "none",
            #          axis.text.x = element_text(angle = 45, hjust = 1), #Angle axis labels
            axis.text.y = element_markdown(), #Have only the OTU names show up as italics
            text = element_text(size = 16)) # Change font size for entire plot
save_plot("results/figures/feat_imp_idsa_severe_otus_abund.png", idsa_severe_otus_hm, base_height =4, base_width = 4)

