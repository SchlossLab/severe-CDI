schtools::log_snakemake()
library(cowplot)
library(here)
library(mikropml)
library(schtools)
library(tidyverse)

dat <- read_csv(here("results","performance_results_aggregated.csv")) %>%
    rename(`test set AUROC` = AUC,
           `training set AUROC` = cv_metric_AUC,
           `test set AUBPRC` = bpr_auc, # yardstick::pr_auc doesn't overestimate
           `test set ABP` = average_precision_balanced) %>% 
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
    pivot_longer(c(`training set AUROC`, `test set AUROC`, `test set AUBPRC`, 
                   ),
                 names_to = "data_partition",
                 values_to = 'performance'
                 )  %>%
    ggplot(aes(x = performance, y = outcome, color = data_partition)) +
    stat_summary(fun = median, 
                 fun.max = function(x) quantile(x, 0.95), 
                 fun.min = function(x) quantile(x, 0.05),
                 position = position_dodge(width = 0.7)
                 ) +
    stat_summary(fun = median, 
                 geom = "label", 
                 show.legend = FALSE,
                 mapping = aes(label = format(round(after_stat(x),2), nsmall = 2)),
                 alpha = 0.7,
                 label.padding = unit(0, 'pt'),
                 label.size = unit(0,'pt'),
                 position = position_nudge(x = 0.12, y = c(-0.25, 0, 0.25))
                 ) +
    geom_hline(yintercept = seq(1.5, length(unique(dat %>% pull(outcome)))-0.5, 1), 
             lwd = 0.5, colour = "grey92") +
    geom_vline(xintercept = 0.5, linetype = "dashed") +
    scale_x_continuous(limits = c(0.3, 1), expand = c(0,0)) +
    scale_color_manual(values = c("training set AUROC" = "#BDBDBD",
                                  "test set AUROC" = "#252525",
                                  "test set AUBPRC" = "#4292C6"),
                       breaks = c("training set AUROC", 
                                  "test set AUROC", 
                                  "test set AUBPRC"),
                       guide = guide_legend(label.position = "top")) +
    facet_wrap('dataset', ncol = 2) +
    labs(x = 'Performance (AUROC or AUBPRC)') +
    theme_sovacool() +
    theme(
        text = element_text(size = 10, family = 'Helvetica'),
        axis.title.y = element_blank(),
        legend.position = 'top',
        legend.title = element_blank(),
        strip.background = element_blank(),
        panel.grid.major.y = element_blank(),
        plot.margin = margin(2,7,2,2, unit = 'pt')
    )

model_comps <- read_csv(here('results', 'model_comparisons.csv')) %>% 
  mutate(is_signif = p_value < 0.05)

sensspec_dat <- read_csv(here('results','sensspec_results_aggregated.csv')) %>% 
  mutate(outcome = factor(outcome, levels = c('idsa', 'allcause', 'attrib', 'pragmatic'))) %>% 
  mutate(dataset = case_when(dataset == 'full' ~ 'Full dataset',
                             dataset == 'int' ~ 'Intersection',
                             TRUE ~ NA_character_))


