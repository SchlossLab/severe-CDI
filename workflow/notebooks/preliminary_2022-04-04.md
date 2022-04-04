Preliminary results for predicting adverse CDI outcomes
================
2022-04-04

``` r
library(tidyverse)
```

    ## ── Attaching packages ─────────────────────────────────────── tidyverse 1.3.1 ──

    ## ✓ ggplot2 3.3.5     ✓ purrr   0.3.4
    ## ✓ tibble  3.1.6     ✓ dplyr   1.0.8
    ## ✓ tidyr   1.2.0     ✓ stringr 1.4.0
    ## ✓ readr   2.1.1     ✓ forcats 0.5.1

    ## ── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
    ## x dplyr::filter() masks stats::filter()
    ## x dplyr::lag()    masks stats::lag()

``` r
library(here)
```

    ## here() starts at /Users/kelly/projects/schloss-lab/adverse-CDI

``` r
library(data.table)
```

    ## 
    ## Attaching package: 'data.table'

    ## The following objects are masked from 'package:dplyr':
    ## 
    ##     between, first, last

    ## The following object is masked from 'package:purrr':
    ## 
    ##     transpose

``` r
source(here('workflow', 'scripts', 'filter_first_samples.R')) 
```

## Load data

``` r
dat_shared <- fread(here('data', 'mothur', 'cdi.opti_mcc.shared')) %>% rename(Run = Group)
metadat <- read_tsv(here('data', 'process', 'final_CDI_16S_metadata.tsv')) %>% 
  rename(sample_id = `CDIS_Sample ID`, patient_id = `CDIS_Study ID`)
```

    ## Rows: 4035 Columns: 14
    ## ── Column specification ────────────────────────────────────────────────────────
    ## Delimiter: "\t"
    ## chr  (12): CDIS_Study ID, CDIS_Aliquot ID, plate, plate_location, pbs_added,...
    ## dbl   (1): nseqs
    ## dttm  (1): CDIS_collect date
    ## 
    ## ℹ Use `spec()` to retrieve the full column specification for this data.
    ## ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.

``` r
idsa_sra <-
  full_join(
    read_csv((
      here('data', 'process', 'case_idsa_severity.csv')
    )) %>%
      rename(sample_id = sample),
    read_csv(here('data', 'SraRunTable.csv')) %>% 
      rename(sample_id = sample_title),
    by = "sample_id"
  ) %>%
  select(sample_id, idsa_severity, Run, patient_id, collection_date) %>%
  left_join(metadat %>% select(sample_id, cdiff_case),
            by = "sample_id")
```

    ## Rows: 1159 Columns: 2
    ## ── Column specification ────────────────────────────────────────────────────────
    ## Delimiter: ","
    ## chr (2): sample, idsa_severity
    ## 
    ## ℹ Use `spec()` to retrieve the full column specification for this data.
    ## ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.

    ## Warning: One or more parsing issues, see `problems()` for details

    ## Rows: 4032 Columns: 89
    ## ── Column specification ────────────────────────────────────────────────────────
    ## Delimiter: ","
    ## chr  (51): Run, Assay Type, BioProject, BioSample, BioSampleModel, Center Na...
    ## dbl   (3): AvgSpotLen, Bases, Bytes
    ## lgl  (34): diet, Genotype, organism_count, perturbation, Abx, Asian, Black, ...
    ## dttm  (1): ReleaseDate
    ## 
    ## ℹ Use `spec()` to retrieve the full column specification for this data.
    ## ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.

``` r
multi_samples <-
  idsa_sra %>% 
  group_by(patient_id) %>% 
  filter(cdiff_case == "Case") %>% 
  tally() %>% 
  filter(n > 1)

one_sample_per_patient_idsa <- filter_first_samples(idsa_sra)

cases_severity_OTUs_idsa <-
  left_join(one_sample_per_patient_idsa, dat_shared, 
            by = "Run") %>%
  filter(cdiff_case == 'Case', !is.na(idsa_severity)) %>%
  select(idsa_severity, starts_with("Otu")) %>%
  rename(idsa = idsa_severity)
```

