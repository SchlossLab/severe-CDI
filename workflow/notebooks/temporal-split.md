Temporal Split
================
2022-01-19

Investigate feasibility of doing a temporal split to train/test models
on older data and then validate on newer data. Bootstrap the test data
to get empirical 95% CI.

Do the 20% most recent patients have the same proportion of severe cases
as the other 80% of the patients?

    ## [1] 91

    ## [1] 365

    ## [1] 456

| severity     | train |  test |
|:-------------|------:|------:|
| idsa_no      | 0.671 | 0.648 |
| idsa_yes     | 0.329 | 0.352 |
| attrib_no    | 0.940 | 0.956 |
| attrib_yes   | 0.060 | 0.044 |
| allcause_no  | 0.907 | 0.890 |
| allcause_yes | 0.093 | 0.110 |

## try bootstrapping with rsample

    ## # A tibble: 15 × 6
    ##    term              .lower .estimate .upper .alpha .method   
    ##    <chr>              <dbl>     <dbl>  <dbl>  <dbl> <chr>     
    ##  1 Accuracy           0.565     0.625  0.727   0.05 percentile
    ##  2 AUC                0.483     0.532  0.602   0.05 percentile
    ##  3 Balanced_Accuracy  0.5       0.5    0.5     0.05 percentile
    ##  4 cv_metric_AUC      0.529     0.529  0.529   0.05 percentile
    ##  5 Detection_Rate     0         0.377  0.725   0.05 percentile
    ##  6 F1                 0.721     0.770  0.847   0.05 percentile
    ##  7 Kappa              0         0      0       0.05 percentile
    ##  8 logLoss            0.596     0.672  0.719   0.05 percentile
    ##  9 Neg_Pred_Value     0.594     0.621  0.657   0.05 percentile
    ## 10 Pos_Pred_Value     0.563     0.628  0.735   0.05 percentile
    ## 11 prAUC              0.470     0.507  0.566   0.05 percentile
    ## 12 Precision          0.563     0.628  0.735   0.05 percentile
    ## 13 Recall             0         0.6    1       0.05 percentile
    ## 14 Sensitivity        0         0.6    1       0.05 percentile
    ## 15 Specificity        0         0.4    1       0.05 percentile

## Plot performance

![](figures/perf-95-ci-1.png)<!-- -->
