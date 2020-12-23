source("code/utilities.R") #Loads libraries, reads in metadata, functions
library(pROC)
library(scales)

#Read in alpha diversity values from mothur
diversity_data <- read_tsv("data/mothur/cdi.opti_mcc.groups.ave-std.summary") %>%
  filter(method == "ave") %>%
  select(group, sobs, shannon, invsimpson, coverage) %>%
  rename(sample = group) %>% #group is the same as sample in the metadata data frame
  left_join(metadata, by = "sample") #Match only the samples we have sequence data for

#Statistical analysis----
set.seed(19760620) #Same seed used for mothur analysis

#Perform Shapiro-Wilk test to see if diversity data is normally distributed.
#p-value > 0.05 means the data is normally distributed
shapiro.test(diversity_data$shannon) #p-value < 2.2e-16
shapiro.test(diversity_data$invsimpson) #p-value < 2.2e-16
shapiro.test(diversity_data$sobs) #p-value < 2.2e-16
#Use non-parametric tests since data is not normally distributed

#Perform Kruskal-Wallis test with different diversity metrics, followed by pairwise wilcoxon testing
shannon_stats <- diversity_data %>%
  nest(data = everything()) %>% 
  mutate(model=map(data, ~kruskal.test(x=.x$shannon, g=as.factor(.x$group)) %>% tidy())) %>% 
  mutate(median = map(data, get_shannon_median_group)) %>% 
  unnest(c(model, median))  %>% 
  mutate(model=map(data, ~pairwise.wilcox.test(x=.x$shannon, g=as.factor(.x$group), p.adjust.method="BH") %>% 
                     tidy() %>% 
                     mutate(compare=paste(group1, group2, sep="-")) %>% 
                     select(-group1, -group2) %>% 
                     pivot_wider(names_from=compare, values_from=p.value)
  )
  ) %>% 
  unnest(model) %>% 
  select(-data) %>% 
  mutate(diversity_metric = "shannon", .before = statistic)

invsimpson_stats <- diversity_data %>%
  nest(data = everything()) %>% 
  mutate(model=map(data, ~kruskal.test(x=.x$invsimpson, g=as.factor(.x$group)) %>% tidy())) %>% 
  mutate(median = map(data, get_invsimpson_median_group)) %>% 
  unnest(c(model, median))  %>% 
  mutate(model=map(data, ~pairwise.wilcox.test(x=.x$invsimpson, g=as.factor(.x$group), p.adjust.method="BH") %>% 
                     tidy() %>% 
                     mutate(compare=paste(group1, group2, sep="-")) %>% 
                     select(-group1, -group2) %>% 
                     pivot_wider(names_from=compare, values_from=p.value)
  )
  ) %>% 
  unnest(model) %>% 
  select(-data) %>% 
  mutate(diversity_metric = "inverse_simpson", .before = statistic)

richness_stats <- diversity_data %>%
  nest(data = everything()) %>% 
  mutate(model=map(data, ~kruskal.test(x=.x$sobs, g=as.factor(.x$group)) %>% tidy())) %>% 
  mutate(median = map(data, get_sobs_median_group)) %>% 
  unnest(c(model, median))  %>% 
  mutate(model=map(data, ~pairwise.wilcox.test(x=.x$sobs, g=as.factor(.x$group), p.adjust.method="BH") %>% 
                     tidy() %>% 
                     mutate(compare=paste(group1, group2, sep="-")) %>% 
                     select(-group1, -group2) %>% 
                     pivot_wider(names_from=compare, values_from=p.value)
  )
  ) %>% 
  unnest(model) %>% 
  select(-data) %>% 
  mutate(diversity_metric = "richness", .before = statistic)

#Combine diversity stats into one dataframe and export as .tsv
diversity_stats <- shannon_stats %>% 
  add_row(invsimpson_stats) %>% 
  add_row(richness_stats) %>% 
  write_tsv("data/process/diversity_stats.tsv")

