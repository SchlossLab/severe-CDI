schtools::log_snakemake()
library(mikropml)
library(tidyverse)

dat <- read_csv("results/performance_results_aggregated.csv") %>%
    rename(`testset AUROC` = AUC,
           `trainset AUROC` = cv_metric_AUC,
           `testset AUPRC` = prAUC,
           `testset AUBPRC` = aubprc) %>% 
    filter(metric == 'AUC', method == 'rf', trainfrac == 0.8) %>%
  mutate(dataset = case_when(dataset == 'full' ~ 'Full dataset',
                             TRUE ~ 'Intersection of samples with all labels available')) %>% 
  mutate(
    outcome = factor(case_when(outcome == 'idsa' ~ 'IDSA\n severity',
                        outcome == 'attrib' ~ 'Attributable\n severity',
                        outcome == 'allcause' ~ 'All-cause\n severity',
                        outcome == 'pragmatic' ~ 'Pragmatic\n severity',
                        TRUE ~ NA_character_), levels = c('IDSA\n severity',
                           'Attributable\n severity',
                           'All-cause\n severity',
                           'Pragmatic\n severity'))
  )
perf_plot <- dat %>% 
    pivot_longer(c(`trainset AUROC`, `testset AUROC`, `testset AUBPRC`
                   ),
                 names_to = "data_partition",
                 values_to = 'performance'
                 )  %>%
    ggplot(aes(x = performance, y = outcome, color = data_partition)) +
    geom_vline(xintercept = 0.5, linetype = "dashed") +
    geom_boxplot() +
    stat_summary(fun = median, 
                 geom = "text", 
                 show.legend = FALSE,
                 mapping = aes(label = round(after_stat(x),2)),
                 position = position_nudge(x = 0, y = c(-0.45, -0.2, 0.45))) +
    facet_wrap('dataset', ncol = 2) +
    scale_color_manual(values = c("trainset AUROC" = "#BDBDBD", 
                                  "testset AUROC" = "#252525",
                                  "testset AUBPRC" = "#4292C6")) +
    labs(x = 'Performance') +
    theme_bw() +
    theme(
        plot.margin = unit(x = c(0, 0, 0, 0), units = "pt"),
        axis.title.y = element_blank(),
        legend.position = 'top',
        legend.margin = margin(0, 0, 0, 0, unit = "pt"),
        legend.title = element_blank()
    )


ggsave("figures/ml-performance.tiff", plot = perf_plot, device = "tiff", 
       width = 6.5, height = 5)
