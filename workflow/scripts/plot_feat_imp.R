source("workflow/scripts/log_smk.R")
library(cowplot)
library(ggtext)
library(glue)
library(here)
library(tidyverse)
model_colors <- RColorBrewer::brewer.pal(3, 'Dark2')
names(model_colors) <- c("idsa", 'attrib', 'allcause')

feat_dat <- read_csv("results/feature-importance_results_aggregated.csv") %>% 
  rename(otu = names)
tax_dat <- schtools::read_tax("data/mothur/cdi.taxonomy")
alpha_level <- 0.05

dat <- full_join(feat_dat, tax_dat, by = 'otu')

top_otus_dat <- dat %>% 
    group_by(outcome, label_html) %>% 
    summarize(median_auroc = median(perf_metric_diff)) %>% #Get the median performance metric diff. for each feature
    #arrange(desc(median)) %>% #Arrange from largest median to smallest
    slice_max(n = 5, order_by = median_auroc)

top_otus_order <- top_otus_dat %>%
  group_by(label_html) %>% 
  summarize(max_med = max(median_auroc)) %>% 
  arrange(max_med) %>% 
  pull(label_html)


otu_sets <- data.frame(label_html = top_otus_order) %>% 
  mutate(idsa = label_html %in% (top_otus_dat %>% filter(outcome == 'idsa') %>% pull(label_html)),
         attrib = label_html %in% (top_otus_dat %>% filter(outcome == 'attrib') %>% pull(label_html)),
         allcause = label_html %in% (top_otus_dat %>% filter(outcome == 'allcause') %>% pull(label_html))
         ) %>% 
  pivot_longer(c(idsa, attrib, allcause), names_to = "group", values_to = 'bool') %>% 
  mutate(label_html = factor(label_html, levels = top_otus_order),
         group_html = glue("<span style = 'color:{model_colors[group]};'>{group}</span>"),
         color_hex = case_when(bool == TRUE ~ model_colors[group],
                               bool == FALSE ~ "white",
                               TRUE ~ NA_character_)) %>% 
  mutate(group_html = fct_relevel(factor(group_html),
                                "<span style = 'color:#1B9E77;'>idsa</span>", 
                                "<span style = 'color:#D95F02;'>attrib</span>", 
                                "<span style = 'color:#7570B3;'>allcause</span>"))
dotplot_colors <- otu_sets %>% pull(color_hex) %>% unique()
names(dotplot_colors) <- dotplot_colors

otu_sets_plot <- otu_sets  %>%
  ggplot(aes(x = group_html, y = label_html)) +
  geom_tile(colour = "whitesmoke", size=0.5, fill = "white") +
  geom_point(aes(color = color_hex), size = 4) + 
  coord_fixed(ratio=1) +  
  scale_color_manual(values = dotplot_colors) +
  scale_x_discrete(position = 'top') +
  theme_minimal(base_size = 8) +
  theme(legend.position = "",
        axis.text.y = element_markdown(size = 8),
        axis.text.x.top = element_markdown(size = 8, angle = 45, 
                                           hjust = -0.1, vjust = -0.2),
        panel.grid = element_blank(),
        axis.ticks = element_blank(),
        axis.title = element_blank(),
        plot.margin = unit(x = c(0, 12, 0, 0), units = "pt"))


feat_imp_plot <- dat %>% 
  filter(label_html %in% top_otus_order) %>% 
  mutate(label_html = factor(label_html, levels = top_otus_order)) %>% 
  ggplot(aes(x = perf_metric_diff, 
             y = label_html, 
             color = outcome))+
    stat_summary(fun = 'median', 
                 fun.max = function(x) quantile(x, 0.75), 
                 fun.min = function(x) quantile(x, 0.25),
                 position = position_dodge(width = 0.4)) +
  geom_hline(yintercept = seq(1.5, length(unique(dat$label_html))-0.5, 1), 
             lwd = 0.5, colour = "whitesmoke") +
    scale_color_manual(values = model_colors) +
    labs(title=NULL, 
         y=NULL,
         x="Difference in AUROC") +
    theme_bw() +
    theme(text = element_text(size = 8),
          axis.text.y = element_blank(), 
          axis.text.x = element_text(size = 8),
          strip.background = element_blank(),
          legend.position = "none",
          panel.grid.major.y = element_blank(),
          plot.margin = unit(x = c(0, 0, 0, 0), units = "pt")) 

combined_plot <- plot_grid(otu_sets_plot, feat_imp_plot, 
                           align = 'h', nrow = 1, rel_widths = c(0.52, 0.48))
ggsave(
    filename = here('figures', 'plot_feat_imp.png'), 
    plot = combined_plot,
    device = "png", dpi = 300, 
    units = "in", width = 5, height = 4
    )
