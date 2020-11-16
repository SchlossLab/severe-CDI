library(tidyverse)
library(cowplot)

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

#Read in metadata
metadata <- read_tsv("data/process/final_CDI_16S_metadata.tsv") %>% 
  rename(sample = `CDIS_Sample ID`)

#Plot the Laplace measurement first.
laplace_plot <- dmm_fit %>% 
  ggplot()+
  geom_line(aes(x = K, y = Laplace))+
  theme_classic()
save_plot(filename = "exploratory/notebook/cdi_community_type_laplace.png", laplace_plot)


#Read in best cluster for each sample
sample_best_cluster_fit <- read_tsv("data/process/cdi.subsample.genus.genus.dmm.mix.design", col_names=c("sample", "best_fitting_cluster")) %>% 
  left_join(metadata, by = "sample")

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
  group_by(best_fitting_cluster, group) %>% 
  summarize(group_cluster_total = n()) %>% 
  #Make a new variable % group per cluster based on total group numbers
  mutate(percent_group = case_when(group == "case" ~ (group_cluster_total/1517)*100,
                                           group == "diarrheal_control" ~ (group_cluster_total/1506)*100,
                                           group == "nondiarrheal_control" ~ (group_cluster_total/909)*100,
                                           TRUE ~ 0)) %>% #No samples should fall into this category
  ggplot()+
  geom_tile(aes(x=best_fitting_cluster, y=group, fill=percent_group))+
  theme_classic()+
  scale_fill_distiller(palette = "YlGnBu", direction = 1) 

percent_cluster <- sample_best_cluster_fit %>% 
  group_by(best_fitting_cluster, group) %>% 
  summarize(group_cluster_total = n()) %>%
  #Make a new variable % group per cluster based on total cluster numbers
  mutate(percent_cluster = case_when(best_fitting_cluster == "Partition_1" ~ (group_cluster_total/221)*100,
                                     best_fitting_cluster == "Partition_10" ~ (group_cluster_total/421)*100,
                                     best_fitting_cluster == "Partition_11" ~ (group_cluster_total/464)*100,
                                     best_fitting_cluster == "Partition_12" ~ (group_cluster_total/81)*100,
                                     best_fitting_cluster == "Partition_2" ~ (group_cluster_total/367)*100,
                                     best_fitting_cluster == "Partition_3" ~ (group_cluster_total/283)*100,
                                     best_fitting_cluster == "Partition_4" ~ (group_cluster_total/504)*100,
                                     best_fitting_cluster == "Partition_5" ~ (group_cluster_total/243)*100,
                                     best_fitting_cluster == "Partition_6" ~ (group_cluster_total/163)*100,
                                     best_fitting_cluster == "Partition_7" ~ (group_cluster_total/421)*100,
                                     best_fitting_cluster == "Partition_8" ~ (group_cluster_total/280)*100,
                                     best_fitting_cluster == "Partition_9" ~ (group_cluster_total/484)*100,
                                     TRUE ~ 0)) %>% #No samples should fall into this category
  mutate(group = factor(group, levels = unique(as.factor(group)))) %>% #Transform group variable into factor variable
  mutate(group = fct_relevel(group, "diarrheal_control", "nondiarrheal_control", "case")) %>% #Specify the order of the groups
  ggplot()+
  geom_tile(aes(x=best_fitting_cluster, y=group, fill=percent_cluster))+
  theme_classic()+
  scale_fill_distiller(palette = "YlGnBu", direction = 1)

test <- sample_best_cluster_fit %>% 
  group_by(best_fitting_cluster, group) %>% 
  summarise(n=n()) %>% 
  pivot_wider()
  mutate(percent_of_partition=n/sum(n)*100)
  
test <- sample_best_cluster_fit %>% 
    group_by(best_fitting_cluster, group) %>% 
    summarise(n=n()) %>% 
    pivot_wider()
  mutate(percent_of_group=n/sum(n)*100)