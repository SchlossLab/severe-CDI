schtools::log_snakemake()
library(cowplot)
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
                                  "test set AUBPRC" = "#4292C6"),
                       breaks = c("training set AUROC", "test set AUROC", "test set AUBPRC")) +
    guides(color = guide_legend(label.position = "bottom"))  +
    labs(x = 'Performance (AUROC or AUBPRC)') +
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

sensspec_dat <- read_csv(here('results','sensspec_results_aggregated.csv')) %>% 
  mutate(outcome = factor(outcome, levels = c('idsa', 'allcause', 'attrib', 'pragmatic'))) %>% 
  mutate(dataset = case_when(dataset == 'full' ~ 'Full dataset',
                             dataset == 'int' ~ 'Intersection',
                             TRUE ~ NA_character_))

roc_dat <- sensspec_dat %>% 
  dplyr::mutate(specificity = round(specificity, 2)) %>%
  dplyr::group_by(specificity, dataset, outcome) %>%
  dplyr::summarise(
    mean_sensitivity = mean(sensitivity)
  )

roc_plot <- roc_dat %>%
  filter(!(dataset == 'Intersection' & outcome == 'pragmatic'))  %>%  # remove pragmatic int since same as attrib
  ggplot(aes(x = specificity, y = mean_sensitivity
             #ymin = lower, ymax = upper
             )) +
  #geom_ribbon(aes(fill = outcome), alpha = 0.1) +
  geom_line(aes(color = outcome), alpha=0.6) +
  geom_abline(
    intercept = 1,
    slope = 1,
    linetype = "dashed",
    color = "grey50"
  ) +
  scale_color_manual(values = c(idsa = "#1B9E77", 
                                attrib = "#D95F02", 
                                allcause = "#7570B3", 
                                pragmatic = "#E7298A")) +
  #scale_fill_brewer(palette = 'Dark2') +
  scale_y_continuous(expand = c(0, 0), limits = c(-0.01, 1.01)) +
  scale_x_reverse(expand = c(0, 0), limits = c(1.01,-0.01)) +
  coord_equal() +
  labs(x = "Specificity", y = "Mean Sensitivity") +
  facet_wrap('dataset', ncol = 2) +
  theme_sovacool() +
  theme(text = element_text(size = 10, family = 'Helvetica'),
        legend.position = 'none',
        legend.title = element_blank(),
        strip.background = element_blank(),
        panel.spacing = unit(10, 'pt'),
        axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1),
        plot.margin = margin(0,5,0,0))

bprc_dat <- sensspec_dat %>% 
  dplyr::mutate(sensitivity = round(sensitivity, 2)) %>%
  dplyr::group_by(sensitivity, dataset, outcome) %>%
  dplyr::summarise(
    mean_balanced_precision = mean(balanced_precision),
  ) 

bprc_plot <- bprc_dat %>%
  filter(!(dataset == 'Intersection' & outcome == 'pragmatic'))  %>%  # remove pragmatic int since same as attrib
  ggplot(aes(x = sensitivity, y = mean_balanced_precision)) +
  #geom_ribbon(aes(fill = outcome), alpha = 0.2) +
  geom_line(aes(color = outcome), alpha=0.6) +
  geom_hline(yintercept = 0.5, color = "grey50", linetype = 'dashed') +
  scale_color_manual(values = c(idsa = "#1B9E77", 
                                attrib = "#D95F02", 
                                allcause = "#7570B3", 
                                pragmatic = "#E7298A"),
                     labels = c(idsa='IDSA', attrib='Attrib', allcause='All-cause', pragmatic='Pragmatic'),
                     guide = guide_legend(label.position = "top")) +
  #scale_fill_brewer(palette = 'Dark2') +
  scale_y_continuous(expand = c(0, 0), limits = c(-0.01, 1.01)) +
  scale_x_continuous(expand = c(0, 0), limits = c(-0.01, 1.01)) +
  coord_equal() +
  labs(x = "Recall", y = "Median Balanced Precision") +
  facet_wrap('dataset', ncol = 2) +
  theme_sovacool() +
  theme(text = element_text(size = 10, family = 'Helvetica'),
        legend.position = 'none',
        legend.title = element_blank(),
        legend.spacing.y = unit(0, 'pt'),
        strip.background = element_blank(),
        panel.spacing = unit(10, 'pt'),
        axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1),
        plot.margin = margin(15,5,0,5))

