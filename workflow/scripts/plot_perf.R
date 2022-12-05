source("workflow/scripts/log_smk.R")
library(tidyverse)
dat <- read_csv("results/performance_results_aggregated.csv") %>%
    rename(AUROC = AUC,
           AUPRC = prAUC) #%>% 
  #filter(method == 'rf', dataset == 'int', trainfrac == 0.65) 
perf_plot <- dat %>% 
    pivot_longer(c(AUROC, AUPRC, F1),
                 names_to = "perf_metric"
                 ) %>%
    mutate(data = case_when(stringr::str_detect(perf_metric, 'cv_metric_AUC') ~ 'train',
                            TRUE ~ 'test'),
           outcome = case_when(outcome == 'idsa' ~ 'IDSA\n severity',
                               outcome == 'attrib' ~ 'Attributable\n severity',
                               outcome == 'allcause' ~ 'All-cause\n severity',
                               TRUE ~ NA_character_)
           ) %>%
    ggplot(aes(x = value, y = perf_metric, color = outcome)) +
    #geom_vline(xintercept = 0.5, linetype = "dashed") +
    geom_boxplot() +
    scale_color_brewer(palette = 'Paired') +
    facet_wrap("metric") +
    labs(x = "performance") +
    theme_bw() +
    theme(
        plot.margin = unit(x = c(0, 0, 0, 0), units = "pt"),
        axis.title.y = element_blank(),
        legend.position = 'top',
        legend.margin = margin(0, 0, 0, 0, unit = "pt")
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
