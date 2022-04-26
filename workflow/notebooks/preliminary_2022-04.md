Preliminary results for predicting adverse CDI outcomes
================
2022-04-26

## load data

``` r
library(data.table)
library(here)
library(knitr)
library(tidyverse)

source(here('workflow', 'scripts', 'filter_first_samples.R')) 
```

``` r
otu_dat <- read_csv(here('data', 'SraRunTable.csv')) %>% 
              rename(sample_id = sample_title) %>% 
  left_join(fread(here('data', 'mothur', 'cdi.opti_mcc.shared')) %>% 
  rename(Run = Group), by = 'Run')
attrib_dat <- read_csv(here('data', 'raw', 'mishare', 
                            'clinical_outcomes.csv')) %>% 
  select(-CDIFF_SAMPLE_DATE, -CDIFF_COLLECT_DTM)
unattrib_dat <- read_csv(here('data', 'raw', 'mishare', 
                              'clinical_outcomes_pt2.csv'))  %>% 
  select(-CDIFF_SAMPLE_DATE, -CDIFF_COLLECT_DTM)
metadat <- bind_rows(attrib_dat, unattrib_dat) %>% 
  select(SAMPLE_ID, SUBJECT_ID, 
         IDSA_severe, ATTRIB_SEVERECDI, UNATTRIB_SEVERECDI) %>% 
  rename(sample_id = SAMPLE_ID, 
         subject_id = SUBJECT_ID,
         idsa = IDSA_severe,
         attrib = ATTRIB_SEVERECDI,
         unattrib = UNATTRIB_SEVERECDI) %>% 
  full_join(read_tsv(here('data', 'process', 'final_CDI_16S_metadata.tsv')) %>% 
              rename(sample_id = `CDIS_Sample ID`, 
                     subject_id = `CDIS_Study ID`,
                     collection_date = `CDIS_collect date`), 
            by = c('sample_id', 'subject_id')) %>% 
  select(sample_id, subject_id, collection_date, cdiff_case, group, idsa, attrib, unattrib) %>% 
  filter(!is.na(cdiff_case)) %>% 
  mutate(allcause = case_when((attrib == 1 | unattrib == 1) ~ 'yes',
                              (attrib == 0 & unattrib == 0) ~ 'no',
                              TRUE ~ NA_character_)
         )
```

``` r
multi_samples <-
  metadat %>% 
  group_by(subject_id) %>% 
  filter(group == "case") %>% 
  tally() %>% 
  filter(n > 1)

metadat_1s <- filter_first_samples(metadat)
metadat_cases <- metadat_1s %>% filter(cdiff_case == 'Case')
```

## CDI cases

``` r
metadat %>% group_by(cdiff_case) %>% tally() %>% kable()
```

| cdiff_case |    n |
|:-----------|-----:|
| Case       | 1517 |
| Control    | 2426 |

### excluding longitudinal samples

``` r
metadat_1s %>% group_by(cdiff_case) %>% tally() %>% kable()
```

| cdiff_case |    n |
|:-----------|-----:|
| Case       | 1190 |
| Control    | 2136 |

## IDSA severity

``` r
metadat_cases %>% group_by(idsa) %>% tally() %>% kable()
```

| idsa |   n |
|-----:|----:|
|    0 | 201 |
|    1 | 122 |
|   NA | 867 |

## Attributable severity

``` r
metadat_cases %>% group_by(attrib) %>% tally() %>% kable()
```

| attrib |   n |
|-------:|----:|
|      0 | 510 |
|      1 |  26 |
|     NA | 654 |

## All-cause severity

``` r
metadat_cases %>% group_by(allcause) %>% tally() %>% kable()
```

| allcause |   n |
|:---------|----:|
| no       | 492 |
| yes      |  44 |
| NA       | 654 |

``` r
metadat_cases %>%  group_by(attrib, unattrib, allcause) %>% tally() %>% kable()
```

| attrib | unattrib | allcause |   n |
|-------:|---------:|:---------|----:|
|      0 |        0 | no       | 492 |
|      0 |        1 | yes      |  18 |
|      1 |        1 | yes      |  26 |
|     NA |       NA | NA       | 654 |

## idsa x attrib x allcause

``` r
metadat_cases %>% 
  group_by(idsa, attrib, unattrib) %>% 
  tally() %>% kable()
```

| idsa | attrib | unattrib |   n |
|-----:|-------:|---------:|----:|
|    0 |      0 |        0 | 190 |
|    0 |      0 |        1 |   4 |
|    0 |      1 |        1 |   7 |
|    1 |      0 |        0 |  97 |
|    1 |      0 |        1 |   9 |
|    1 |      1 |        1 |  16 |
|   NA |      0 |        0 | 205 |
|   NA |      0 |        1 |   5 |
|   NA |      1 |        1 |   3 |
|   NA |     NA |       NA | 654 |

``` r
metadat_cases %>% 
  group_by(idsa, allcause) %>% 
  tally() %>% kable()
```

| idsa | allcause |   n |
|-----:|:---------|----:|
|    0 | no       | 190 |
|    0 | yes      |  11 |
|    1 | no       |  97 |
|    1 | yes      |  25 |
|   NA | no       | 205 |
|   NA | yes      |   8 |
|   NA | NA       | 654 |
