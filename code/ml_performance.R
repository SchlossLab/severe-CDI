source("code/utilities.R") #Loads libraries, reads in metadata, functions

set.seed(19760620) #Same seed used for mothur analysis

#Function to read in model performances:
#file_path = path to performance results file
#taxa_level_name = "genus" or "otu"
#comp_name = name of comparison in quotes
read_perf_results <- function(file_path, taxa_level_name, comp_name){
  read_csv(file_path) %>% 
    mutate(taxa_level = taxa_level_name) %>% 
    mutate(comparison = comp_name)
}
#Read in OTU level model performance:
CvDC_otu <- read_perf_results("results/CvDC/performance_results.csv", 
                              "otu", "Case-DC") 
CvNDC_otu <- read_perf_results("results/CvNDC/performance_results.csv", 
                               "otu", "Case-NDC") 
DCvNDC_otu <- read_perf_results("results/DCvNDC/performance_results.csv", 
                               "otu", "DC-NDC") 
#Read in genus level models performance:
CvDC_genus <- read_perf_results("results/CvDC/genus_level/performance_results.csv",
                                "genus", "Case-DC")
CvNDC_genus <- read_perf_results("results/CvNDC/genus_level/performance_results.csv",
                                "genus", "Case-NDC")
DCvNDC_genus <- read_perf_results("results/DCvNDC/genus_level/performance_results.csv",
                                "genus", "DC-NDC")

#Combine all performance results
perf_results <- CvDC_otu %>% 
  add_row(CvNDC_otu) %>% 
  add_row(DCvNDC_otu) %>% 
  add_row(CvDC_genus) %>% 
  add_row(CvNDC_genus) %>% 
  add_row(DCvNDC_genus)

#Examine logistic regression results
log_results <- perf_results %>% 
  filter(method == "glmnet") %>% 
  group_by(comparison, taxa_level) %>% 
  summarize(median = median(AUC))
  
#Examine random forest results
rf_results <- perf_results %>% 
  filter(method == "rf") %>% 
  group_by(comparison, taxa_level) %>% 
  summarize(median = median(AUC))
