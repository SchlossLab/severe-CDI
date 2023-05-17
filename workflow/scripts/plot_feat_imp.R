source("workflow/scripts/log_smk.R")
library(cowplot)
library(ggtext)
library(glue)
library(here)
library(schtools)
library(tidyverse)
filter_top_feats <- function(feat_dat, 
                             frac_important_threshold = 0.75,
                             otu_col = label_html, 
                             outcome_col = outcome,
                             ds_col = dataset) {
  n_models <- feat_dat %>% pull(seed) %>% unique() %>% length()
  message(glue("# models: {n_models}"))
  feat_dat %>%
    mutate(is_important = perf_metric_diff > 0) %>%
    filter(is_important) %>%
    group_by({{ otu_col }}, {{ outcome_col }}, {{ ds_col }}) %>%
    summarise(
      frac_important = sum(is_important) / n_models,
      median_perf_diff = median(perf_metric_diff)
    ) %>%
    filter(frac_important >= frac_important_threshold) %>%
    arrange(by = desc(median_perf_diff)) 
}

model_colors <- RColorBrewer::brewer.pal(4, 'Dark2')
names(model_colors) <- c("idsa", 'attrib', 'allcause', 'pragmatic')

feat_dat <- read_csv("results/feature-importance_results_aggregated.csv") %>% 
  rename(otu = feat)
tax_dat <- schtools::read_tax("data/mothur/alpha/cdi.taxonomy")
alpha_level <- 0.05

dat <- left_join(feat_dat, tax_dat, by = 'otu')
dat_top_otus <- dat %>% 
  filter_top_feats(frac_important_threshold = 0.80)

top_otus_order <- dat_top_otus %>%
  arrange(median_perf_diff) %>% 
  pull(label_html) %>% 
  unique() 

plot_feat_imp <- function(dat) {
  dat %>% 
  ggplot(aes(x = perf_metric_diff, 
             y = label_html, 
             color = outcome))+
    stat_summary(fun = 'median', 
                 fun.max = function(x) quantile(x, 0.75), 
                 fun.min = function(x) quantile(x, 0.25),
                 position = position_dodge(width = 0.4)) +
  geom_hline(yintercept = seq(1.5, length(unique(dat$label_html))-0.5, 1), 
             lwd = 0.5, colour = "whitesmoke") +
  facet_wrap('dataset') +
    scale_color_manual(values = model_colors,
                       labels = c(idsa='IDSA', attrib='Attrib', allcause='All-cause', pragmatic='Pragmatic'),
                       guide = guide_legend(label.position = "bottom")) +
    labs(title=NULL, 
         y=NULL,
         x="Difference in AUROC") +
    theme_sovacool() +
    theme(text = element_text(size = 10, family = 'Helvetica'),
          axis.text.y = element_markdown(size = 10),
          axis.text.x = element_text(size = 10),
          strip.background = element_blank(),
          legend.position = "top",
          panel.grid.major.y = element_blank(),
          legend.title = element_blank()) 
}

feat_imp_plot <- dat %>% 
  inner_join(dat_top_otus %>% filter(label_html %in% top_otus_order), 
             by = c('label_html', 'outcome', 'dataset')) %>% 
  mutate(label_html = factor(label_html, levels = top_otus_order),
         dataset = case_when(dataset == 'full' ~ 'Full dataset',
                             TRUE ~ 'Intersection of samples with all labels'),
         outcome = factor(outcome, levels = c('idsa', 'allcause', 'attrib', 'pragmatic'))) %>% 
  plot_feat_imp()

top_5_plot <- dat %>% # keeping even insignificant OTU x outcome combinations
  filter(label_html %in% c("<i>Lactobacillus</i> (OTU 71)", "<i>Enterococcus</i> (OTU 12)", 
  "<i>Lachnospiraceae</i> (OTU 149)", "<i>Parabacteroides</i> (OTU 9)", 
  "<i>Staphylococcus</i> (OTU 119)")) %>% 
  plot_feat_imp()

# TODO add difference in relative abundance (severe minus not severe?)
ggsave(
    filename = here('figures', 'feature-importance.tiff'), 
    plot = feat_imp_plot,
    device = "tiff", dpi = 600, 
    units = "in", width = 6.5, height = 6.5
    )
