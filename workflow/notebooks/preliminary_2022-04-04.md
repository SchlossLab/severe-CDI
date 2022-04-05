Preliminary results for predicting adverse CDI outcomes
================
2022-04-05

    ## here() starts at /Users/kelly/projects/schloss-lab/adverse-CDI

    ## ── Attaching packages ─────────────────────────────────────── tidyverse 1.3.1 ──

    ## ✓ ggplot2 3.3.5     ✓ purrr   0.3.4
    ## ✓ tibble  3.1.6     ✓ dplyr   1.0.8
    ## ✓ tidyr   1.2.0     ✓ stringr 1.4.0
    ## ✓ readr   2.1.1     ✓ forcats 0.5.1

    ## ── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
    ## x dplyr::between()   masks data.table::between()
    ## x dplyr::filter()    masks stats::filter()
    ## x dplyr::first()     masks data.table::first()
    ## x dplyr::lag()       masks stats::lag()
    ## x dplyr::last()      masks data.table::last()
    ## x purrr::transpose() masks data.table::transpose()

## Load data

    ## Rows: 4035 Columns: 14
    ## ── Column specification ────────────────────────────────────────────────────────
    ## Delimiter: "\t"
    ## chr  (12): CDIS_Study ID, CDIS_Aliquot ID, plate, plate_location, pbs_added,...
    ## dbl   (1): nseqs
    ## dttm  (1): CDIS_collect date
    ## 
    ## ℹ Use `spec()` to retrieve the full column specification for this data.
    ## ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.

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

## CDI cases

| cdiff_case |    n |
|:-----------|-----:|
| Case       | 1516 |
| Control    | 2425 |
| NA         |   91 |

### excluding longitudinal samples

| cdiff_case |    n |
|:-----------|-----:|
| Case       | 1193 |
| Control    | 2132 |
| NA         |    2 |

## IDSA severity

| idsa |   n |
|:-----|----:|
| no   | 544 |
| yes  | 389 |

## Attributable severity

| attrib |   n |
|:-------|----:|
| no     | 513 |
| yes    |  26 |

## All-cause severity

| attrib | unattrib | allcause |   n |
|:-------|:---------|:---------|----:|
| no     | NA       | no       | 511 |
| yes    | NA       | yes      |  26 |
| NA     | no       | no       | 563 |
| NA     | yes      | yes      |  39 |
| NA     | NA       | NA       |  49 |

| allcause |    n |
|:---------|-----:|
| no       | 1074 |
| yes      |   65 |

## idsa x attrib x allcause

| idsa | attrib | unattrib |   n |
|:-----|:-------|:---------|----:|
| no   | no     | NA       | 255 |
| no   | yes    | NA       |   6 |
| no   | NA     | no       | 253 |
| no   | NA     | yes      |   7 |
| no   | NA     | NA       |  23 |
| yes  | no     | NA       | 139 |
| yes  | yes    | NA       |  18 |
| yes  | NA     | no       | 189 |
| yes  | NA     | yes      |  32 |
| yes  | NA     | NA       |  11 |
| NA   | no     | NA       | 117 |
| NA   | yes    | NA       |   2 |
| NA   | NA     | no       | 121 |
| NA   | NA     | NA       |  20 |

| idsa | allcause |   n |
|:-----|:---------|----:|
| no   | no       | 508 |
| no   | yes      |  13 |
| no   | NA       |  23 |
| yes  | no       | 328 |
| yes  | yes      |  50 |
| yes  | NA       |  11 |
| NA   | no       | 238 |
| NA   | yes      |   2 |
| NA   | NA       |  20 |
