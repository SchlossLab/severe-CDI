source("code/utilities.R") #Loads libraries, reads in metadata, functions

set.seed(19760620) #Same seed used for mothur analysis

#Create .shared and .taxonomy files at the genus level to use in Dirichlet Multinomial Mixture analysis
#Shared file:
shared <- read.delim('data/mothur/cdi.opti_mcc.0.03.subsample.shared', header=T, sep='\t') %>%
  select(-label, -numOtus) %>% 
  gather(-Group, key=OTU, value=count)

#Read in taxonomy and select genus level:
taxonomy <- read_tsv(file="data/mothur/cdi.taxonomy") %>% 
  select(-Size) %>%
  mutate(Taxonomy=str_replace_all(Taxonomy, "\\(\\d*\\)", "")) %>%
  mutate(Taxonomy=str_replace_all(Taxonomy, ";$", "")) %>%
  separate(Taxonomy, c("kingdom", "phylum", "class", "order", "family", "genus"), sep=';') %>%
  select(OTU, "genus") %>%
  rename(taxon = genus)

unique_taxonomy <- taxonomy %>%
  select(taxon) %>%
  unique() %>%
  mutate(otu = paste0("Otu", str_pad(1:nrow(.), width=nchar(nrow(.)), pad="0")))

#Join genus level taxonomy to shared to create shared file at the genus level:
genus_shared <- inner_join(shared, taxonomy, by="OTU") %>%
  group_by(taxon, Group) %>%
  summarize(count = sum(count)) %>%
  ungroup() %>%
  inner_join(., unique_taxonomy) %>%
  select(-taxon) %>%
  spread(otu, count) %>%
  mutate(label="genus", numOtus=ncol(.)-1) %>%
  select(label, Group, numOtus, everything())
write_tsv(genus_shared, path = "data/process/cdi.subsample.genus.shared")

select(genus_shared, -label, -numOtus) %>%
  gather(otu, count, -Group) %>%
  group_by(otu) %>%
  summarize(count=sum(count)) %>%
  inner_join(., unique_taxonomy) %>%
  rename("OTU"="otu", "Size"="count", "Taxonomy"="taxon") %>%
  write_tsv(path ="data/process/cdi.genus.taxonomy")

#Read in outputs from mothur's get.communitytype function----
#Read in data to evaluate community type fit depending on the number of community types
dmm_fit <- read_tsv("data/process/cdi.subsample.genus.genus.dmm.mix.fit")

#Plot the Laplace measurement first.
laplace_plot <- dmm_fit %>% 
  ggplot()+
  geom_line(aes(x = K, y = Laplace))+
  theme_classic()
save_plot(filename = "exploratory/notebook/cdi_community_type_laplace.png", laplace_plot)


#Read in best cluster for each sample
sample_best_cluster_fit <- read_tsv("data/process/cdi.subsample.genus.genus.dmm.mix.design", col_names=c("sample", "best_fitting_cluster")) %>% 
  left_join(metadata, by = "sample") %>% 
  mutate(cluster=str_replace(best_fitting_cluster,"Partition_(\\d*)","\\1")) %>% #Add a column with just the cluster number
  mutate(cluster= as.numeric(cluster)) #Transform cluster variable type from character to numeric

best_cluster_group_plot <- sample_best_cluster_fit %>% 
  group_by(group) %>% 
  count(best_fitting_cluster) %>% 
  ggplot()+
  geom_boxplot(aes(x=best_fitting_cluster, y=n, color= group))+
  coord_flip()+
  theme_classic()+
  geom_vline(xintercept = c((1:12) - 0.5 ), color = "grey")  # Add gray lines to clearly separate partitions

#Figure out percent cases, nondiarrheal controls and diarrheal controls by cluster
percent_group <- sample_best_cluster_fit %>% 
  group_by(cluster, group) %>% 
  summarize(group_cluster_total = n()) %>% 
  #Make a new variable % group per cluster based on total group numbers
  mutate(percent_group = case_when(group == "case" ~ (group_cluster_total/1517)*100,
                                           group == "diarrheal_control" ~ (group_cluster_total/1506)*100,
                                           group == "nondiarrheal_control" ~ (group_cluster_total/909)*100,
                                           TRUE ~ 0)) %>% #No samples should fall into this category
  ggplot()+
  geom_tile(aes(x=cluster, y=group, fill=percent_group))+
  scale_y_discrete(label = c("Diarrheal Control", "Non-Diarrheal Control", "Case"))+
  theme_classic()+
#  scale_fill_viridis(name = "% Group") Alternative color scale
  scale_fill_distiller(palette = "YlGnBu", direction = 1, name = "% Group") 

