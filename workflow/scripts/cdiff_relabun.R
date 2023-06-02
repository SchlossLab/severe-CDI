schtools::log_snakemake()
library(cowplot)
library(ggtext)
library(here)
library(schtools)
library(tidyverse)
model_colors <- c(idsa = "#1B9E77", attrib = "#D95F02", allcause = "#7570B3", 
                  pragmatic = "#E7298A")

cdiff_taxa <- schtools::read_tax("data/mothur/alpha/cdi.taxonomy") %>% 
  filter(str_detect(family, "Peptost"), str_detect(genus, 'Clostrid') | str_detect(genus, 'unclassified'))

relabun_dat <- data.table::fread(here('data', 'mothur', 'alpha', 
                                      'cdi.opti_mcc.shared')) %>% 
  calc_relabun()

tiny_constant <- relabun_dat %>%
  filter(rel_abun > 0) %>%
  slice_min(rel_abun) %>%
  pull(rel_abun) %>% .[1]/100 # select tiniest non-zero relabun and divide

cdiff_relabun_dat <- relabun_dat %>% 
  filter(otu %in% (cdiff_taxa %>% pull(otu))) %>%
  right_join(left_join(read_csv(here('data', 'process', 'cases_full_metadata.csv')),
                       data.table::fread(here('data', 'SraRunTable.csv')) %>% 
                         select(-Group) %>% 
                         rename(sample_id = sample_title,
                                sample = Run) %>% 
                         select(sample_id, sample), by = 'sample_id')) %>% 
  select(sample_id, otu, rel_abun, idsa, attrib, allcause, pragmatic) %>% 
  mutate(rel_abun_c = rel_abun + tiny_constant) %>% # for log transformation
  pivot_longer(c(idsa, attrib, allcause, pragmatic), 
               names_to = 'outcome', values_to = 'is_severe') %>% 
  right_join(cdiff_taxa) %>% 
  filter(!is.na(is_severe)) %>% 
  arrange(desc(otu))
    
# OTU 25 is the only cdiff OTU with abundance above the LOD
cdiff_plot <- cdiff_relabun_dat %>% 
  group_by(outcome, is_severe, label_html) %>% 
  summarize(med_rel_abun = mean(rel_abun_c)) %>% 
  ggplot(aes(x = med_rel_abun, y = label_html, 
             color = outcome, shape = is_severe, group = outcome)) +
  geom_point(
               position = position_dodge(width = 0.9),
               alpha = 0.6) +
  geom_vline(xintercept = tiny_constant, linetype = 'dashed') +
  scale_color_manual(values = model_colors,
                     labels = c(idsa='IDSA', attrib='Attributable', 
                                allcause='All-cause', pragmatic='Pragmatic'),
  ) +
  scale_shape_manual(values = c(yes=3, no=1),
                     labels = c(yes='Yes', no='No'),
                     guide = guide_legend(label.position = 'bottom',
                                          title = 'Is Severe',
                                          title.position = 'top')) +
  labs(x = 'mean Relative Abundance') +
  theme_sovacool() +
  theme(axis.text.y = element_markdown(),
        axis.title.y = element_blank(),
        legend.position = 'top')

feat_dat <- read_csv("results/feature-importance_results_aggregated.csv") %>% 
  rename(otu = feat) %>% 
  filter(otu == 'Otu0025') 

otu25_label <- cdiff_taxa %>% filter(otu == 'Otu0025') %>% pull(label_html)
relabun_plot <- cdiff_relabun_dat %>% 
  mutate(outcome = factor(outcome, levels = c('idsa', 'allcause', 'attrib', 'pragmatic')),
         is_severe = factor(is_severe, levels = c('yes','no'))) %>% 
  filter(otu == 'Otu0025') %>% 
  ggplot(aes(x = rel_abun_c, y = outcome, fill = is_severe, color = outcome)) +
  geom_vline(xintercept = tiny_constant, linetype = 'dashed') +
  geom_boxplot(alpha = 0.6) +
  geom_hline(yintercept = seq(1.5, 3.5, 1), 
             lwd = 0.5, colour = "grey92") +
  scale_y_discrete(labels = c(idsa='IDSA', attrib='Attributable', 
                              allcause='All-cause', pragmatic='Pragmatic')) +
  scale_x_log10() +
  scale_fill_manual(values = c(no='#FFFFFF', yes="#000000"),
                    labels = c(no='No', yes='Yes'),
                    guide = guide_legend(title = 'Is Severe',
                                         label.position = 'top',
                                         order = 1)) +
  scale_color_manual(values = model_colors,
                     labels = c(idsa='IDSA', attrib='Attributable', 
                                allcause='All-cause', pragmatic='Pragmatic'),
  ) +
  guides(color = 'none') +
  labs(title = otu25_label, x = expression(''*log[10]*' Relative Abundance')) +
  theme_sovacool() +
  theme(text = element_text(size = 10, family = 'Helvetica'),
        plot.title = element_markdown(),
        axis.title.y = element_blank(),
        panel.grid.major.y = element_blank(),
        legend.position = 'top')

feat_plot <- feat_dat %>% 
  mutate(outcome = factor(outcome, levels = c('idsa', 'allcause', 'attrib', 'pragmatic'))) %>% 
  ggplot(aes(x = perf_metric_diff, y = outcome, color = outcome))+
  stat_summary(fun = mean,
               fun.max = ~ quantile(.x, 0.75),
               fun.min = ~ quantile(.x, 0.25),
               geom = 'pointrange',
               position = position_dodge(width = 0.5),
               alpha = 0.6) +
  geom_hline(yintercept = seq(1.5, 3.5, 1), 
             lwd = 0.5, colour = "grey92") +
  geom_vline(xintercept = 0, linetype = 'dotted') +
  scale_color_manual(values = model_colors,
                     labels = c(idsa='IDSA', attrib='Attributable', 
                                allcause='All-cause', pragmatic='Pragmatic'),
                     guide = guide_legend(title = '',
                                          label.position = 'top',
                                          order = 1)
  ) +
  labs(x='Difference in AUROC') +
  theme_sovacool() +
  theme(text = element_text(size = 10, family = 'Helvetica'),
        axis.title.y = element_blank(),
        axis.text.y = element_blank(),
        axis.ticks.y = element_blank(),
        panel.grid.major.y = element_blank(),
        legend.position = 'top')

fig <- 
  plot_grid(relabun_plot, feat_plot,
            nrow = 1, align = 'h',axis = 'tb'
            )
ggsave(
  filename = here('figures', 'cdiff-otu.tiff'), 
  plot = fig,
  device = "tiff", compression = "lzw", dpi = 600, 
  units = "in", width = 6.875, height = 5 # https://journals.asm.org/figures-tables
)