roc_dat <- read_csv(here('results', 'roccurve_results_aggregated.csv')) %>%
  mutate(outcome = factor(outcome, levels = c('idsa', 'allcause', 'attrib', 'pragmatic'))) %>% 
  mutate(dataset = case_when(dataset == 'full' ~ 'Full dataset',
                             dataset == 'int' ~ 'Intersection',
                             TRUE ~ NA_character_)) %>% 
  dplyr::mutate(specificity = round(specificity, 1)) %>%
  dplyr::group_by(specificity, dataset, outcome) %>%
  dplyr::summarise(
    mean_sensitivity = mean(sensitivity),
    upper = quantile(sensitivity, 0.95),
    lower = quantile(sensitivity, 0.05)
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

thresh_dat <- read_csv(here('results','thresholds_results_aggregated.csv')) %>% 
  mutate(predicted_pos_frac = (tp + fp) / (tp + fp + tn + fn))
roc_risk_pct <- thresh_dat %>% 
  mutate(Specificity = round(Specificity, 2)) %>%
  group_by(Specificity, dataset, outcome) %>%
  summarise(
    mean_sensitivity = mean(Sensitivity),
    mean_pred_pos_frac = mean(predicted_pos_frac)
  ) %>% 
  ungroup() %>%
  group_by(dataset, outcome) %>%
  mutate(diff_95th_pct = abs(mean_pred_pos_frac - 0.05)) %>%
  slice_min(diff_95th_pct) %>% 
  mutate(dataset = case_when(dataset == 'full' ~ 'Full dataset',
                             dataset == 'int' ~ 'Intersection',
                             TRUE ~ NA_character_))
roc_plot <- roc_dat %>%
  filter(!(dataset == 'Intersection' & outcome == 'pragmatic'))  %>%  # remove pragmatic int since same as attrib
  ggplot() +
  geom_ribbon(aes(x = specificity, ymin = lower, ymax = upper, fill = outcome), 
              alpha = 0.08) +
  geom_line(aes(x = specificity, y = mean_sensitivity, color = outcome), alpha=0.6) +
  #geom_point(data = roc_risk_pct, aes(x = Specificity, y = mean_sensitivity, color = outcome)) +
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
  scale_fill_manual(values = c(idsa = "#1B9E77", 
                               attrib = "#D95F02", 
                               allcause = "#7570B3", 
                               pragmatic = "#E7298A"),
                    labels = c(idsa='IDSA', attrib='Attrib', allcause='All-cause', pragmatic='Pragmatic')
  ) +
  guides(fill = 'none') +
  scale_y_continuous(expand = c(0, 0), limits = c(-0.01, 1.01)) +
  scale_x_reverse(expand = c(0, 0), limits = c(1.01,-0.01)) +
  coord_equal() +
  labs(x = "Specificity", y = "Sensitivity") +
  facet_wrap('dataset', ncol = 2) +
  theme_sovacool() +
  theme(text = element_text(size = 10, family = 'Helvetica'),
        legend.position = 'none',
        legend.title = element_blank(),
        strip.background = element_blank(),
        panel.spacing = unit(10, 'pt'),
        axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1),
        plot.margin = margin(0,2,0,0))

bprc_dat <- read_csv(here('results', 'prcurve_results_aggregated.csv')) %>%
  mutate(outcome = factor(outcome, levels = c('idsa', 'allcause', 'attrib', 'pragmatic')),
         dataset = case_when(dataset == 'full' ~ 'Full dataset',
                             dataset == 'int' ~ 'Intersection',
                             TRUE ~ NA_character_)) %>% 
  left_join(sensspec_dat %>% 
              select(outcome, dataset, prior) %>% 
              dplyr::distinct(), 
            by = join_by(outcome, dataset)) %>% 
  mutate(
         balanced_precision = mikropml::calc_balanced_precision(precision, prior),
         recall = round(recall, 2)) %>%
  group_by(recall, dataset, outcome) %>%
  summarise(
    mean_balanced_precision = median(balanced_precision),
    upper = quantile(balanced_precision, 0.95),
    lower = quantile(balanced_precision, 0.05)
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
bprc_plot <- bprc_dat %>%
  filter(!(dataset == 'Intersection' & outcome == 'pragmatic'))  %>%  # remove pragmatic int since same as attrib
  ggplot(aes(x = recall, y = mean_balanced_precision, 
             ymin = lower, ymax = upper)) +
  geom_ribbon(aes(fill = outcome), alpha = 0.08) +
  geom_line(aes(color = outcome), alpha=0.6) +
  geom_hline(yintercept = 0.5, color = "grey50", linetype = 'dashed') +
  scale_color_manual(values = c(idsa = "#1B9E77", 
                                attrib = "#D95F02", 
                                allcause = "#7570B3", 
                                pragmatic = "#E7298A"),
                     labels = c(idsa='IDSA', attrib='Attrib', allcause='All-cause', pragmatic='Pragmatic'),
                     guide = guide_legend(label.position = "top")) +
  scale_fill_manual(values = c(idsa = "#1B9E77", 
                                attrib = "#D95F02", 
                                allcause = "#7570B3", 
                                pragmatic = "#E7298A"),
                     labels = c(idsa='IDSA', attrib='Attrib', allcause='All-cause', pragmatic='Pragmatic')
                     ) +
  guides(fill = 'none') +
  scale_y_continuous(expand = c(0, 0), limits = c(-0.01, 1.01)) +
  scale_x_continuous(expand = c(0, 0), limits = c(-0.01, 1.01)) +
  coord_equal() +
  labs(x = "Recall", y = "Balanced Precision") +
  facet_wrap('dataset', ncol = 2) +
  theme_sovacool() +
  theme(text = element_text(size = 10, family = 'Helvetica'),
        legend.position = 'none',
        legend.title = element_blank(),
        legend.spacing.y = unit(0, 'pt'),
        strip.background = element_blank(),
        panel.spacing = unit(10, 'pt'),
        axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1),
        plot.margin = margin(5,2,0,2))


