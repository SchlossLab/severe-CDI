source("code/utilities.R") #Loads libraries, reads in metadata, functions

set.seed(19760620) #Same seed used for mothur analysis

#Used to figure out color scale:
values = brewer_pal("qual", palette = "Dark2")(4)

#Function to read in model performances:
#file_path = path to performance results file
#taxa_level_name = "genus" or "otu"
#comp_name = name of comparison in quotes
read_perf_results <- function(file_path, taxa_level_name, comp_name){
  read_csv(file_path) %>% 
    mutate(taxa_level = taxa_level_name) %>% 
    mutate(comparison = comp_name)
}

#Examine IDSA severity performance results----
#Read in OTU level model performance:
IDSA_otu <- read_perf_results("results/idsa_severity/performance_results.csv", 
                              "otu", "idsa_severity")

#Examine OTU level results across different ML methods
IDSA_otu_results <- IDSA_otu %>% 
  filter(taxa_level == "otu") %>% 
  group_by(method) %>% 
  summarize(median = median(AUC)) %>% 
  arrange(desc(median))

#Plot performance for all methods with OTU input data----
performance_otu_idsa <- IDSA_otu %>% 
  filter(taxa_level == "otu") %>% 
  mutate(method = fct_relevel(method, c("rf", "glmnet", "svmRadial"))) %>% #Reorder methods so left to right is in order of descending AUC
  ggplot(aes(x = taxa_level, y = prAUC, color = method)) +
  geom_boxplot(alpha=0.5, fatten = 4) +
  geom_hline(yintercept = 0.5, linetype="dashed") +
  scale_color_manual(values = c("#D95F02", "#1B9E77", "#E7298A"),                     
                     breaks=c("rf", "glmnet", "svmRadial"), 
                     labels = c("random forest", "logistic regression", "support vector machine")) +
  scale_y_continuous(name = "prAUC",
                     breaks = seq(0.4, 1, 0.1),
                     limits=c(0.4, 1),
                     expand=c(0,0)) +
  labs(x = NULL)+
  theme_bw()  +
  theme(legend.position = "bottom",
        text = element_text(size = 19),# Change font size for entire plot
        axis.ticks.x = element_blank(), #Remove x axis ticks
        axis.text.x = element_blank(), #Remove x axis text (all models are at the OTU level)
        strip.background = element_blank()) +#Make Strip backgrounds blank
  guides(color=guide_legend(nrow = 2))+   #Legend in 2 rows so it doesn't get cut off 
  ggsave("results/figures/ml_performance_idsa_otu.png", height = 5, width = 7)

performance_otu_idsa_AUC <- IDSA_otu %>% 
  filter(taxa_level == "otu") %>% 
  mutate(method = fct_relevel(method, c("glmnet", "rf", "svmRadial"))) %>% #Reorder methods so left to right is in order of descending AUC
  ggplot(aes(x = taxa_level, y = AUC, color = method)) +
  geom_boxplot(alpha=0.5, fatten = 4) +
  geom_hline(yintercept = 0.5, linetype="dashed") +
  scale_color_manual(values = c("#1B9E77", "#D95F02", "#E7298A"),                     
                     breaks=c("glmnet", "rf", "svmRadial"), 
                     labels = c( "logistic regression", "random forest", "support vector machine")) +
  scale_y_continuous(name = "AUC",
                     breaks = seq(0.4, 1, 0.1),
                     limits=c(0.4, 1),
                     expand=c(0,0)) +
  labs(x = NULL)+
  theme_bw()  +
  theme(legend.position = "bottom",
        text = element_text(size = 19),# Change font size for entire plot
        axis.ticks.x = element_blank(), #Remove x axis ticks
        axis.text.x = element_blank(), #Remove x axis text (all models are at the OTU level)
        strip.background = element_blank()) +#Make Strip backgrounds blank
  guides(color=guide_legend(nrow = 2))+
  ggsave("results/figures/ml_performance_idsa_otu_AUC.png", height = 5, width = 7)
