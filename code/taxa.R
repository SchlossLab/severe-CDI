source("code/utilities.R") #Loads libraries, reads in metadata, functions
source("code/read_taxa_data.R") #Read in taxa data

agg_genus_data <- agg_taxonomic_data(genus)

#Remove large data frames no longer needed
rm(agg_taxa_data)
rm(agg_otu)

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
    group_by(group, otu_name) %>% 
    summarize(median=median(agg_rel_abund + 1/10000),`.groups` = "drop") %>%  #Add small value (1/2Xsubssampling parameter) so that there are no infinite values with log transformation
    ggplot()+
    geom_tile(aes(x = group, y=otu_name, fill=median))+
    labs(title=NULL,
         x=NULL,
         y=NULL)+
    scale_fill_distiller(trans = "log10",palette = "YlGnBu", direction = 1, name = "Relative \nAbundance", breaks=c(1e-4, 1e-3, 1e-2, 1e-1, 1), labels=c(1e-2, 1e-1, 1, 10, 100), limits = c(1/10000, 1))+
    theme_classic()+
    scale_x_discrete(label = c("Case", "Diarrheal Control", "Non-Diarrheal Control"))+
    theme(plot.title=element_text(hjust=0.5),
          axis.text.x = element_text(angle = 45, hjust = 1), #Angle axis labels
          axis.text.y = element_markdown(), #Have only the OTU names show up as italics
          text = element_text(size = 16)) # Change font size for entire plot
}

c_diff_otu_hm_plot <- hm_plot_otus(c_diff_otus)
save_plot("results/figures/otus_peptostreptococcaceae_hm.png", c_diff_otu_hm_plot, base_height =8, base_width = 6)
#OTU 41 blast results match C. difficile. The rest of the Peptostreptococcaceae are mostly below the limit of detection in most samples.
#For now just remove OTU 41 from features used in machine learning models.

#of samples with >0 rel_abund for C. diff OTUs
c_diff_otu_count <- agg_otu_data %>% 
  filter(otu %in% c_diff_otus) %>% 
  filter(agg_rel_abund > 0) %>% 
  group_by(otu_name, group) %>% 
  count() %>% 
  ggplot(aes(y= otu_name, x = n, color=group, fill = group))+
  geom_col(position = "dodge")+
  labs(title="Relative abundance > 0", 
       x="# of Samples",
       y=NULL)+
  scale_colour_manual(name=NULL,
                      values=color_scheme,
                      breaks=legend_groups,
                      labels=legend_labels)+
  scale_fill_manual(name=NULL,
                      values=color_scheme,
                      breaks=legend_groups,
                      labels=legend_labels)+
  theme_classic()+
  theme(axis.text.y = element_markdown())
save_plot("results/figures/otus_peptostreptococcaceae_sample_count_0.png", c_diff_otu_count, base_height =8, base_width = 6)


c_diff_otu_count_subset <- agg_otu_data %>% 
  filter(otu %in% c_diff_otus) %>% 
  filter(agg_rel_abund > 0.001) %>% 
  group_by(otu_name, group) %>% 
  count() %>% 
  ggplot(aes(y= otu_name, x = n, color=group, fill = group))+
  geom_col(position = "dodge")+
  labs(title="Relative abundance > 0.001", 
       x="# of Samples",
       y=NULL)+
  scale_colour_manual(name=NULL,
                      values=color_scheme,
                      breaks=legend_groups,
                      labels=legend_labels)+
  scale_fill_manual(name=NULL,
                    values=color_scheme,
                    breaks=legend_groups,
                    labels=legend_labels)+
  theme_classic()+
  theme(axis.text.y = element_markdown())
save_plot("results/figures/otus_peptostreptococcaceae_sample_count_.001.png", c_diff_otu_count_subset, base_height =8, base_width = 6)

#Function to plot a the median relative abundances of a list of OTUs across groups
#Arguments: otus = list of otus to plot
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
save_plot("results/figures/otus_peptostreptococcaceae.png", c_diff_otu_plot, base_height =8, base_width = 6)
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

otu_41 <- indiv_otu_plot("Peptostreptococcaceae (OTU 41)")
save_plot("results/figures/otus_peptostreptococcaceae_41.png", otu_41, base_height =8, base_width = 6)

#Explore relative abundances of top features that overlap across the 3 random forest classification models---
overlap_otu <- read_csv("data/process/ml_rf_top_otus_overlap.csv")
overlap_otus <- overlap_otu %>% pull(otu) #list of otus
overlap_genus <- read_csv("data/process/ml_rf_top_genera_overlap.csv")