percent_cluster <- sample_best_cluster_fit %>% 
  group_by(cluster, group) %>% 
  summarize(group_cluster_total = n()) %>%
  #Make a new variable % group per cluster based on total cluster numbers
  mutate(percent_cluster = case_when(cluster == "1" ~ (group_cluster_total/221)*100,
                                     cluster == "10" ~ (group_cluster_total/421)*100,
                                     cluster == "11" ~ (group_cluster_total/464)*100,
                                     cluster == "12" ~ (group_cluster_total/81)*100,
                                     cluster == "2" ~ (group_cluster_total/367)*100,
                                     cluster == "3" ~ (group_cluster_total/283)*100,
                                     cluster == "4" ~ (group_cluster_total/504)*100,
                                     cluster == "5" ~ (group_cluster_total/243)*100,
                                     cluster == "6" ~ (group_cluster_total/163)*100,
                                     cluster == "7" ~ (group_cluster_total/421)*100,
                                     cluster == "8" ~ (group_cluster_total/280)*100,
                                     cluster == "9" ~ (group_cluster_total/484)*100,
                                     TRUE ~ 0)) %>% #No samples should fall into this category
  mutate(group = factor(group, levels = unique(as.factor(group)))) %>% #Transform group variable into factor variable
  mutate(group = fct_relevel(group, "diarrheal_control", "nondiarrheal_control", "case")) %>% #Specify the order of the groups
  ggplot()+
  geom_tile(aes(x=cluster, y=group, fill=percent_cluster))+
  scale_x_continuous(breaks = c(1:12))+
  scale_y_discrete(label = c("Diarrheal Control", "Non-Diarrheal Control", "Case"))+
  theme_classic()+
#  scale_fill_viridis(name = "% Cluster") Alternate scale
  scale_fill_distiller(palette = "YlGnBu", direction = 1, name = "% Cluster")+
  theme(axis.title.y = element_blank(), #Get rid of y axis title
        axis.title.x = element_blank(), #Get rid of x axis title, text, and ticks. Will combine with bacteria in cluster
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank())

#Alternative with detailed_group which breaks cases down based on stool consistency
percent_group_detailed <- sample_best_cluster_fit %>% 
  group_by(best_fitting_cluster, detailed_group) %>% 
  summarize(group_cluster_total = n()) %>% 
  #Make a new variable % group per cluster based on total group numbers
  mutate(percent_group = case_when(detailed_group == "diarrheal_case" ~ (group_cluster_total/1459)*100,
                                   detailed_group == "nondiarrheal_case " ~ (group_cluster_total/56)*100,
                                   detailed_group == "unknown_case" ~ (group_cluster_total/2)*100,
                                   detailed_group == "diarrheal_control" ~ (group_cluster_total/1506)*100,
                                   detailed_group == "nondiarrheal_control" ~ (group_cluster_total/909)*100,
                                   TRUE ~ 0)) %>% #No samples should fall into this category
  ggplot()+
  geom_tile(aes(x=best_fitting_cluster, y=detailed_group, fill=percent_group))+
  theme_classic()+
  scale_fill_viridis(name = "% Group")
#  scale_fill_distiller(palette = "YlGnBu", direction = 1, name = "% Group")

percent_cluster_detailed <- sample_best_cluster_fit %>% 
  group_by(cluster, detailed_group) %>% 
  summarize(group_cluster_total = n()) %>%
  #Make a new variable % group per cluster based on total cluster numbers
  mutate(percent_cluster = case_when(cluster == "1" ~ (group_cluster_total/221)*100,
                                     cluster == "10" ~ (group_cluster_total/421)*100,
                                     cluster == "11" ~ (group_cluster_total/464)*100,
                                     cluster == "12" ~ (group_cluster_total/81)*100,
                                     cluster == "2" ~ (group_cluster_total/367)*100,
                                     cluster == "3" ~ (group_cluster_total/283)*100,
                                     cluster == "4" ~ (group_cluster_total/504)*100,
                                     cluster == "5" ~ (group_cluster_total/243)*100,
                                     cluster == "6" ~ (group_cluster_total/163)*100,
                                     cluster == "7" ~ (group_cluster_total/421)*100,
                                     cluster == "8" ~ (group_cluster_total/280)*100,
                                     cluster == "9" ~ (group_cluster_total/484)*100,
                                     TRUE ~ 0)) %>% #No samples should fall into this category
  mutate(detailed_group = fct_relevel(detailed_group, "diarrheal_control", "nondiarrheal_control", "nondiarrheal_case", "diarrheal_case", "unknown_case")) %>% #Specify the order of the groups
  ggplot()+
  geom_tile(aes(x=cluster, y=detailed_group, fill=percent_cluster))+
  theme_classic()+
  scale_fill_viridis(name = "% Cluster")
#  scale_fill_distiller(palette = "YlGnBu", direction = 1, name = "% Cluster")

#Exploratory-figure out a better way to calculate percent group and percent cluster
test <- sample_best_cluster_fit %>% 
  group_by(best_fitting_cluster, group) %>% 
  summarise(n=n()) %>% 
  pivot_wider() %>% 
  mutate(percent_of_partition=n/sum(n)*100)
  
test <- sample_best_cluster_fit %>% 
    group_by(best_fitting_cluster, group) %>% 
    summarise(n=n()) %>% 
    pivot_wider() %>% 
  mutate(percent_of_group=n/sum(n)*100)
  
