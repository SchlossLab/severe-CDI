source("workflow/scripts/utilities.R") #Loads libraries, reads in metadata, functions

#Read in alpha diversity values from mothur
diversity_data <- read_tsv("data/mothur/cdi.opti_mcc.groups.ave-std.summary") %>%
  filter(method == "ave") %>%
  select(group, sobs, shannon, invsimpson, coverage) %>%
  rename(sample = group) %>% #group is the same as sample in the metadata data frame
  left_join(cdi_metadata, by = "sample") %>%  #Match only the samples we have sequence data for
  filter(group == "case") %>% #Filter to only include diversity data from cases
  filter(!sample %in% contam_samples)  #Remove 2 contaminated samples

#Statistical analysis----
set.seed(19760620) #Same seed used for mothur analysis

#Examine diversity data in CDI cases split into groups based on IDSA severity
#Create mikropml data to classify IDSA severity status with OTU level data ----
#Read in IDSA severity results & join to OTU data frame
idsa_diversity <- read_csv("data/process/case_idsa_severity.csv") %>%
  left_join(diversity_data, by = "sample")

#Function to plot different alpha diversity metrics with the following arguments
#alpha_metric: how alpha metric of choice is listed in dataframe. Ex. sobs, shannon, etc.
#y_axis_label: how you want to label the alpha metric on the plot. Ex. "Shannon Diversity Index"
plot_alpha_metric_idsa <- function(alpha_metric, y_axis_label){
  idsa_diversity %>%
    group_by(idsa_severity) %>%
    mutate(median = median({{ alpha_metric }})) %>% #Create column of median values for each group
    ungroup() %>%
    ggplot(aes(x=idsa_severity, y = {{ alpha_metric }}, color = idsa_severity))+
    geom_jitter(shape = 1, size=1, alpha = 0.5, show.legend = FALSE) +
    geom_errorbar(aes(ymax= median, ymin= median), color = "black", size = 1)+#Add line to show median of each point
    labs(title=NULL,
         x=NULL,
         y=y_axis_label)+
    scale_colour_manual(name=NULL,
                        values=color_scheme,
                        breaks=legend_idsa,
                        labels=legend_labels)+
    scale_x_discrete(label = c("Not Severe", "IDSA Severe"))+
    theme_classic()+
    theme(legend.position = "bottom",
          text = element_text(size = 19),# Change font size for entire plot
          axis.text.x = element_text(angle = 45, hjust = 1), #Angle axis labels
          axis.title.y = element_text(size = 17))
}

#Shannon, inverse simpson and richness plots
idsa_shannon_plot <- plot_alpha_metric_idsa(shannon, "Shannon Diversity Index")
idsa_invsimpson_plot <- plot_alpha_metric_idsa(invsimpson, "Inverse Simpson")
idsa_richness_plot <- plot_alpha_metric_idsa(sobs, "Number of Observed OTUs")

#Inverse simpson
plot_grid(idsa_invsimpson_plot)+
  ggsave("results/figures/idsa_alpha_inv_simpson.png", height = 5, width = 4.5)
#Richness
plot_grid(idsa_richness_plot)+
  ggsave("results/figures/idsa_alpha_richness.png", height = 5, width = 4.5)
