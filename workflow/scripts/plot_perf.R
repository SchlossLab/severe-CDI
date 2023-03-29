schtools::log_snakemake()
library(mikropml)
library(tidyverse)
dat <- read_csv("results/performance_results_aggregated.csv") %>%
    rename(AUROC = AUC,
           AUPRC = prAUC) %>% 
    filter(metric == 'AUC', method == 'rf', trainfrac == 0.8) %>%
  mutate(
    outcome = factor(case_when(outcome == 'idsa' ~ 'IDSA\n severity',
                        outcome == 'attrib' ~ 'Attributable\n severity',
                        outcome == 'allcause' ~ 'All-cause\n severity',
                        outcome == 'pragmatic' ~ 'Pragmatic\n all-cause\n severity',
                        TRUE ~ NA_character_), levels = c('IDSA\n severity',
                           'Attributable\n severity',
                           'All-cause\n severity',
                           'Pragmatic\n all-cause\n severity'))
  )
perf_plot <- dat %>% 
    #filter(dataset == 'full') %>% 
    rename(trainset = cv_metric_AUC,
           testset = AUROC) %>% 
    pivot_longer(c(trainset, testset),
                 names_to = "data_partition",
                 values_to = 'AUROC'
                 )  %>%
    ggplot(aes(x = AUROC, y = outcome, color = data_partition)) +
    geom_vline(xintercept = 0.5, linetype = "dashed") +
    geom_boxplot() +
    stat_summary(fun = median, 
                 geom = "text", 
                 show.legend = FALSE,
                 mapping = aes(label = round(after_stat(x),2)),
                 position = position_nudge(x = 0.2, y = c(-0.1, 0.1))) +
    facet_wrap('dataset', ncol = 2) +
    scale_color_grey() +
    theme_bw() +
    theme(
        plot.margin = unit(x = c(0, 0, 0, 0), units = "pt"),
        axis.title.y = element_blank(),
        legend.position = 'top',
        legend.margin = margin(0, 0, 0, 0, unit = "pt"),
        legend.title = element_blank()
    )

perf_plot_prc <- dat %>% 
  filter(dataset == 'int') %>% 
  mutate(
    outcome = case_when(outcome == 'idsa' ~ 'IDSA\n severity',
                        outcome == 'attrib' ~ 'Attributable\n severity',
                        outcome == 'allcause' ~ 'All-cause\n severity',
                        TRUE ~ NA_character_)
  ) %>%
  ggplot(aes(x = AUPRC, y = outcome)) +
  geom_boxplot() +
  stat_summary(fun = median, 
               geom = "text", 
               mapping = aes(label = round(after_stat(x),2)),
               position = position_nudge(x = 0.2, y = c(-0.1, 0.1))) +
  facet_wrap('dataset', ncol = 2) +
  scale_color_grey() +
  theme_bw() +
  theme(
    plot.margin = unit(x = c(0, 0, 0, 0), units = "pt"),
    axis.title.y = element_blank(),
    legend.position = 'top',
    legend.margin = margin(0, 0, 0, 0, unit = "pt"),
    legend.title = element_blank()
  )

sensspec_plot <- dat %>% 
  filter(dataset=='full') %>% 
  ggplot(aes(Specificity, Sensitivity, color = outcome)) +
  geom_jitter(alpha = 0.7) +
  facet_wrap("metric") +
  theme_bw()
precrec_plot <- dat %>% 
  filter(dataset=='int') %>% 
  ggplot(aes(Recall, Precision, color = outcome)) +
  geom_jitter(alpha = 0.7) +
  facet_wrap("metric") +
  theme_bw()

ggsave("figures/plot_perf.png", plot = perf_plot, device = "png", 
       width = 8, height = 5)
ggsave("figures/plot_sensspec.png", plot = sensspec_plot, device = "png", 
       width = 5, height = 3)
ggsave("figures/plot_precrec.png", plot = precrec_plot, device = "png", 
       width = 5, height = 3)
