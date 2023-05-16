# Predicting *C. difficile* Infection Severity from the Taxonomic
Composition of the Gut Microbiome
Kelly L. SovacoolSarah E. TomkovichMegan L. CodenVincent B. YoungKrishna
RaoPatrick D. Schloss
May 16, 2023

# Introduction

A few ways to define CDI severity ([Figure 1](#fig-flowchart))

# Results

## Model performance

Report median AUROC for trainset and testset, and median AUBPRC for
testset ([Figure 2](#fig-performance)).

## Feature importance

1)  

## Clinical value of severity prediction models

# Discussion

TODO

# Materials and Methods

## Sample collection and 16S rRNA gene amplicon sequencing

(Schloss et al. 2009)

## Defining CDI severity

IDSA definition of severe CDI based on lab values. CDC definiton of
severe CDI based on disease-related complications (McDonald et al.
2007).

## Model training and evaluation

(Topçuoğlu et al. 2021)

### Balanced precision

## Code and data availability

(Sovacool, Lesniak, and Schloss 2022)

# Acknowledgements

TODO

# References

<div id="refs" class="references csl-bib-body hanging-indent">

<div id="ref-mcdonald_recommendations_2007" class="csl-entry">

McDonald, L. Clifford, Bruno Coignard, Erik Dubberke, Xiaoyan Song,
Teresa Horan, and Preeta K. Kutty. 2007. “Recommendations for
Surveillance of Clostridium Difficile Disease.” *Infection Control &Amp;
Hospital Epidemiology* 28 (2): 140–45. <https://doi.org/10.1086/511798>.

</div>

<div id="ref-schloss_introducing_2009" class="csl-entry">

Schloss, Patrick D., Sarah L. Westcott, Thomas Ryabin, Justine R. Hall,
Martin Hartmann, Emily B. Hollister, Ryan A. Lesniewski, et al. 2009.
“Introducing Mothur: Open-Source, Platform-Independent,
Community-Supported Software for Describing and Comparing Microbial
Communities.” *Applied and Environmental Microbiology* 75 (23): 7537–41.
<https://doi.org/10.1128/AEM.01541-09>.

</div>

<div id="ref-sovacool_schtools_2022" class="csl-entry">

Sovacool, Kelly, Nick Lesniak, and Patrick Schloss. 2022. “Schtools:
Schloss Lab Tools for Reproducible Microbiome Research.”
<https://doi.org/10.5281/zenodo.6540687>.

</div>

<div id="ref-topcuoglu_mikropml_2021" class="csl-entry">

Topçuoğlu, Begüm D., Zena Lapp, Kelly L. Sovacool, Evan Snitkin, Jenna
Wiens, and Patrick D. Schloss. 2021. “Mikropml: User-Friendly R Package
for Supervised Machine Learning Pipelines.” *JOSS* 6 (61): 3073.
<https://doi.org/10.21105/joss.03073>.

</div>

</div>

# Figures

<div id="fig-flowchart">

![](figures/flowchart_sankey.png)

Figure 1: **CDI severity definitions.** A) Decision flow chart to define
CDI cases as severe according to the Infectious Diseases Society of
America (IDSA) based on lab values, the occurence of complications due
to any cause (All-cause), and the occurence of disease-related
complications confirmed as attributable to CDI with chart review
(Attrib). B) The proportion of severe CDI cases labelled according to
each definition. An additional ‘Pragmatic’ severity definition uses the
Attributable definition when possible, and falls back to the All-cause
definition when chart review is not available.

</div>

<div id="fig-performance">

![](figures/ml-performance.png)

Figure 2: **Performance of ML models.** Area Under the Receiver-Operator
Characteristic Curve (AUROC) for the cross-validation trainsets and
testsets, and the Area Under the Balanced Precision-Recall Curve (AUPRC)
for the testsets. Left: models were trained on the full dataset, with
different numbers of samples available for each severity definition.
Right: models were trained on the intersection of samples with all
labels available for each definition.

</div>

<div id="fig-features">

TODO insert figure here

Figure 3: **Feature importance.**

</div>
