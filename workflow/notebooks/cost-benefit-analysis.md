Cost-Benefit Analysis
================
2023-04-25

- use values from confusion matrix for one representative model on a
  test set.
  - number needed to screen
  - number needed to treat
  - number needed to benefit
- assumptions
  - cost of a non-severe case
  - cost of a severe case
    - days in icu, colectomy
  - cost of possible treatments:
    - abx: metronizadole, vancomycin, fidaxomycin
    - fmt, monoclonal antibodies

## evaluating ml models

[number needed to
benefit](https://academic.oup.com/jamia/article-abstract/26/12/1655/5516459)

> In the simplest terms, prediction can be distilled into an NNS and
> action into a number needed to treat. When contextualized within this
> framework, the product of NNS and number needed to treat results in a
> number needed to benefit. The table outlines key variables in this
> framework that will alter the estimated number needed to benefit
> across different modeling and implementation scenarios.

## lit review

### [Gupta \_et al.](https://journals.sagepub.com/doi/10.1177/17562848211018654)

- average cost of CDI case in the US:
  - \$8k to \$30k (Nanwa *et al*)
  - \$21k (Zhang *et al*)
  - likely underestimates of true attributable costs.
- treatment
  - IDSA recommends either vancomycin or fidaxomycin for 10 days
  - Metronizadole out of favor, not efficacious
  - Recommend FMT after multiple recurrences
  - monoclonal Ab now an fda-approved treatment

#### treatment costs

> More recently, Rajasingham et al. calculated the costs of the
> currently available therapies for CDI. The cost of oral metronidazole
> (10-day course) ranged from US\$4.38 to US\$13.14, intravenous
> metronidazole (14-day course) from US\$19.56 to \$58.68, vancomycin
> (10-day course) from US\$7.04 to US\$21.12, rifaximin (20-day course)
> from US\$44.16 to US\$132.48, and fidaxomicin (10day course), being
> the most expensive option, ranged from US\$883.60 to US\$2650.80. It
> is difficult to predict the exact cost of FMT due to the multiple
> variables involved, including source of stool and route of
> administration. In general, one course of FMT is estimated to cost
> between US\$500 and US\$2000.

### [fidaxomycin clinical trial](https://www.nejm.org/doi/full/10.1056/nejmoa0910812)

no significant difference in whether CDI was cured, but did have
significant difference in recurrence.

### [severe CDI treatment options](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3088840/)

**from 2008, now out of date**

see table for different treatment recommendations for mild-moderate CDI,
IDSA severe CDI, and complicated CDI.

could compare cost-benefit analysis with IDSA severity.

### [idsa treatment guidelines comparison](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC9780550/)

i may need to also consider “fulminant” cdi criteria

### [mich med treatment guidelines](https://www.med.umich.edu/1info/FHP/practiceguides/InptCDiff/C-Diff.pdf)

from 2019, has this been updated?