#Filter otu data to just otus of interest, join to overlap_otu to add overlap and color columns
top_agg_otu_subset <- agg_otu_data %>% 
  filter(otu %in% overlap_otus) %>% 
  left_join(overlap_otu, by = "otu")

top_overlap_otus_hm <- top_agg_otu_subset %>% 
  group_by(group, otu_color_name) %>% 
  summarize(median=median(agg_rel_abund + 1/10000),`.groups` = "drop") %>%  #Add small value (1/2Xsubssampling parameter) so that there are no infinite values with log transformation
  ggplot()+
  geom_tile(aes(x = group, y=otu_color_name, fill=median))+
  labs(title=NULL,
       x=NULL,
       y=NULL)+
  scale_fill_distiller(trans = "log10",palette = "YlGnBu", direction = 1, name = "Relative \nAbundance", breaks=c(1e-4, 1e-3, 1e-2, 1e-1, 1), labels=c(1e-2, 1e-1, 1, 10, 100), limits = c(1/10000, 1))+
  theme_classic()+
  scale_x_discrete(label = c("Case", "Diarrheal Control", "Non-Diarrheal Control"))+
  theme(plot.title=element_text(hjust=0.5),
        axis.text.x = element_text(angle = 45, hjust = 1), #Angle axis labels
        axis.text.y = element_markdown(), #Have only the OTU names show up as italics
        text = element_text(size = 16)) # Change font size for entire plot
save_plot("results/figures/feat_imp_overlap_otus_abund.png", top_overlap_otus_hm, base_height =8, base_width = 6)

#OTUs that are unique to each model
no_overlap_otu <- read_csv("data/process/ml_rf_top_otus_no_overlap.csv")
no_overlap_otus <- no_overlap_otu %>% pull(otu) #list of otus
cvdc_otus <- no_overlap_otu %>% filter(model == "CvDC") %>% pull(otu)
cvndc_otus <- no_overlap_otu %>% filter(model == "CvNDC") %>% pull(otu)
dcvndc_otus <- no_overlap_otu %>% filter(model == "DCvNDC") %>% pull(otu) 

#Filter otu data to just otus of interest, join to overlap_otu to add overlap and color columns
no_overlap_agg_otu_subset <- agg_otu_data %>% 
  filter(otu %in% no_overlap_otus) %>% 
  left_join(no_overlap_otu, by = "otu")

#Function to plot OTUs that were unique to each model
#model_otus = list of otus unique to a model
#model_name = name of model in quotes, to be used as title
plot_unique_otus <- function(model_otus, model_name){
  no_overlap_agg_otu_subset %>% 
    filter(otu %in% model_otus) %>% #Select only otus for a specific model
    group_by(group, otu_color_name) %>% 
    mutate(median=median(agg_rel_abund + 1/10000),`.groups` = "drop") %>%  #Add small value (1/2Xsubssampling parameter) so that there are no infinite values with log transformation
    ggplot()+
    geom_tile(aes(x = group, y=otu_color_name, fill=median))+
    labs(title=model_name,
         x=NULL,
         y=NULL)+
    scale_fill_distiller(trans = "log10",palette = "YlGnBu", direction = 1, name = "Relative \nAbundance", breaks=c(1e-4, 1e-3, 1e-2, 1e-1, 1), labels=c(1e-2, 1e-1, 1, 10, 100), limits = c(1/10000, 1))+
    theme_classic()+
    scale_x_discrete(label = c("Case", "Diarrheal Control", "Non-Diarrheal Control"))+
    theme(plot.title=element_text(hjust=0.5),
          axis.text.x = element_text(angle = 45, hjust = 1), #Angle axis labels
          axis.text.y = element_markdown(), #Have only the OTU names show up as italics
          text = element_text(size = 16)) # Change font size for entire plot
}

#Plot the unique OTUs for each model----
cvdc_unique <- plot_unique_otus(cvdc_otus, "Case v DC")  
save_plot("results/figures/feat_imp_unique_CvDC_otus_abund.png", cvdc_unique, base_height =8, base_width = 6)
cvndc_unique <- plot_unique_otus(cvndc_otus, "Case v NDC")  
save_plot("results/figures/feat_imp_unique_CvNDC_otus_abund.png", cvndc_unique, base_height =8, base_width = 6)
dcvndc_unique <- plot_unique_otus(dcvndc_otus, "DC v NDC")  
save_plot("results/figures/feat_imp_unique_DCvNDC_otus_abund.png", dcvndc_unique, base_height =8, base_width = 6)

