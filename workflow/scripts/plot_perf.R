source("workflow/scripts/log_smk.R")
library(tidyverse)
dat <- read_csv("results/performance_results_aggregated.csv")
perf_plot <- dat %>%
    pivot_longer(-c(method, seed, outcome),
                 names_to = "metric"
                 ) %>%
    mutate(data = case_when(metric == 'cv_metric_AUC' ~ 'train',
                            metric == 'AUC' ~ 'test',
                            TRUE ~ NA_character_),
           outcome = case_when(outcome == 'idsa' ~ 'IDSA\n severity',
                               outcome == 'attrib' ~ 'Attributable\n severity',
                               outcome == 'allcause' ~ 'All-cause\n severity',
                               TRUE ~ NA_character_)
           ) %>%
    filter(!is.na(data) & method == 'rf') %>% # TODO: plot PRC separately with different baseline
    ggplot(aes(x = value, y = outcome, color = data)) +
    geom_vline(xintercept = 0.5, linetype = "dashed") +
    geom_boxplot() +
    scale_color_brewer(palette = 'Paired') +
    #facet_wrap('method', ncol = 1) +
    #xlim(0.5, 1) +
    labs(x = "AUROC") +
    theme_bw() +
    theme(
        plot.margin = unit(x = c(0, 0, 0, 0), units = "pt"),
        axis.title.y = element_blank(),
        legend.position = 'top',
        legend.margin = margin(0, 0, 0, 0, unit = "pt")
    )
ggsave("figures/plot_perf.png", plot = perf_plot, device = "png", 
       width = 5, height = 5)
