source("code/utilities.R") #Loads libraries, reads in metadata, functions

#Have PCoA outputs from mothur based on Bray-Curtis or Jensen-Shannon divergence distance matrices
#Also, have nmds output based on the 2 distance matrices. NMDS was used in the Schubert et al. mBio 2014 paper

#Function to read in ordination (ord) values from mothur
import_ord <- function(file_path){
  read_tsv(file_path) %>%
    select(group, axis1, axis2) %>% #Limit to 2 PCoA axes
    rename(sample = group) %>% #group is the same as id in the metadata data frame
    left_join(metadata, by= "sample") #merge metadata and PCoA data frames
}
#Function to read in PCoA axis values from mothur for the percent variation represented by each PCoA axis
axis_ord <- function(file_path, select_axis){
  read_tsv(file_path) %>%
    filter(axis == select_axis) %>%
    pull(loading) %>% round(digits = 1) #Pull value & round to 1 decimal
}

#Function to plot PCoA data
plot_pcoa <- function(pcoa_df, axis1_label, axis2_label){
  pcoa_df %>%
    ggplot(aes(x=axis1, y=axis2, color = group, fill = group, shape = group))+
    geom_point(size=2, alpha = 0.5)+
    labs(x = paste("PCoA 1 (", axis1_label, "%)", sep = ""), #Annotations for each axis from loadings file
         y = paste("PCoA 2 (", axis2_label,"%)", sep = ""))+
    scale_colour_manual(name=NULL,
                        values=color_scheme,
                        breaks=legend_groups,
                        labels=legend_labels)+
    scale_fill_manual(name=NULL,
                      values=color_scheme,
                      breaks=legend_groups,
                      labels=legend_labels)+
    scale_shape_manual(name=NULL,
                       values=shape_scheme,
                       breaks=legend_groups,
                       labels=legend_labels)+
    theme_classic() +
    theme(text = element_text(size = 16),
          legend.position = "bottom")
}

#Plot NMDS
plot_nmds <- function(nmds_df){
  nmds_df %>%
  ggplot(aes(x=axis1, y=axis2, color = group, fill = group, shape = group))+
  geom_point(size=2, alpha = 0.5)+
  coord_fixed()+
  labs(x = "NMDS Axis 1",
       y = "NMDS Axis 2")+
  scale_colour_manual(name=NULL,
                      values=color_scheme,
                      breaks=legend_groups,
                      labels=legend_labels)+
  scale_fill_manual(name=NULL,
                    values=color_scheme,
                    breaks=legend_groups,
                    labels=legend_labels)+
  scale_shape_manual(name=NULL,
                     values=shape_scheme,
                     breaks=legend_groups,
                     labels=legend_labels)+
  theme_classic() +
  theme(text = element_text(size = 16),
        legend.key.height = unit(0.25, "cm"),
        legend.position = "bottom")

}

#Read in PCoA values from mothur
bc_pcoa <- import_ord("data/mothur/cdi.opti_mcc.braycurtis.0.03.lt.ave.pcoa.axes")
bc_axis1 <- axis_ord("data/mothur/cdi.opti_mcc.braycurtis.0.03.lt.ave.pcoa.loadings", 1)
bc_axis2 <- axis_ord("data/mothur/cdi.opti_mcc.braycurtis.0.03.lt.ave.pcoa.loadings", 2)
#Bray-Curtis PCoA----
bc_pcoa_plot <- plot_pcoa(bc_pcoa, bc_axis1, bc_axis2)+
  ggsave("results/figures/pcoa_bc.png", height = 6, width = 6)

#Read in nmds values
bc_nmds <- import_ord("data/mothur/cdi.opti_mcc.braycurtis.0.03.lt.ave.nmds.axes")
#No percent variation labels associated with NMDS ordination
#Jensen-Shannon divergence NMDS----
bc_nmds_plot <- plot_nmds(bc_nmds)+
  ggsave("results/figures/nmds_bc.png", height = 6, width = 6)

#Jensen-Shannon divergence PCoA----
jsd_pcoa <- import_ord("data/mothur/cdi.opti_mcc.jsd.0.03.lt.ave.pcoa.axes")
jsd_axis1 <- axis_ord("data/mothur/cdi.opti_mcc.jsd.0.03.lt.ave.pcoa.loadings", 1)
jsd_axis2 <- axis_ord("data/mothur/cdi.opti_mcc.jsd.0.03.lt.ave.pcoa.loadings", 2)
jsd_pcoa_plot <- plot_pcoa(jsd_pcoa, jsd_axis1, jsd_axis2)+
  ggsave("results/figures/pcoa_bc.png", height = 6, width = 6)

#Read in JSD NMDS results
jsd_nmds <- import_ord("data/mothur/cdi.opti_mcc.jsd.0.03.lt.ave.nmds.axes")
#No percent variation labels associated with NMDS ordination
#Jensen-Shannon divergence NMDS----
jsd_nmds_plot <- plot_nmds(jsd_nmds)+
  ggsave("results/figures/nmds_jsd.png", height = 6, width = 6)
