Temporal Split
================
2022-01-19

``` r
library(here)
library(mikropml)
library(rlang)
library(tidyverse)
```

Investigate feasibility of doing a temporal split to train/test models
on older data and then validate on newer data. Bootstrap the test data
to get empirical 95% CI.

Do the 20% most recent patients have the same proportion of severe cases
as the other 80% of the patients?

``` r
metadat_full <- read_csv(here('data','process','cases_full_metadata.csv'))
metadat_int <- read_csv(here('data','process','cases_int_metadata.csv'))
```

``` r
count_prop <- function(dat, colname, part) {
  dat %>% 
    count({{ colname }}) %>% 
    mutate(p = round(n / sum(n), 3)) %>% 
    mutate(partition = part) %>% 
    select(partition, p, {{ colname }}) %>% 
    pivot_wider(names_from = partition, values_from = p)
}
compare_props <- function(test_dat, train_dat, colname) {
  test <- test_dat %>% 
    count_prop({{ colname }}, 'test')
  train <- train_dat %>% 
    count_prop({{ colname }}, 'train')
  full_join(test, train) %>% 
    mutate(severity = paste(quo_name(enquo(colname)), {{ colname }}, sep = "_")
    ) %>% 
    select(severity, train, test)
}
```

``` r
test_dat_int <- metadat_int %>% 
  arrange(desc(collection_date)) %>% 
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
partitions_int <- bind_rows(
  compare_props(test_dat_int, train_dat_int, idsa),
  compare_props(test_dat_int, train_dat_int, attrib),
  compare_props(test_dat_int, train_dat_int, allcause)
) 

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
