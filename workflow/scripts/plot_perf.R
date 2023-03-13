source("workflow/scripts/log_smk.R")
library(tidyverse)
dat <- read_csv("results/performance_results_aggregated.csv") %>%
    rename(AUROC = AUC,
           AUPRC = prAUC) %>% 
    filter(method == 'rf', dataset == 'int', trainfrac == 0.65) 
perf_plot <- dat %>% 
    filter(metric == 'AUC') %>% 
    rename(trainset = cv_metric_AUC,
           testset = AUROC) %>% 
    pivot_longer(c(trainset, testset),
                 names_to = "data_partition",
                 values_to = 'AUROC'
                 ) %>%
    mutate(
           outcome = case_when(outcome == 'idsa' ~ 'IDSA\n severity',
                               outcome == 'attrib' ~ 'Attributable\n severity',
                               outcome == 'allcause' ~ 'All-cause\n severity',
                               TRUE ~ NA_character_)
           ) %>%
    ggplot(aes(x = AUROC, y = outcome, color = data_partition)) +
    geom_vline(xintercept = 0.5, linetype = "dashed") +
    geom_boxplot() +
    scale_color_brewer(palette = 'Paired') +
    theme_bw() +
    theme(
        plot.margin = unit(x = c(0, 0, 0, 0), units = "pt"),
        axis.title.y = element_blank(),
        legend.position = 'top',
        legend.margin = margin(0, 0, 0, 0, unit = "pt"),
        legend.title = element_blank()
    )

sensspec_plot <- dat %>% 
  ggplot(aes(Specificity, Sensitivity, color = outcome)) +
  geom_jitter(alpha = 0.7) +
  facet_wrap("metric") +
  theme_bw()
precrec_plot <- dat %>% 
  ggplot(aes(Recall, Precision, color = outcome)) +
  geom_jitter(alpha = 0.7) +
  facet_wrap("metric") +
  theme_bw()

ggsave("figures/plot_perf.png", plot = perf_plot, device = "png", 
       width = 5, height = 5)
ggsave("figures/plot_sensspec.png", plot = sensspec_plot, device = "png", 
       width = 5, height = 3)
ggsave("figures/plot_precrec.png", plot = precrec_plot, device = "png", 
       width = 5, height = 3)
