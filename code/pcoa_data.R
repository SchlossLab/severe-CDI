source("code/utilities.R") #Loads libraries, reads in metadata, functions

#Have PCoA outputs from mothur based on Bray-Curtis or Jensen-Shannon divergence distance matrices
#Also, have nmds output based on Jensen-Shannon divergence distance matrix

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
    theme(text = element_text(size = 16))
}

#Read in PCoA values from mothur
#Bray-Curtis PCoA
bc_pcoa <- import_ord("data/mothur/cdi.opti_mcc.braycurtis.0.03.lt.ave.pcoa.axes")
bc_axis1 <- axis_ord("data/mothur/cdi.opti_mcc.braycurtis.0.03.lt.ave.pcoa.loadings", 1)
bc_axis2 <- axis_ord("data/mothur/cdi.opti_mcc.braycurtis.0.03.lt.ave.pcoa.loadings", 2)
bc_pcoa_plot <- plot_pcoa(bc_pcoa, bc_axis1, bc_axis2)

#Perform adonis----
#Read in Bray-Curtis distance matrix
bc_dist <- read_dist("data/mothur/cdi.opti_mcc.braycurtis.0.03.lt.std.dist")
bc_variables <- tibble(sample = attr(bc_dist, "Labels")) %>%
  left_join(metadata, by = "sample")
detectCores()
detectCores("system")
detectCores("mc.cores")
bc_adonis <- adonis(bc_dist~group, data = bc_variables, permutations = 1000, parallel = 20)
bc_adonis
#Select the adonis results dataframe and transform rownames into effects column
bc_adonis_table <- as_tibble(rownames_to_column(bc_adonis$aov.tab, var = "effects")) %>%
  write_tsv("data/process/permanova_bc_group.tsv")#Write results to .tsv file
bc_adonis <- adonis(bc_dist~miseq_run, data = bc_variables, permutations = 1000, parallel = 20)
bc_adonis
#Select the adonis results dataframe and transform rownames into effects column
bc_adonis_table <- as_tibble(rownames_to_column(bc_adonis$aov.tab, var = "effects")) %>%
  write_tsv("data/process/permanova_bc_miseq_run.tsv")#Write results to .tsv file
bc_adonis <- adonis(bc_dist~plate, data = bc_variables, permutations = 1000, parallel = 20)
bc_adonis
#Select the adonis results dataframe and transform rownames into effects column
bc_adonis_table <- as_tibble(rownames_to_column(bc_adonis$aov.tab, var = "effects")) %>%
  write_tsv("data/process/permanova_bc_plate.tsv")#Write results to .tsv file
bc_adonis <- adonis(bc_dist~plate_location, data = bc_variables, permutations = 1000, parallel = 20)
bc_adonis
#Select the adonis results dataframe and transform rownames into effects column
bc_adonis_table <- as_tibble(rownames_to_column(bc_adonis$aov.tab, var = "effects")) %>%
  write_tsv("data/process/permanova_bc_plate_location.tsv")#Write results to .tsv file
bc_adonis <- adonis(bc_dist~pbs_added, data = bc_variables, permutations = 1000, parallel = 20)
bc_adonis
#Select the adonis results dataframe and transform rownames into effects column
bc_adonis_table <- as_tibble(rownames_to_column(bc_adonis$aov.tab, var = "effects")) %>%
  write_tsv("data/process/permanova_bc_pbs_added.tsv")#Write results to .tsv file


bc_adonis <- adonis(bc_dist~group/(miseq_run*plate*plate_location*pbs_added), data = bc_variables, permutations = 1000, parallel = 20)
bc_adonis
#Select the adonis results dataframe and transform rownames into effects column
bc_adonis_table <- as_tibble(rownames_to_column(bc_adonis$aov.tab, var = "effects")) %>%
  write_tsv("data/process/permanova_bc.tsv")#Write results to .tsv file

#Jensen-Shannon divergence PCoA
jsd_pcoa <- import_ord("data/mothur/cdi.opti_mcc.jsd.0.03.lt.ave.pcoa.axes")
jsd_axis1 <- axis_ord("data/mothur/cdi.opti_mcc.jsd.0.03.lt.ave.pcoa.loadings", 1)
jsd_axis2 <- axis_ord("data/mothur/cdi.opti_mcc.jsd.0.03.lt.ave.pcoa.loadings", 2)
jsd_pcoa_plot <- plot_pcoa(jsd_pcoa, jsd_axis1, jsd_axis2)

jsd_nmds <- import_ord("data/mothur/cdi.opti_mcc.jsd.0.03.lt.ave.nmds.axes")
#No percent variation labels associated with NMDS ordination
jsd_nmds_plot <- jsd_nmds %>%
  ggplot(aes(x=axis1, y=axis2, color = group, fill = group, shape = group))+
  geom_point(size=2, alpha = 0.5)+
  labs(x = "Axis 1",
       y = "Axis 2")+
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
  theme(text = element_text(size = 16))