``` r
attrib_dat <-
  full_join(read_csv((here('data', 'raw', 'mishare', 'clinical_outcomes.csv'))) %>%
              rename(sample_id = SAMPLE_ID),
            read_csv(here('data', 'SraRunTable.csv')) %>% 
              rename(sample_id = sample_title), by = "sample_id") %>% 
  rename(attrib = ATTRIB_SEVERECDI) %>% 
  mutate(attrib = case_when(attrib == 0 ~ "no",
                            attrib == 1 ~ "yes",
                            TRUE ~ NA_character_)) %>% 
  select(sample_id, patient_id, collection_date, attrib, Run) %>% 
  left_join(metadat %>% 
              select(sample_id, cdiff_case), by = "sample_id") 
```

    ## New names:
    ## * `` -> ...1

    ## Rows: 1338 Columns: 27
    ## ── Column specification ────────────────────────────────────────────────────────
    ## Delimiter: ","
    ## chr  (8): SAMPLE_ID, SUBJECT_ID, CDIFF_SAMPLE_DATE, ANTIGEN_TEST, TOXIN_TEST...
    ## dbl (19): ...1, CDIFF_POS_POST_NM, DEATH_14_YN, DEATH_30_YN, DEATH_365_YN, D...
    ## 
    ## ℹ Use `spec()` to retrieve the full column specification for this data.
    ## ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.

    ## Warning: One or more parsing issues, see `problems()` for details

    ## Rows: 4032 Columns: 89
    ## ── Column specification ────────────────────────────────────────────────────────
    ## Delimiter: ","
    ## chr  (51): Run, Assay Type, BioProject, BioSample, BioSampleModel, Center Na...
    ## dbl   (3): AvgSpotLen, Bases, Bytes
    ## lgl  (34): diet, Genotype, organism_count, perturbation, Abx, Asian, Black, ...
    ## dttm  (1): ReleaseDate
    ## 
    ## ℹ Use `spec()` to retrieve the full column specification for this data.
    ## ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.

``` r
multi_samples_attrib <- attrib_dat %>% 
  group_by(patient_id) %>% 
  filter(cdiff_case == "Case") %>% 
  tally() %>% 
  filter(n > 1)

one_sample_per_patient_attrib <- filter_first_samples(attrib_dat)

cases_severity_OTUs_attrib <- 
  left_join(one_sample_per_patient_attrib, dat_shared, by = "Run") %>% 
  filter(cdiff_case == 'Case', !is.na(attrib)) %>% 
  select(attrib, starts_with("Otu")) 
```

``` r
allcause_dat <-
  full_join(read_csv((here('data', 'raw', 'mishare', 'clinical_outcomes_pt2.csv'))) %>%
              rename(sample_id = SAMPLE_ID),
            read_csv(here('data', 'SraRunTable.csv')) %>% rename(sample_id = sample_title),
            by = "sample_id") %>% 
  rename(unattrib = UNATTRIB_SEVERECDI) %>% 
  mutate(unattrib = case_when(unattrib == 0 ~ "no",
                              unattrib == 1 ~ "yes",
                              TRUE ~ NA_character_)) %>% 
  select(sample_id, patient_id, collection_date, unattrib, Run) %>% 
  left_join(metadat %>% 
              select(sample_id, cdiff_case),by = "sample_id") %>% 
  left_join(attrib_dat, 
            by = c("sample_id", "patient_id", "collection_date", "cdiff_case", "Run")) %>% 
  mutate(allcause = case_when((attrib=="yes") | (unattrib=="yes") ~ "yes", 
                              (attrib=="no") | (unattrib=="no") ~ "no",
                              is.na(attrib) | is.na(unattrib) ~ NA_character_)
         )
```

    ## New names:
    ## * `` -> ...1

    ## Rows: 2472 Columns: 22
    ## ── Column specification ────────────────────────────────────────────────────────
    ## Delimiter: ","
    ## chr   (5): SAMPLE_ID, ANTIGEN_TEST, TOXIN_TEST, PCR_TEST, CDIFF_RESULT_TEXT
    ## dbl  (15): ...1, CDIFF_POS_POST_NM, DEATH_14_YN, DEATH_30_YN, DEATH_365_YN, ...
    ## date  (2): CDIFF_SAMPLE_DATE, CDIFF_COLLECT_DTM
    ## 
    ## ℹ Use `spec()` to retrieve the full column specification for this data.
    ## ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.

    ## Warning: One or more parsing issues, see `problems()` for details

    ## Rows: 4032 Columns: 89
    ## ── Column specification ────────────────────────────────────────────────────────
    ## Delimiter: ","
    ## chr  (51): Run, Assay Type, BioProject, BioSample, BioSampleModel, Center Na...
    ## dbl   (3): AvgSpotLen, Bases, Bytes
    ## lgl  (34): diet, Genotype, organism_count, perturbation, Abx, Asian, Black, ...
    ## dttm  (1): ReleaseDate
    ## 
    ## ℹ Use `spec()` to retrieve the full column specification for this data.
    ## ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.

