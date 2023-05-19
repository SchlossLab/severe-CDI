schtools::log_snakemake()
library(here)
library(mikropml)
library(schtools)
library(tidyverse)

dat <- read_csv(here("results","performance_results_aggregated.csv")) %>%
    rename(`test set AUROC` = AUC,
           `training set AUROC` = cv_metric_AUC,
           `test set AUPRC` = prAUC,
           `test set AUBPRC` = aubprc) %>% 
    filter(metric == 'AUC', method == 'rf', trainfrac == 0.8) %>%
  mutate(dataset = case_when(dataset == 'full' ~ 'Full dataset',
                             TRUE ~ 'Intersection of samples with all labels available')) %>% 
  mutate(
    outcome = factor(case_when(outcome == 'idsa' ~ 'IDSA\n severity',
                        outcome == 'attrib' ~ 'Attributable\n severity',
                        outcome == 'allcause' ~ 'All-cause\n severity',
                        outcome == 'pragmatic' ~ 'Pragmatic\n severity',
                        TRUE ~ NA_character_), levels = c('IDSA\n severity',
                           'All-cause\n severity',
                           'Attributable\n severity',
                           'Pragmatic\n severity'))
  )
perf_plot <- dat %>% 
    pivot_longer(c(`training set AUROC`, `test set AUROC`, `test set AUBPRC`
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
    scale_color_manual(values = c("training set AUROC" = "#BDBDBD", 
                                  "test set AUROC" = "#252525",
                                  "test set AUBPRC" = "#4292C6")) +
    guides(color = guide_legend(label.position = "bottom"))  +
    labs(x = 'Performance') +
    theme_sovacool() +
    theme(
        text = element_text(size = 10, family = 'Helvetica'),
        axis.title.y = element_blank(),
        legend.position = 'top',
        legend.title = element_blank(),
        strip.background = element_blank()
    )

model_comps <- read_csv(here('results', 'model_comparisons.csv')) %>% 
  mutate(is_signif = p_value < 0.05)

# TODO AUROC and AUBPRC curves

ggsave("figures/ml-performance.tiff", plot = perf_plot, 
       device = "tiff", compression = "lzw", dpi = 600,
       width = 6.5, height = 5)
