Preliminary results for predicting adverse CDI outcomes
================
2022-04-28

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
seq_metadat <- read_tsv(here('data', 'process', 'final_CDI_16S_metadata.tsv')) %>% 
              rename(sample_id = `CDIS_Sample ID`, 
                     subject_id = `CDIS_Study ID`,
                     collection_date = `CDIS_collect date`) %>% 
  full_join(read_csv(here('data', 'process', 'case_idsa_severity.csv')) %>% 
              rename(sample_id = sample,
                     idsa_lab = idsa_severity),
            by = 'sample_id')

attrib_dat <- read_csv(here('data', 'raw', 'mishare', 
                            'clinical_outcomes.csv')) %>% 
  select(-CDIFF_SAMPLE_DATE, -CDIFF_COLLECT_DTM) %>% 
  mutate(chart_reviewed = TRUE)
unattrib_dat <- read_csv(here('data', 'raw', 'mishare', 
                              'clinical_outcomes_pt2.csv'))  %>% 
  select(-CDIFF_SAMPLE_DATE, -CDIFF_COLLECT_DTM) %>% 
  mutate(chart_reviewed = FALSE) 
metadat <- bind_rows(attrib_dat, unattrib_dat) %>% 
  rename(sample_id = SAMPLE_ID, 
         idsa_chart = IDSA_severe,
         attrib = ATTRIB_SEVERECDI,
         unattrib = UNATTRIB_SEVERECDI) %>% 
  select(-SUBJECT_ID) %>% 
  full_join(seq_metadat,
            by = c('sample_id')) %>% 
  filter(!is.na(cdiff_case)) %>% 
  mutate(idsa = case_when(idsa_chart == 1 ~ 'yes',
                          idsa_chart == 0 ~ 'no',
                          TRUE ~ idsa_lab),
         attrib = case_when(attrib == 1 ~ 'yes',
                            attrib == 0 ~ 'no',
                            TRUE ~ NA_character_),
         unattrib = case_when(unattrib == 1 ~ 'yes',
                              unattrib == 0 ~ 'no',
                              TRUE ~ NA_character_),
         allcause = case_when(attrib == 'yes' | unattrib == 'yes' ~ 'yes',
                              attrib == 'no' & unattrib == 'no' ~ 'no',
                              is.na(attrib) ~ unattrib,
                              TRUE ~ NA_character_)
         ) %>% 
  select(sample_id, subject_id, collection_date, cdiff_case, 
         chart_reviewed, idsa, attrib, unattrib, allcause) 
```

``` r
multi_samples <-
  metadat %>% 
  group_by(subject_id) %>% 
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
| Case       | 1191 |
| Control    | 2135 |

## IDSA severity

``` r
metadat_cases %>% group_by(idsa) %>% tally() %>% kable()
```

| idsa |   n |
|:-----|----:|
| no   | 649 |
| yes  | 342 |
| NA   | 200 |

## Attributable severity

``` r
metadat_cases %>% group_by(attrib) %>% tally() %>% kable()
```

| attrib |   n |
|:-------|----:|
| no     | 513 |
| yes    |  26 |
| NA     | 652 |

## All-cause severity

``` r
metadat_cases %>%  group_by(attrib, unattrib, allcause) %>% tally() %>% kable()
```

| attrib | unattrib | allcause |   n |
|:-------|:---------|:---------|----:|
| no     | no       | no       | 495 |
| no     | yes      | yes      |  18 |
| yes    | yes      | yes      |  26 |
| NA     | no       | no       | 564 |
| NA     | yes      | yes      |  39 |
| NA     | NA       | NA       |  49 |

``` r
metadat_cases %>% group_by(allcause) %>% tally() %>% kable()
```

| allcause |    n |
|:---------|-----:|
| no       | 1059 |
| yes      |   83 |
| NA       |   49 |

## idsa x attrib x allcause

``` r
metadat_cases %>% 
  group_by(idsa, attrib, unattrib) %>% 
  tally() %>% kable()
```

| idsa | attrib | unattrib |   n |
|:-----|:-------|:---------|----:|
| no   | no     | no       | 291 |
| no   | no     | yes      |   6 |
| no   | yes    | yes      |   7 |
| no   | NA     | no       | 317 |
| no   | NA     | yes      |   7 |
| no   | NA     | NA       |  21 |
| yes  | no     | no       | 121 |
| yes  | no     | yes      |  12 |
| yes  | yes    | yes      |  19 |
| yes  | NA     | no       | 150 |
| yes  | NA     | yes      |  32 |
| yes  | NA     | NA       |   8 |
| NA   | no     | no       |  83 |
| NA   | NA     | no       |  97 |
| NA   | NA     | NA       |  20 |

``` r
metadat_cases %>% 
  group_by(idsa, allcause) %>% 
  tally() %>% kable()
```

| idsa | allcause |   n |
|:-----|:---------|----:|
| no   | no       | 608 |
| no   | yes      |  20 |
| no   | NA       |  21 |
| yes  | no       | 271 |
| yes  | yes      |  63 |
| yes  | NA       |   8 |
| NA   | no       | 180 |
| NA   | NA       |  20 |
