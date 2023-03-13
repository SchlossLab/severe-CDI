source("workflow/scripts/log_smk.R")
library(tidyverse)
dat <- read_csv("results/performance_results_aggregated.csv") %>%
  rename(AUROC = AUC) #%>% 
#filter(method == 'rf', dataset == 'int', trainfrac == 0.65) 
temp <- dat %>% filter(metric == "AUC")
# get median values
#TODO: make into train and test median vals, add to plot
dataMedian <- summarise(group_by(temp, outcome), med = median(AUROC))

# plot performance
perf_plot <- temp %>% 
  pivot_longer(c(AUROC),
               names_to = "perf_metric"
  ) %>%
  mutate(data_partition = case_when(stringr::str_detect(perf_metric, 'cv_metric_AUC') ~ 'train',
                          TRUE ~ 'test'),
         outcome = case_when(outcome == 'idsa' ~ 'IDSA',
                             outcome == 'attrib' ~ 'Attributable',
                             outcome == 'allcause' ~ 'Allcause',
                             TRUE ~ NA_character_),
         dataset = case_when(data_partition == 'test' ~ 'Test',
                                data_partition == 'train' ~ 'Train')
  ) %>%
  ggplot(aes(x = value, y = outcome, color = data_partition)) +
  #geom_vline(xintercept = 0.5, linetype = "dashed") +
  geom_boxplot() +
  # geom_text(data = dataMedian, aes(x = med, y = outcome, label = med), 
  #           size = 3, vjust = -1.5) +
  scale_color_brewer(palette = 'Paired') +
  labs(x = "AUROC") +
  theme_bw() +
  theme(
    plot.margin = unit(x = c(0, 0, 0, 0), units = "pt"),
    axis.title.y = element_blank(),
    legend.position = 'top',
    legend.margin = margin(0, 0, 0, 0, unit = "pt")
  )
  # + stat_summary(fun = "median", geom = "text", hjust = 0.5, vjust = 0.9, label = dataMedian)

ggsave("figures/plot_perf.png", plot = perf_plot, device = "png", 
       width = 5, height = 5)