``` r
multi_samples_allcause <- allcause_dat %>% 
  group_by(patient_id) %>% 
  filter(cdiff_case == "Case") %>% 
  tally() %>% 
  filter(n > 1)

one_sample_per_patient_allcause <- filter_first_samples(allcause_dat)

cases_severity_OTUs_allcause <-
  left_join(one_sample_per_patient_allcause, dat_shared, by = "Run") %>%
  filter(cdiff_case == 'Case', !is.na(allcause)) %>%
  select(allcause, starts_with("Otu")) 
```

## CDI cases

``` r
idsa_sra %>% group_by(cdiff_case) %>% tally()
```

    ## # A tibble: 3 × 2
    ##   cdiff_case     n
    ##   <chr>      <int>
    ## 1 Case        1516
    ## 2 Control     2425
    ## 3 <NA>          91

### excluding longitudinal samples

``` r
idsa_sra %>% filter_first_samples() %>% group_by(cdiff_case) %>% tally()
```

    ## # A tibble: 3 × 2
    ##   cdiff_case     n
    ##   <chr>      <int>
    ## 1 Case        1193
    ## 2 Control     2132
    ## 3 <NA>           2

## IDSA severity

``` r
cases_severity_OTUs_idsa %>% group_by(idsa) %>% tally()
```

    ## # A tibble: 2 × 2
    ##   idsa      n
    ##   <chr> <int>
    ## 1 no      544
    ## 2 yes     389

## Attributable severity

``` r
cases_severity_OTUs_attrib %>% group_by(attrib) %>% tally()
```

    ## # A tibble: 2 × 2
    ##   attrib     n
    ##   <chr>  <int>
    ## 1 no       513
    ## 2 yes       26

## All-cause severity

``` r
one_sample_per_patient_allcause %>% filter(cdiff_case == 'Case') %>%  group_by(attrib, unattrib, allcause) %>% tally()
```

    ## # A tibble: 5 × 4
    ## # Groups:   attrib, unattrib [5]
    ##   attrib unattrib allcause     n
    ##   <chr>  <chr>    <chr>    <int>
    ## 1 no     <NA>     no         511
    ## 2 yes    <NA>     yes         26
    ## 3 <NA>   no       no         563
    ## 4 <NA>   yes      yes         39
    ## 5 <NA>   <NA>     <NA>        49

``` r
cases_severity_OTUs_allcause %>% group_by(allcause) %>% tally()
```

    ## # A tibble: 2 × 2
    ##   allcause     n
    ##   <chr>    <int>
    ## 1 no        1074
    ## 2 yes         65

## idsa x attrib x allcause

``` r
case_dat <- full_join(one_sample_per_patient_idsa, 
                      one_sample_per_patient_allcause, 
                      by = c('sample_id', 'patient_id', 'Run', 'collection_date', 'cdiff_case')
                      ) %>% 
  filter(cdiff_case == 'Case') %>% 
  rename(idsa = idsa_severity)
case_dat %>% 
  group_by(idsa, attrib, unattrib) %>% 
  tally()
```

    ## # A tibble: 14 × 4
    ## # Groups:   idsa, attrib [9]
    ##    idsa  attrib unattrib     n
    ##    <chr> <chr>  <chr>    <int>
    ##  1 no    no     <NA>       255
    ##  2 no    yes    <NA>         6
    ##  3 no    <NA>   no         253
    ##  4 no    <NA>   yes          7
    ##  5 no    <NA>   <NA>        23
    ##  6 yes   no     <NA>       139
    ##  7 yes   yes    <NA>        18
    ##  8 yes   <NA>   no         189
    ##  9 yes   <NA>   yes         32
    ## 10 yes   <NA>   <NA>        11
    ## 11 <NA>  no     <NA>       117
    ## 12 <NA>  yes    <NA>         2
    ## 13 <NA>  <NA>   no         121
    ## 14 <NA>  <NA>   <NA>        20

``` r
case_dat %>% 
  group_by(idsa, allcause) %>% 
  tally()
```

    ## # A tibble: 9 × 3
    ## # Groups:   idsa [3]
    ##   idsa  allcause     n
    ##   <chr> <chr>    <int>
    ## 1 no    no         508
    ## 2 no    yes         13
    ## 3 no    <NA>        23
    ## 4 yes   no         328
    ## 5 yes   yes         50
    ## 6 yes   <NA>        11
    ## 7 <NA>  no         238
    ## 8 <NA>  yes          2
    ## 9 <NA>  <NA>        20
