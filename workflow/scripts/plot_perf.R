source("workflow/scripts/log_smk.R")
library(tidyverse)
dat <- read_csv(snakemake@input[["csv"]])
perf_plot <- dat %>%
    rename(
        `train AUROC` = cv_metric_AUC,
        `test AUROC` = AUC,
        `test AUPRC` = prAUC
    ) %>%
    pivot_longer(c(`train AUROC`, `test AUROC`, `test AUPRC`),
                 names_to = "metric"
    ) %>%
    mutate(metric = factor(metric,
                           levels = c("train AUROC", "test AUROC", "test AUPRC")
    )) %>%
    filter(metric != "test AUPRC") %>% # TODO: plot PRC separately with different baseline
    ggplot(aes(x = value, y = outcome, color = metric)) +
    geom_vline(xintercept = 0.5, linetype = "dashed") +
    geom_boxplot() +
    scale_color_brewer(palette = 'Dark2') +
    #facet_wrap('metric', ncol = 1) +
    #xlim(0.5, 1) +
    labs(x = "Performance", y = "") +
    theme_bw() +
    theme(
        plot.margin = unit(x = c(0, 5, 0, 0), units = "pt"),
        axis.title.y = element_blank()
    )
ggsave(snakemake@output[["png"]], plot = perf_plot, device = "png")
