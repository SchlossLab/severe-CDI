source("workflow/rules/scripts/log_smk.R")
library(tidyverse)

perf_plot <- snakemake@input[["csv"]] %>%
  read_csv() %>%
    rename(
        `train AUROC` = cv_metric_AUC,
        `test AUROC` = AUC,
        `test AUPRC` = prAUC
    ) %>%
    pivot_longer(c(`train AUROC`, `test AUROC`, `test AUPRC`),
                 names_to = "metric"
    ) %>%
    mutate(metric = factor(metric,
                           levels = c("test AUPRC", "test AUROC", "train AUROC")
    )) %>%
    ggplot(aes(x = value, y = metric)) +
    geom_vline(xintercept = 0.5, linetype = "dashed") +
    geom_boxplot() +
    xlim(0.5, 1) +
    labs(x = "Performance", y = "") +
    theme_bw() +
    theme(
        plot.margin = unit(x = c(0, 5, 0, 0), units = "pt"),
        axis.title.y = element_blank()
    )
ggsave(snakemake@output[["plot"]], plot = perf_plot, device = "png")
