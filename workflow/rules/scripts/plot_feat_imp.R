source("workflow/rules/scripts/log_smk.R")
library(tidyverse)
feat_dat <- read_csv("results/predict_allcause/feature-importance_results.csv")
tax_dat <- schtools::read_tax("data/mothur/cdi.taxonomy") # do i need the .tsv?
alpha_level = 0.05

# code from get_top_feats
feat_dat <- feat_dat %>%
        rename(otu = names)
tax_dat <- tax_dat %>%
        rename(otu = OTU) %>%
        mutate(label = str_replace(tax_otu_label, "(^\\w+) (.*)", "_\\1_ \\2"))
    
nseeds <- feat_dat %>%
        pull(seed) %>%
        unique() %>%
        length()
    
signif_feats <- feat_dat %>%
        filter(pvalue < alpha_level) %>%
        group_by(otu) %>%
        summarize(frac_sig = n() / (nseeds))
    
feats <- feat_dat %>%
        group_by(otu) %>%
        summarise(
            mean_auroc = mean(perf_metric),
            sd_auroc = sd(perf_metric),
            mean_diff = mean(perf_metric_diff),
            median_diff = median(perf_metric_diff),
            sd_diff = sd(perf_metric_diff),
            lowerq = quantile(perf_metric_diff)[2],
            upperq = quantile(perf_metric_diff)[4]
        ) %>%
        inner_join(signif_feats, by = c("otu")) %>%
        left_join(tax_dat %>% select(otu, label), by = "otu") %>%
        ungroup() %>%
        arrange(mean_diff)
    
top_20 <- feats %>%
        filter(mean_diff > 0) %>%
        slice_max(n = 20, order_by = mean_diff) %>%
        pull(otu)
    
top_feats <- feats %>%
               filter(otu %in% top_20) %>%
               mutate(
                   label = fct_reorder(as.factor(label), mean_diff),
                   percent_models_signif = frac_sig * 100
               )

# code from plot_feat_imp
feat_imp_plot <- top_feats %>%
        ggplot(aes(
            x = -mean_diff, y = label,
            color = percent_models_signif
        )) +
        geom_vline(xintercept = 0, linetype = "dashed") +
        geom_pointrange(aes(
            xmin = -mean_diff - sd_diff,
            xmax = -mean_diff + sd_diff
        )) +
        scale_color_continuous(type = "viridis", name = "% models") +
        labs(y = "", x = "Mean decrease in AUROC") +
        theme_bw() +
        theme(
            axis.text.y = element_markdown(),
            axis.title.y = element_blank(),
            legend.position = "bottom",
            legend.margin = margin(t = 0, r = 0, b = 0, l = 0, unit = "pt"),
            plot.margin = unit(x = c(17, 8, 0, 2), units = "pt")
        )


# feat_imp_plot <- get_top_feats(feat_dat, tax_dat, alpha_level = 0.05) %>%
    # plot_feat_imp()

ggsave(
    filename = snakemake@output[["plot"]], plot = feat_imp_plot,
    device = "png", dpi = 300, units = "in", width = 9, height = 5
)