#Function to plot different alpha diversity metrics with the following arguments
#alpha_metric: how alpha metric of choice is listed in dataframe. Ex. sobs, shannon, etc.
#y_axis_label: how you want to label the alpha metric on the plot. Ex. "Shannon Diversity Index"
plot_alpha_metric <- function(alpha_metric, y_axis_label){
  diversity_data %>% 
    group_by(group) %>% 
    mutate(median = median({{ alpha_metric }})) %>% #Create column of median values for each group
    ungroup() %>% 
    ggplot(aes(x=group, y = {{ alpha_metric }}, color = group))+
    geom_jitter(shape = 1, size=1, alpha = 0.5, show.legend = FALSE) +
    geom_errorbar(aes(ymax= median, ymin= median), color = "black", size = 1)+#Add line to show median of each point
    labs(title=NULL, 
         x=NULL,
         y=y_axis_label)+
    scale_colour_manual(name=NULL,
                        values=color_scheme,
                        breaks=legend_groups,
                        labels=legend_labels)+
    scale_shape_manual(name=NULL, 
                       values=shape_scheme,
                       breaks=legend_groups,
                       labels=legend_labels)+
    scale_x_discrete(label = c("Case", "Diarrheal Control", "Non-Diarrheal Control"))+
    theme_classic()+
    theme(legend.position = "bottom",
          text = element_text(size = 19),# Change font size for entire plot
          axis.text.x = element_text(angle = 45, hjust = 1), #Angle axis labels
          axis.title.y = element_text(size = 17)) 
}

#Shannon, inverse simpson and richness plots 
shannon_plot <- plot_alpha_metric(shannon, "Shannon Diversity Index")
invsimpson_plot <- plot_alpha_metric(invsimpson, "Inverse Simpson")
richness_plot <- plot_alpha_metric(sobs, "Number of Observed OTUs")

#Alternative alpha diversity plots with cases broken out based on stool consistency
#Function to plot different alpha diversity metrics with the following arguments
#alpha_metric: how alpha metric of choice is listed in dataframe. Ex. sobs, shannon, etc.
#y_axis_label: how you want to label the alpha metric on the plot. Ex. "Shannon Diversity Index"
plot_alpha_metric_detailed <- function(alpha_metric, y_axis_label){
  diversity_data %>% 
    group_by(detailed_group) %>% 
    mutate(median = median({{ alpha_metric }})) %>% #Create column of median values for each group
    ungroup() %>% 
    ggplot(aes(x=detailed_group, y = {{ alpha_metric }}, color = detailed_group))+
    geom_jitter(shape = 1, size=1, alpha = 0.5, show.legend = FALSE) +
    geom_errorbar(aes(ymax= median, ymin= median), color = "black", size = 1)+#Add line to show median of each point
    labs(title=NULL, 
         x=NULL,
         y=y_axis_label)+
    scale_colour_manual(name=NULL,
                        values=color_scheme_detailed,
                        breaks=legend_groups_detailed,
                        labels=legend_labels_detailed)+
    scale_x_discrete(label = c("Diarrheal Case", "Non-Diarrheal Case", "Unknown Case", "Diarrheal Control", "Non-Diarrheal Control"))+
    theme_classic()+
    theme(legend.position = "bottom",
          text = element_text(size = 19),# Change font size for entire plot
          axis.text.x = element_text(angle = 45, hjust = 1), #Angle axis labels
          axis.title.y = element_text(size = 17)) 
}

#Shannon, inverse simpson and richness plots 
shannon_plot_detailed <- plot_alpha_metric_detailed(shannon, "Shannon Diversity Index")
invsimpson_plot_detailed <- plot_alpha_metric_detailed(invsimpson, "Inverse Simpson")
richness_plot_detailed <- plot_alpha_metric_detailed(sobs, "Number of Observed OTUs")

plot_grid(invsimpson_plot, shannon_plot, richness_plot,
          invsimpson_plot_detailed, shannon_plot_detailed, richness_plot_detailed,
          nrow = 2)+
  ggsave("results/figures/alpha_diversity.png", height = 10, width = 8)

#Logistic regression based on Inverse Simpson index----
#Chose Inverse Simpson because that is metric used in Schubert et al. mBio 2014
#Match naming convention used in Schubert et al.
#Resources used as starting point for code: https://github.com/BTopcuoglu/machine-learning-pipelines-r
#https://daviddalpiaz.github.io/r4sl/logistic-regression.html 
#Format data for logistic regression:
#Case = CDI Case
#DC = diarrheal control
#NDC = nondiarrheal control

#See utilities for format_df function. Select metric to use. Rescale values to between 0 & 1
div_format <- format_df(diversity_data, invsimpson) %>% 
  select(-invsimpson) %>% #Tried to do this in function, but wasn't working
  rename(invsimpson = rescale) #Replace rescale name 

#Subset data so that we are only predicting 2 outcomes at a time (see code/utilities.R for more details on funcitons used)
Case_NDC <- randomize(subset_Case_NDC(div_format)) 
Case_DC <- randomize(subset_Case_DC(div_format)) 
DC_NDC <- randomize(subset_DC_NDC(div_format))

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
  model_glm <- glm(group ~ invsimpson, data = train, family = "binomial")
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