prcurve_dat <- read_csv(here('results', 'prcurve_results_aggregated.csv')) %>%
  mutate(outcome = factor(outcome, levels = c('idsa', 'allcause', 'attrib', 'pragmatic'))) %>% 
  mutate(dataset = case_when(dataset == 'full' ~ 'Full dataset',
                             dataset == 'int' ~ 'Intersection',
                             TRUE ~ NA_character_)) %>% 
  dplyr::mutate(recall = round(recall, 2)) %>%
  dplyr::group_by(recall, dataset, outcome) %>%
  dplyr::summarise(
    mean_precision = mean(precision),
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

color_names <- c("IDSA"="#1B9E77", 'All-cause'="#7570B3", 
                 'Attrib'="#D95F02", 'Pragmatic'="#E7298A")

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

prc_plot_grid <- prcurve_dat %>%
  mutate(outcome = factor(case_when(
    outcome == 'idsa' ~ 'IDSA',
    outcome == 'allcause' ~ 'All-cause',
    outcome == 'attrib' ~ 'Attrib',
    outcome == 'pragmatic' ~ 'Pragmatic',
    TRUE ~ NA_character_
  ), levels = c("IDSA", 'All-cause', 'Attrib', 'Pragmatic'))) %>% 
  ggplot(aes(x = recall, y = mean_precision, 
             ymin = lower, ymax = upper)) +
  geom_ribbon(aes(fill = outcome), alpha = 0.15) +
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
  labs(x = "Recall", y = "Precision") +
  facet_grid(dataset ~ outcome) +
  theme_sovacool() +
  theme(text = element_text(size = 10, family = 'Helvetica'),
        legend.position = 'none',
        legend.title = element_blank(),
        strip.background = element_blank(),
        panel.spacing = unit(8, 'pt'),
        axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1))

ggsave('figures/prc_curves.tiff', plot = prc_plot_grid,
       device = 'tiff', compression = 'lzw', dpi = 600,
       width = 5, height = 3)

curve_legend <- get_legend(bprc_plot + theme(legend.position = 'bottom'))
fig <- plot_grid(perf_plot, 
                 plot_grid(roc_plot, bprc_plot,
                           nrow = 1, align = 'hv', axis = 'l',
                           labels = c('B', 'C')),
                 curve_legend,
                 labels = c('A', '', ''),
                 ncol = 1, rel_heights = c(1,0.7,0.1))
ggsave("figures/ml-performance.tiff", plot = fig, 
       device = "tiff", compression = "lzw", dpi = 600,  bg = '#FFFFFF',
       width = 6.875, height = 6) # https://journals.asm.org/figures-tables
