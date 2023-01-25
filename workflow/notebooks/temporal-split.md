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
    ##  1 Accuracy           0.582     0.643  0.720   0.05 percentile
    ##  2 AUC                0.396     0.533  0.625   0.05 percentile
    ##  3 Balanced_Accuracy  0.5       0.5    0.5     0.05 percentile
    ##  4 cv_metric_AUC      0.529     0.529  0.529   0.05 percentile
    ##  5 Detection_Rate     0         0.520  0.720   0.05 percentile
    ##  6 F1                 0.738     0.787  0.838   0.05 percentile
    ##  7 Kappa              0         0      0       0.05 percentile
    ##  8 logLoss            0.602     0.658  0.700   0.05 percentile
    ##  9 Neg_Pred_Value     0.584     0.615  0.647   0.05 percentile
    ## 10 Pos_Pred_Value     0.584     0.650  0.721   0.05 percentile
    ## 11 prAUC              0.431     0.504  0.563   0.05 percentile
    ## 12 Precision          0.584     0.650  0.721   0.05 percentile
    ## 13 Recall             0         0.8    1       0.05 percentile
    ## 14 Sensitivity        0         0.8    1       0.05 percentile
    ## 15 Specificity        0         0.2    1       0.05 percentile

## Plot performance

![](figures/temporal-split_perf-95-ci-1.png)<!-- -->

## Computational resources

![](figures/temporal-split_bench-1.png)<!-- -->

## Feature importance

![](figures/temporal-split_feat-imp-1.png)<!-- -->
