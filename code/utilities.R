#Load required libraries
library(tidyverse)
library(broom)
library(cowplot)
library(readxl)
library(vegan)

#Define color scheme----
color_scheme <- c("red", "blue", "gray60") 
legend_groups <- c("case", "diarrheal_control", "nondiarrheal_control")
legend_labels <- c("Case", "Diarrheal Control", "Non-Diarrheal Control")

#Define shape scheme----
shape_scheme <- c(1, 2, 0) 
legend_groups #Same as color scheme
legend_labels 


#Read in metadata
metadata <- read_tsv("data/process/final_CDI_16S_metadata.tsv") %>% 
  rename(sample = `CDIS_Sample ID`)

#Functions used in statistical analysis----
#Function to calculate the median shannon values from a dataframe (x) grouped by treatment
get_shannon_median_group <- function(x){
  x %>%
    group_by(group) %>%
    summarize(median=median(shannon)) %>%
    spread(key=group, value=median)
}

#Function to calculate the median inverse simpson values from a dataframe (x) grouped by treatment
get_invsimpson_median_group <- function(x){
  x %>%
    group_by(group) %>%
    summarize(median=median(invsimpson)) %>%
    spread(key=group, value=median)
}

#Function to calculate the median sobs (richness) values from a dataframe (x) grouped by treatment
get_sobs_median_group <- function(x){
  x %>%
    group_by(group) %>%
    summarize(median=median(sobs)) %>%
    spread(key=group, value=median)
}

#Function to calculate the median agg_rel_abund values from a dataframe (x) grouped by treatment
get_rel_abund_median_group <- function(x){
  x %>%
    group_by(group) %>%
    summarize(median=median(agg_rel_abund)) %>%
    spread(key=group, value=median)
}

#Function to pull significant taxa (adjusted p value < 0.05) after statistical analysis
pull_significant_taxa <- function(dataframe, taxonomic_level){
  dataframe %>%
    filter(p.value.adj <= 0.05) %>%
    pull({{ taxonomic_level }}) #Embracing transforms taxonomic_level argument into a column name
}

#Functions related to 16S rRNA sequencing analysis----
#Function to format distance matrix generated with mothur for use in R.
#Source: Sze et al. mSphere 2019 https://github.com/SchlossLab/Sze_PCRSeqEffects_mSphere_2019/blob/master/code/vegan_analysis.R
read_dist <- function(dist_file_name){
  
  linear_data <- scan(dist_file_name, what="character", sep="\n", quiet=TRUE)
  
  n_samples <- as.numeric(linear_data[1])
  linear_data <- linear_data[-1]
  
  samples <- str_replace(linear_data, "\t.*", "")
  linear_data <- str_replace(linear_data, "[^\t]*\t", "")
  linear_data <- linear_data[-1]
  
  distance_matrix <- matrix(0, nrow=n_samples, ncol=n_samples)
  
  for(i in 1:(n_samples-1)){
    row <- as.numeric(unlist(str_split(linear_data[i], "\t")))
    distance_matrix[i+1,1:length(row)] <- row
  }
  
  distance_matrix <- distance_matrix + t(distance_matrix)
  rownames(distance_matrix) <- samples
  
  as.dist(distance_matrix)
}

#Function to find which significant otus/genera/families are shared
intersect_all <- function(a,b,...){
  Reduce(intersect, list(a,b,...))
}