#Examine the bacteria that make up each community type:
#Read in data that indicate the bacteria (at the genus level) membership of the different clusters
community_otus <- read_tsv("data/process/cdi.subsample.genus.genus.dmm.mix.summary") %>% 
  rename("otu" = "OTU") #rename to match otu column in taxonomy
#Read in genus-level taxomy file and clean up genus names
taxonomy <- read_tsv(file="data/process/cdi.genus.taxonomy") %>%
  rename_all(tolower) %>% #remove uppercase from column names
  rename(genus = taxonomy) %>% #Rename taxonomy to genus
  # Clean up genus names  
  mutate(genus=str_replace_all(genus, c('Bacteria_unclassified' = 'Unclassified',
                                        "Clostridium_" = "Clostridium ", #Remove underscores after Clostridium
                                        "_" = " ", #Removes all other underscores
                                        "unclassified" = "unclassified")))
#Join bacteria in clusters to taxonomy file
bacteria_in_clusters <- community_otus %>% 
  left_join(taxonomy, by = "otu") %>% #Join to taxonomy data frame by otu column in order to get the genus name for each OTU
  select(genus,ends_with("mean")) %>% 
  select(-P0.mean)
bacteria_in_clusters_plot <- bacteria_in_clusters %>%   
  slice_head(n=15) %>% 
  add_row(bacteria_in_clusters %>% filter(genus == "Peptostreptococcaceae unclassified")) %>% #Also plot C. difficile OTU (confirm if this is the right one)
  pivot_longer(-genus,names_to="cluster",values_to="relabund") %>% 
  mutate(cluster=str_replace(cluster,"P(\\d*).mean","\\1")) %>% 
  mutate(cluster= as.numeric(cluster)) %>% #Transform cluster variable type from character to numeric
  ggplot() + geom_tile(aes(x=genus,y=cluster,fill=relabund))+
  scale_y_continuous(breaks = c(1:12))+
  labs(y = "Cluster")+
  coord_flip()+
  theme_classic()+
  theme(axis.text.y = element_text(face = "italic"))+
  scale_fill_distiller(palette = "YlGnBu", direction = 1, name = "Relative \nAbundance")+
#  scale_fill_viridis(name = "Relative Abundance")
  theme(axis.title.y = element_blank()) #Get rid of y axis title

#Combine plot of percent of each group that belongs to each cluster and the relative abundances of bacteria in the clusters
#To do: Figure out which OTUs corresond to C. difficile
#Start by checking Otu 25 and Otu 85
#Inspiration for combining plots: Kelly's Code Club: https://github.com/SchlossLab/plot-recreation/tree/key
#Align heat amps
combined_heatmaps <- align_plots(percent_cluster, bacteria_in_clusters_plot, align = 'v', axis = 'b') 
#Combine heat maps
plot_grid(combined_heatmaps[[1]], combined_heatmaps[[2]], rel_heights = c(1, 3), ncol = 1)+
  ggsave("results/figures/community_types.png", height = 6.0, width = 8.5)

#Logistic regression based on community type----
#Cluster = community type
#Match naming convention used in Schubert et al.
#Resources used as starting point for code: https://github.com/BTopcuoglu/machine-learning-pipelines-r
#https://daviddalpiaz.github.io/r4sl/logistic-regression.html 
#Format data for logistic regression:
#Case = CDI Case
#DC = diarrheal control
#NDC = nondiarrheal control

#See utilities for format_df function. Select metric to use. Rescale values to between 0 & 1
cluster_format <- format_df(sample_best_cluster_fit, cluster) %>% 
  select(-cluster) %>% #Tried to do this in function, but wasn't working
  rename(cluster = rescale) #Replace rescale name 

#Subset data so that we are only predicting 2 outcomes at a time (see code/utilities.R for more details on funcitons used)
Case_NDC <- randomize(subset_Case_NDC(cluster_format)) 
Case_DC <- randomize(subset_Case_DC(cluster_format)) 
DC_NDC <- randomize(subset_DC_NDC(cluster_format))

#Function to run logistic regression on different data frames that you input
#random_ordered = formatted dataframe with rows in a random order
log_reg <- function(random_ordered){
  #Number of training samples
  number_training_samples <- ceiling(nrow(random_ordered) * 0.8)
  #Training set
  train <- random_ordered[1:number_training_samples,]
  #Testing set
  test <- random_ordered[(number_training_samples + 1):nrow(random_ordered),]
  #glm model
  model_glm <- glm(group ~ cluster, data = train, family = "binomial")
  #test model
  test_prob <- predict(model_glm, newdata = test, type = "response")
  #Get 95% confidence interval
  ci <- ci.auc(test$group, test_prob, conf.level = 0.95)
  print(ci) #Print out confidence interval
  #Plot roc
  test_roc <- roc(test$group ~ test_prob, plot = TRUE, print.auc = TRUE)
  test_roc
}
#Make ROC curve
Case_NDC_ROC <- log_reg(Case_NDC)
Case_DC_ROC <- log_reg(Case_DC)
DC_NDC_ROC <- log_reg(DC_NDC)

#Seems a lot worse than 2014 paper at discriptinating group.
#Only difference was treating community type as a categorical variable in the model?

