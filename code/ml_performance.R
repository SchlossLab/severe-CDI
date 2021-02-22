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

#Read in model performance for subset of OTUs identified by lefse analysis
CvDC_lefse <- read_perf_results("results/CvDC/lefse_otus/performance_results.csv",
                                "lefse_otus", "Case-DC")
CvNDC_lefse <- read_perf_results("results/CvNDC/lefse_otus/performance_results.csv",
                                 "lefse_otus", "Case-NDC")
DCvNDC_lefse <- read_perf_results("results/DCvNDC/lefse_otus/performance_results.csv",
                                  "lefse_otus", "DC-NDC")

#Combine all performance results
perf_results <- CvDC_otu %>% 
  add_row(CvNDC_otu) %>% 
  add_row(DCvNDC_otu) %>% 
  add_row(CvDC_genus) %>% 
  add_row(CvNDC_genus) %>% 
  add_row(DCvNDC_genus) %>% 
  add_row(CvDC_lefse) %>% 
  add_row(CvNDC_lefse) %>% 
  add_row(DCvNDC_lefse) %>% 
  mutate(taxa_level= factor(taxa_level, levels = unique(as.factor(taxa_level))))#transform taxa_level into a factor

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

#Plot performance for all methods with all types of input data----
performance <- perf_results %>% 
  mutate(taxa_level = fct_relevel(taxa_level, c("lefse_otus", "genus", "otu")),
         comparison = fct_relevel(comparison, c("Case-DC", "DC-NDC", "Case-NDC"))) %>% 
  ggplot(aes(x = taxa_level, y = AUC, color = method)) +
  geom_boxplot(alpha=0.5, fatten = 4) +
  facet_wrap(~comparison)+
  geom_hline(yintercept = 0.5, linetype="dashed") +
 scale_color_manual(values = brewer_pal("qual", palette = "Dark2")(4),
                    breaks=c("glmnet", "rf", "rpart2", "svmRadial"), 
                    labels = c("logistic regression", "random forest", "decision tree", "support vector machine")) +
  scale_y_continuous(name = "AUC",
                     breaks = seq(0.4, 1, 0.1),
                     limits=c(0.4, 1),
                     expand=c(0,0)) +
  labs(x = NULL)+
  theme_bw()  +
  theme(legend.position = "bottom",
        strip.background = element_blank()) +#Make Strip backgrounds blank
  ggsave("results/figures/ml_performance.png", height = 5, width = 8)

