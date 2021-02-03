#Load required libraries
library(tidyverse)
library(broom)
library(cowplot)
library(readxl)
library(vegan)
library(glue)
library(ggtext)
library(parallel)
library(pROC)
library(scales)
#library(viridis) #color blind friendly palettes

#Define color scheme----
color_scheme <- c("red", "blue", "grey50") 
legend_groups <- c("case", "diarrheal_control", "nondiarrheal_control")
legend_labels <- c("Case", "Diarrheal Control", "Non-Diarrheal Control")
#Alternative color scheme for detailed_group where C. difficile cases are broken down by stool consistency
color_scheme_detailed <- c("red", "red", "red", "blue", "grey50") 
legend_groups_detailed <- c("diarrheal_case", "nondiarrheal_case", "unknown_case", "diarrheal_control", "nondiarrheal_control")
legend_labels_detailed <- c("Diarrheal Case", "Non-Diarrheal Case", "Unknown Case", "Diarrheal Control", "Non-Diarrheal Control")
  
#Define shape scheme----
shape_scheme <- c(0, 2, 1) #open
shape_scheme <- c(22, 24, 21) #closed
legend_groups #Same as color scheme
legend_labels 
#Alternative shape scheme for detailed_group where C. difficile cases are broken down by stool consistency
shape_scheme_detailed <- c(0, 22, 8, 24, 21) #closed

#Read in metadata
metadata <- read_tsv("data/process/final_CDI_16S_metadata.tsv") %>% 
  rename(sample = `CDIS_Sample ID`) %>% 
  mutate(pbs_added = replace_na(pbs_added, "no")) %>% #All NAs means PBS was not added so change to no
  #Update group to reflect case as anything regardless of stool consistency
  mutate(detailed_group = case_when(cdiff_case == "Case" & `stool_consistency` == "unformed" ~ "diarrheal_case",
                           cdiff_case == "Control" & `stool_consistency` == "unformed" ~ "diarrheal_control",
                           cdiff_case == "Control" & `stool_consistency` == "formed" ~ "nondiarrheal_control",
                           cdiff_case == "Case" & `stool_consistency` == "formed" ~ "nondiarrheal_case", #56 samples that were positive for C. diff and had formed stool consistency
                           cdiff_case == "Case" & `stool_consistency` == "unknown" ~ "unknown_case", #2 cases with unknown stool consistencies
                           TRUE ~ "control")) %>%  #Label rest of samples as control (water and mock samples)
  mutate(detailed_group = fct_relevel(detailed_group, "diarrheal_case", "nondiarrheal_case", "unknown_case", "diarrheal_control", "nondiarrheal_control")) %>% #Specify the order of the detailed group factor
  #Transform variables of interest for PERMANOVA tests into factor variables
  mutate(group = factor(group, levels = unique(as.factor(group))),
         miseq_run = factor(miseq_run, levels = unique(as.factor(miseq_run))),
         plate = factor(plate, levels = unique(as.factor(plate))),
         plate_location = factor(plate_location, levels = unique(as.factor(plate_location))),
         pbs_added = factor(pbs_added, levels = unique(as.factor(pbs_added))))
  

#Functions to subset data frames and format for logistic regression----
#Function to Rescale values to fit between 0 and 1
scale_this <- function(x){
  as.vector(rescale(x))
}

#Narrow dataframe to 2 columns needed, rescale column that will be used to predict group
#df = dataframe to format
#metric = column to use in logistic regression analysis
format_df <- function(df, metric){
  df %>% 
  select(group, {{ metric }}) %>%  #Only require these 2 columns
    mutate(rescale = scale_this({{ metric }})) %>% #Rescale values to fit between 0 and 1
    mutate(group = as.character(group))
}

#Format data for logistic regression:
#Case = CDI Case
#DC = diarrheal control
#NDC = nondiarrheal control
#Function that selects 2 groups to predict with logistic regression. 
#Recode character entries into #s for group column.
#Randomize order of the rows
#df = formatted dataframe with rescaled feature values
subset_Case_NDC <- function(df){
  df %>% 
    filter(group %in% c("case", "nondiarrheal_control")) %>% 
    mutate(group = ifelse(group == "case", 1, 0)) #Requires values to be 0 or 1 instead of characters
}
subset_Case_DC <- function(df){
  df %>% 
  filter(group %in% c("case", "diarrheal_control")) %>% 
  mutate(group = ifelse(group == "case", 1, 0)) #Requires values to be 0 or 1 instead of characters
}
subset_DC_NDC <- function(df){
    df %>% 
    filter(group %in% c("diarrheal_control", "nondiarrheal_control")) %>% 
    mutate(group = ifelse(group == "diarrheal_control", 1, 0)) #Requires values to be 0 or 1 instead of characters
}
#Random order samples:
#df to randomize based on number of rows
randomize <- function(df){
  df[sample(nrow(df)),] #Need column to specify we're only shuffling row order
}

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