prc_dat <- roc_dat <- sensspec_dat %>% 
  dplyr::mutate(sensitivity = round(sensitivity, 2)) %>%
  dplyr::group_by(sensitivity, dataset, outcome) %>%
  dplyr::summarise(
    median_precision = median(precision),
    upper = quantile(precision, 0.95),
    lower = quantile(precision, 0.05)
  ) %>%
  dplyr::mutate(
    upper = dplyr::case_when(
      upper > 1 ~ 1,
      TRUE ~ upper
    ),
    lower = dplyr::case_when(
      lower < 0 ~ 0,
      TRUE ~ lower
    )
  )

# TODO add baseline precision
priors <- sensspec_dat %>% 
  select(outcome, dataset, prior) %>% 
  dplyr::distinct() %>%
  mutate(outcome = factor(case_when(
    outcome == 'idsa' ~ 'IDSA',
    outcome == 'allcause' ~ 'All-cause',
    outcome == 'attrib' ~ 'Attrib',
    outcome == 'pragmatic' ~ 'Pragmatic',
    TRUE ~ NA_character_
  ), levels = c("IDSA", 'All-cause', 'Attrib', 'Pragmatic')))
color_names <- c("IDSA"="#1B9E77", 'All-cause'="#7570B3", 
                 'Attrib'="#D95F02", 'Pragmatic'="#E7298A")
prc_plot_grid <- prc_dat %>%
  mutate(outcome = factor(case_when(
    outcome == 'idsa' ~ 'IDSA',
    outcome == 'allcause' ~ 'All-cause',
    outcome == 'attrib' ~ 'Attrib',
    outcome == 'pragmatic' ~ 'Pragmatic',
    TRUE ~ NA_character_
  ), levels = c("IDSA", 'All-cause', 'Attrib', 'Pragmatic'))) %>% 
  ggplot(aes(x = sensitivity, y = median_precision, 
             ymin = lower, ymax = upper)) +
  geom_ribbon(aes(fill = outcome), alpha = 0.2) +
  geom_line(aes(color = outcome)) +
  geom_hline(data = priors,
             aes(yintercept = prior),
             linetype = 'dashed') +
  scale_color_manual(values = color_names,
                     guide = guide_legend(label.position = "top")) +
  scale_fill_manual(values = color_names,
  ) +
  scale_y_continuous(expand = c(0, 0), limits = c(-0.01, 1.01)) +
  scale_x_continuous(expand = c(0, 0), limits = c(-0.01, 1.01)) +
  coord_equal() +
  labs(x = "Recall", y = "Median Precision") +
  facet_grid(dataset ~ outcome) +
  theme_sovacool() +
  theme(text = element_text(size = 10, family = 'Helvetica'),
        legend.position = 'none',
        legend.title = element_blank(),
        strip.background = element_blank(),
        panel.spacing = unit(10, 'pt'),
        axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1))

ggsave('figures/prc_curves.tiff', plot = prc_plot_grid,
       device = 'tiff', compression = 'lzw', dpi = 600,
       width = 5, height = 3.5)

curve_legend <- get_legend(bprc_plot + theme(legend.position = 'bottom'))
fig <- plot_grid(perf_plot, 
                 plot_grid(roc_plot, bprc_plot,
                           nrow = 1, align = 'hv', axis = 'l',
                           labels = c('B', 'C')),
                 curve_legend,
                 labels = c('A', '', ''),
                 ncol = 1, rel_heights = c(1,0.5,0.1))
ggsave("figures/ml-performance.tiff", plot = fig, 
       device = "tiff", compression = "lzw", dpi = 600,  bg = '#FFFFFF',
       width = 6.875, height = 6.875) # https://journals.asm.org/figures-tables
