source("code/utilities.R") #Loads libraries, reads in metadata, functions

#Read in pcoa values from mothur
pcoa_data <- read_tsv("data/mothur/cdi.opti_mcc.braycurtis.0.03.lt.ave.pcoa.axes") %>%
  select(group, axis1, axis2) %>% #Limit to 2 PCoA axes
  rename(sample = group) %>% #group is the same as id in the metadata data frame
  left_join(metadata, by= "sample") #merge metadata and PCoA data frames

#Read in .loadings file to add percent variation represented by PCoA axis
axis_labels <- read_tsv("data/mothur/cdi.opti_mcc.braycurtis.0.03.lt.ave.pcoa.loadings")
axis1 <- axis_labels %>% filter(axis == 1) %>% pull(loading) %>% round(digits = 1) #Pull value & round to 1 decimal
axis2 <- axis_labels %>% filter(axis == 2) %>% pull(loading) %>% round(digits = 1) #Pull value & round to 1 decimal

#Plot PCoA data 
pcoa_plot <- pcoa_data %>% 
  ggplot(aes(x=axis1, y=axis2, color = group, shape = group))+
  geom_point(size=2, alpha = 0.5)+
  labs(x = paste("PCoA 1 (", axis1, "%)", sep = ""), #Annotations for each axis from loadings file
       y = paste("PCoA 2 (", axis2,"%)", sep = ""))+
  scale_colour_manual(name=NULL,
                      values=color_scheme,
                      breaks=legend_groups,
                      labels=legend_labels)+
  scale_shape_manual(name=NULL, 
                     values=shape_scheme,
                     breaks=legend_groups,
                     labels=legend_labels)+
  theme_classic()

