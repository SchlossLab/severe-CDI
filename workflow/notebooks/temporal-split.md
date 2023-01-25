Temporal Split
================
2022-01-19

``` r
library(here)
library(knitr)
library(mikropml)
library(rlang)
library(schtools)
library(tidyverse)
```

Investigate feasibility of doing a temporal split to train/test models
on older data and then validate on newer data. Bootstrap the test data
to get empirical 95% CI.

Do the 20% most recent patients have the same proportion of severe cases
as the other 80% of the patients?

``` r
metadat_full <- read_csv(here("data", "process", "cases_full_metadata.csv"))
metadat_int <- read_csv(here("data", "process", "cases_int_metadata.csv"))
```

``` r
count_prop <- function(dat, colname, part) {
    dat %>%
        count({
            {
                colname
            }
        }) %>%
        mutate(p = round(n/sum(n), 3)) %>%
        mutate(partition = part) %>%
        select(partition, p, {
            {
                colname
            }
        }) %>%
        pivot_wider(names_from = partition, values_from = p)
}
compare_props <- function(test_dat, train_dat, colname) {
    test <- test_dat %>%
        count_prop({
            {
                colname
            }
        }, "test")
    train <- train_dat %>%
        count_prop({
            {
                colname
            }
        }, "train")
    full_join(test, train) %>%
        mutate(severity = paste(quo_name(enquo(colname)), {
            {
                colname
            }
        }, sep = "_")) %>%
        select(severity, train, test)
}
```

``` r
test_dat_int <- metadat_int %>%
    slice_max(order_by = collection_date, prop = 0.2)

train_dat_int <- metadat_int %>%
    anti_join(test_dat_int)

nrow(test_dat_int)
```

    ## [1] 91

``` r
nrow(train_dat_int)
```

    ## [1] 365

``` r
nrow(metadat_int)
```

    ## [1] 456

``` r
partitions_int <- bind_rows(compare_props(test_dat_int, train_dat_int, idsa), compare_props(test_dat_int,
    train_dat_int, attrib), compare_props(test_dat_int, train_dat_int, allcause))

kable(partitions_int)
```

| severity     | train |  test |
|:-------------|------:|------:|
| idsa_no      | 0.671 | 0.648 |
| idsa_yes     | 0.329 | 0.352 |
| attrib_no    | 0.940 | 0.956 |
| attrib_yes   | 0.060 | 0.044 |
| allcause_no  | 0.907 | 0.890 |
| allcause_yes | 0.093 | 0.110 |

## try bootstrapping with rsample

``` r
library(furrr)
library(mikropml)
library(rsample)

model <- readRDS(here("results/predict_idsa/taxlevel_OTU/metric_AUC/dataset_int/trainfrac_0.8/temporal-split/glmnet_100_model.Rds"))

test_dat <- read_csv(here("results/predict_idsa/taxlevel_OTU/metric_AUC/dataset_int/trainfrac_0.8/temporal-split/glmnet_100_test-data.csv"))

calc_perf <- function(split) {
    get_performance_tbl(model, analysis(split), outcome_colname = "idsa", perf_metric_function = caret::multiClassSummary,
        perf_metric_name = "AUC", class_probs = TRUE, method = "glmnet", seed = 100) %>%
        select(-c(method, seed)) %>%
        mutate(across(everything(), as.numeric)) %>%
        pivot_longer(everything(), names_to = "term", values_to = "estimate")
}

boots <- bootstraps(test_dat, times = 10) %>%
    mutate(perf = future_map(splits, ~calc_perf(.x)))

int_pctl(boots, perf) %>%
    kable()
```

| term              |    .lower | .estimate |    .upper | .alpha | .method    |
|:------------------|----------:|----------:|----------:|-------:|:-----------|
| Accuracy          | 0.5604396 | 0.6296703 | 0.6678571 |   0.05 | percentile |
| AUC               | 0.4322505 | 0.5437002 | 0.6202419 |   0.05 | percentile |
| Balanced_Accuracy | 0.5000000 | 0.5000000 | 0.5000000 |   0.05 | percentile |
| cv_metric_AUC     | 0.5290527 | 0.5290527 | 0.5290527 |   0.05 | percentile |
| Detection_Rate    | 0.0000000 | 0.3901099 | 0.6678571 |   0.05 | percentile |
| F1                | 0.7713019 | 0.7879160 | 0.8016404 |   0.05 | percentile |
| Kappa             | 0.0000000 | 0.0000000 | 0.0000000 |   0.05 | percentile |
| logLoss           | 0.6390430 | 0.6666555 | 0.7179882 |   0.05 | percentile |
| Neg_Pred_Value    | 0.5604396 | 0.5989011 | 0.6373626 |   0.05 | percentile |
| Pos_Pred_Value    | 0.6277473 | 0.6501832 | 0.6689560 |   0.05 | percentile |
| prAUC             | 0.4452304 | 0.5097012 | 0.5564353 |   0.05 | percentile |
| Precision         | 0.6277473 | 0.6501832 | 0.6689560 |   0.05 | percentile |
| Recall            | 0.0000000 | 0.6000000 | 1.0000000 |   0.05 | percentile |
| Sensitivity       | 0.0000000 | 0.6000000 | 1.0000000 |   0.05 | percentile |
| Specificity       | 0.0000000 | 0.4000000 | 1.0000000 |   0.05 | percentile |

## Plot performance

``` r
perf_dat <- read_csv(here("results", "temporal-split", "performance_results.csv"))
perf_dat %>%
    filter(term %in% c("cv_metric_AUC", "AUC")) %>%
    mutate(term = case_when(term == "cv_metric_AUC" ~ "train AUROC", term == "AUC" ~
        "test AUROC", TRUE ~ term)) %>%
    rename(estimate = .estimate, lower = .lower, upper = .upper) %>%
    ggplot(aes(x = estimate, xmin = lower, xmax = upper, y = outcome, color = term)) +
    geom_pointrange(position = position_dodge(width = 0.1)) + facet_wrap("dataset") +
    theme_sovacool()
```

![](figures/temporal-split_perf-95-ci-1.png)<!-- -->

## Computational resources

``` r
bench_dat <- read_csv(here("results", "temporal-split", "benchmarks_results.csv"))
bench_dat %>%
    ggplot(aes(x = s, y = outcome, color = dataset)) + geom_point() + scale_x_time() +
    theme_sovacool()
```

![](figures/temporal-split_bench-1.png)<!-- -->

## Feature importance

``` r
feat_dat <- read_csv(here("results", "temporal-split", "feature-importance_results.csv"))
tax_dat <- read_tax(here("data", "mothur", "cdi.taxonomy"))
important_feats <- feat_dat %>%
    rename(otu = names) %>%
    left_join(tax_dat, by = "otu") %>%
    filter(pvalue < 0.05, perf_metric_diff > 0) %>%
    arrange(perf_metric_diff)
important_feats %>%
    mutate(otu = factor(otu, levels = important_feats %>%
        pull(otu) %>%
        unique())) %>%
    ggplot(aes(x = perf_metric_diff, y = label_html, color = outcome, shape = dataset)) +
    geom_point() + theme_sovacool() + theme(axis.text.y = ggtext::element_markdown())
```

![](figures/temporal-split_feat-imp-1.png)<!-- -->
