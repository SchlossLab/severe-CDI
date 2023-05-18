# Predicting *C. difficile* Infection Severity from the Taxonomic
Composition of the Gut Microbiome
Kelly L. SovacoolSarah E. TomkovichMegan L. CodenVincent B. YoungKrishna
RaoPatrick D. Schloss
May 18, 2023

# Introduction

A few ways to define CDI severity ([Figure 1](#fig-flowchart))

The IDSA definition is known to be a poor predictor of adverse outcomes
(Stevens et al. 2020), however, it is easy to collect.

# Results

## Model performance

Report median AUROC for training set and test set, and median AUBPRC for
test set ([Figure 2](#fig-performance)).

## Feature importance

Most important OTUs contributing to model performance
([Figure 3](#fig-features))

## Clinical value of severity prediction models

# Discussion

TODO

# Materials and Methods

## Sample collection

This study was approved by the University of Michigan Institutional
Review Board. All patient samples were collected by the University of
Michigan Health System from January 2016 through December 2017. Stool
samples that had unformed stool consistency were tested for *C.
difficile* by the clinical microbiology lab with a two-step algorithm
that included detection of *C. difficile* glutamate dehydrogenase and
toxins A and B by enzyme immunoassay with reflex to PCR for the *tcdB*
gene when results were discordant. 1,517 stool samples were collected
from patients diagnosed with a CDI. Leftover stool samples that were
sent to the clinical microbiology lab were collected and split into
different aliquots. For 16S sequencing, the aliquot of stool was
resuspended in DNA genotek stabilization buffer and then stored in the
-80°C freezer. Only the first CDI sample per patient was used for
subsequent ML analyses such that no patient is represented more than
once, resulting in a dataset of 1,191 samples.

## 16S rRNA gene amplicon sequencing

Samples stored in DNA genotek buffer were thawed from the -80°C,
vortexed, and then transferred to a 96-well bead beating plate for DNA
extractions. DNA was extracted using the DNeasy Powersoil HTP 96 kit
(Qiagen) and an EpMotion 5075 automated pipetting system (Eppendorf).
The V4 region of the 16S rRNA gene was amplified with the AccuPrime Pfx
DNA polymerase (Thermo Fisher Scientific) using custom barcoded primers,
as previously described (Kozich et al. 2013). Each library preparation
plate for sequencing contained a negative control (water) and mock
community control (ZymoBIOMICS microbial community DNA standards). The
PCR amplicons were normalized (SequalPrep normalizatin plate kit from
Thermo Fisher Scientific), pooled and quantified (KAPA library
quantification kit from KAPA Biosystems), and sequenced with the MiSeq
system (Illumina).

All sequences were processed with mothur (v1.46) using the MiSeq SOP
protocol (Schloss et al. 2009; Kozich et al. 2013). Paired sequencing
reads were combined and aligned with the SILVA (v132) reference database
(Quast et al. 2013) and taxonomy was assigned with a modified version of
the Ribosomal Database Project reference sequences (v16) (Cole et al.
2014). Sequences were clustered into *de novo* OTUs with the OptiClust
algorithm in mothur (Westcott and Schloss 2017). Samples were rarefied
to 5,000 sequences per sample, repeated 1,000 times for alpha and beta
diversity analysis.
<!-- TODO supplementary figure with alpha and beta diversity & significance -->

## Defining CDI severity

We explore four different ways to define CDI cases as severe or not. The
IDSA definition of severe CDI is based on lab values collected on the
day of diagnosis, with a case being severe if serum creatinine level is
greater than or equal to $1.5 mg/dL$ and the white blood cell count is
greater than or equal to $15 k/\mu L$ (**mcdonald_clinical_2018?**). The
remaining definitions focus on the occurrence of adverse outcomes, which
may be more clinically relevant. The all-cause severity definition
defines a case as severe if ICU admission, colectomy, or death occurs
within 30 days of CDI diagnosis, regardless of the cause of the adverse
event. The attributable severity definition is based on disease-related
complications defined by the CDC, where an adverse event of ICU
admission, colectomy, or death occurs within 30 days of CDI diagnosis,
and the adverse event is determined to be attributable to the CDI by
physician chart review (McDonald et al. 2007). Finally, we defined a
pragmatic severity definition that makes use of the attributable
definition when available and falls back to the all-cause definition
when chart review has not been completed, allowing us to use as many
samples as we have available while taking physicians’ expert opinions
into account where possible.

## Model training and evaluation

Random forest models were used to examine whether OTU data collected on
the day of diagnosis could classify CDI cases as severe according to
four different definitions of severity. We used the mikropml R package
v1.5.0 (Topçuoğlu et al. 2021) for all steps of the machine learning
analysis. We randomly split the data into an 80% training and 20% test
set and repeated this 100 times, followed by training models with 5-fold
cross-validation. Model performance was calculated on the test set using
the area under the receiver-operator characteristic curve (AUROC) and
the area under the balanced precision-recall curve (AUBPRC). Permutation
feature importance was then performed to determine which OTUs
contributed most to model performance. We reported OTUs with a
significant permutation test in at least 80 of the 100 models.

Since the severity labels are imbalanced with different frequencies of
severity for each definition, we calculated balanced precision, the
precision expected if the labels were balanced. The balanced precision
and the area under the balanced precision-recall curve (AUBPRC) were
calculated with Equations 1 and 7 from Wu et al. (2021).

## Code availability

The complete workflow, code, and supporting files required to reproduce
this manuscript with accompanying figures is available at
<https://github.com/SchlossLab/severe-CDI>.
<!-- TODO update GitHub URL once accepted to journal -->

The workflow was defined with Snakemake (Köster and Rahmann 2012) using
a custom version of the mikropml Snakemake workflow (Sovacool et al.
2023). Dependencies were managed with conda environments. Scripts were
written in R (R Core Team 2020), Python (Van Rossum and Drake 2009), and
GNU bash. Additional software and packages used in the creation of this
manuscript include cowplot (Wilke 2020a), ggtext (Wilke 2020b), ggsankey
(Sjoberg 2022), schtools (Sovacool, Lesniak, and Schloss 2022), the
tidyverse metapackage (Wickham et al. 2019), Quarto, and vegan (Oksanen
et al. 2023).

## Data availability

The 16S rRNA sequencing data have been deposited in the National Center
for Biotechnology Information Sequence Read Archive (BioProject
Accession no. PRJNA729511).

# Acknowledgements

TODO

# References

<div id="refs" class="references csl-bib-body hanging-indent">

<div id="ref-cole_ribosomal_2014" class="csl-entry">

Cole, James R., Qiong Wang, Jordan A. Fish, Benli Chai, Donna M.
McGarrell, Yanni Sun, C. Titus Brown, Andrea Porras-Alfaro, Cheryl R.
Kuske, and James M. Tiedje. 2014. “Ribosomal Database Project: Data and
Tools for High Throughput <span class="nocase">rRNA</span> Analysis.”
*Nucl. Acids Res.* 42 (D1): D633–42.
<https://doi.org/10.1093/nar/gkt1244>.

</div>

<div id="ref-koster_snakemake_2012" class="csl-entry">

Köster, Johannes, and Sven Rahmann. 2012. “Snakemake a Scalable
Bioinformatics Workflow Engine.” *Bioinformatics* 28 (19): 2520–22.
<https://doi.org/10.1093/bioinformatics/bts480>.

</div>

<div id="ref-kozich_development_2013" class="csl-entry">

Kozich, James J., Sarah L. Westcott, Nielson T. Baxter, Sarah K.
Highlander, and Patrick D. Schloss. 2013. “Development of a Dual-Index
Sequencing Strategy and Curation Pipeline for Analyzing Amplicon
Sequence Data on the MiSeq Illumina Sequencing Platform.” *Appl.
Environ. Microbiol.* 79 (17): 5112–20.
<https://doi.org/10.1128/AEM.01043-13>.

</div>

<div id="ref-mcdonald_recommendations_2007" class="csl-entry">

McDonald, L. Clifford, Bruno Coignard, Erik Dubberke, Xiaoyan Song,
Teresa Horan, and Preeta K. Kutty. 2007. “Recommendations for
Surveillance of Clostridium Difficile Disease.” *Infection Control &Amp;
Hospital Epidemiology* 28 (2): 140–45. <https://doi.org/10.1086/511798>.

</div>

<div id="ref-oksanen_vegan_2023" class="csl-entry">

Oksanen, Jari, Gavin L. Simpson, F. Guillaume Blanchet, Roeland Kindt,
Pierre Legendre, Peter R. Minchin, R. B. O’Hara, et al. 2023. *Vegan:
Community Ecology Package*.

</div>

<div id="ref-quast_silva_2013" class="csl-entry">

Quast, Christian, Elmar Pruesse, Pelin Yilmaz, Jan Gerken, Timmy
Schweer, Pablo Yarza, Jörg Peplies, and Frank Oliver Glöckner. 2013.
“The SILVA Ribosomal RNA Gene Database Project: Improved Data Processing
and Web-Based Tools.” *Nucleic Acids Research* 41 (D1): D590–96.
<https://doi.org/10.1093/nar/gks1219>.

</div>

<div id="ref-r_core_team_r_2020" class="csl-entry">

R Core Team. 2020. *R: A Language and Environment for Statistical
Computing*. Manual. Vienna, Austria: R Foundation for Statistical
Computing.

</div>

<div id="ref-schloss_introducing_2009" class="csl-entry">

Schloss, Patrick D., Sarah L. Westcott, Thomas Ryabin, Justine R. Hall,
Martin Hartmann, Emily B. Hollister, Ryan A. Lesniewski, et al. 2009.
“Introducing Mothur: Open-Source, Platform-Independent,
Community-Supported Software for Describing and Comparing Microbial
Communities.” *Applied and Environmental Microbiology* 75 (23): 7537–41.
<https://doi.org/10.1128/AEM.01541-09>.

</div>

<div id="ref-sjoberg_ggsankey_2022" class="csl-entry">

Sjoberg, David. 2022. *Ggsankey: Sankey, Alluvial and Sankey Bump
Plots*.

</div>

<div id="ref-sovacool_mikropml_2023" class="csl-entry">

Sovacool, Kelly, Zena Lapp, Courtney Armour, Sarah K. Lucas, and Patrick
Schloss. 2023. “Mikropml Snakemake Workflow.” Zenodo.
<https://doi.org/10.5281/zenodo.4759351>.

</div>

<div id="ref-sovacool_schtools_2022" class="csl-entry">

Sovacool, Kelly, Nick Lesniak, and Patrick Schloss. 2022. “Schtools:
Schloss Lab Tools for Reproducible Microbiome Research.”
<https://doi.org/10.5281/zenodo.6540687>.

</div>

<div id="ref-stevens_validation_2020" class="csl-entry">

Stevens, Vanessa W., Holly E. Shoemaker, Makoto M. Jones, Barbara E.
Jones, Richard E. Nelson, Karim Khader, Matthew H. Samore, and Michael
A. Rubin. 2020. “Validation of the SHEA/IDSA Severity Criteria to
Predict Poor Outcomes Among Inpatients and Outpatients with
Clostridioides Difficile Infection.” *Infection Control & Hospital
Epidemiology* 41 (5): 510–16. <https://doi.org/10.1017/ice.2020.8>.

</div>

<div id="ref-topcuoglu_mikropml_2021" class="csl-entry">

Topçuoğlu, Begüm D., Zena Lapp, Kelly L. Sovacool, Evan Snitkin, Jenna
Wiens, and Patrick D. Schloss. 2021. “Mikropml: User-Friendly R Package
for Supervised Machine Learning Pipelines.” *JOSS* 6 (61): 3073.
<https://doi.org/10.21105/joss.03073>.

</div>

<div id="ref-van_rossum_python_2009" class="csl-entry">

Van Rossum, Guido, and Fred L. Drake. 2009. “Python 3 Reference Manual
\| Guide Books.”

</div>

<div id="ref-westcott_opticlust_2017" class="csl-entry">

Westcott, Sarah L., and Patrick D. Schloss. 2017. “OptiClust, an
Improved Method for Assigning Amplicon-Based Sequence Data to
Operational Taxonomic Units.” Edited by Katherine McMahon. *mSphere* 2
(2): e00073–17. <https://doi.org/10.1128/mSphereDirect.00073-17>.

</div>

<div id="ref-wickham_welcome_2019" class="csl-entry">

Wickham, Hadley, Mara Averick, Jennifer Bryan, Winston Chang, Lucy
D’Agostino McGowan, Romain François, Garrett Grolemund, et al. 2019.
“Welcome to the Tidyverse.” *Journal of Open Source Software* 4 (43):
1686. <https://doi.org/10.21105/joss.01686>.

</div>

<div id="ref-wilke_cowplot_2020" class="csl-entry">

Wilke, Claus O. 2020a. *Cowplot: Streamlined Plot Theme and Plot
Annotations for ’Ggplot2’*.

</div>

<div id="ref-wilke_ggtext_2020" class="csl-entry">

———. 2020b. *Ggtext: Improved Text Rendering Support for ’Ggplot2’*.
Manual.

</div>

<div id="ref-wu_improved_2021" class="csl-entry">

Wu, Yingzhou, Hanqing Liu, Roujia Li, Song Sun, Jochen Weile, and
Frederick P. Roth. 2021. “Improved Pathogenicity Prediction for Rare
Human Missense Variants.” *The American Journal of Human Genetics* 108
(10): 1891–1906. <https://doi.org/10.1016/j.ajhg.2021.08.012>.

</div>

</div>

# Figures

<div id="fig-flowchart">

![](figures/flowchart_sankey.png)

Figure 1: **CDI severity definitions.** **A)** Decision flow chart to
define CDI cases as severe according to the Infectious Diseases Society
of America (IDSA) based on lab values, the occurence of complications
due to any cause (All-cause), and the occurence of disease-related
complications confirmed as attributable to CDI with chart review
(Attrib). **B)** The proportion of severe CDI cases labelled according
to each definition. An additional ‘Pragmatic’ severity definition uses
the Attributable definition when possible, and falls back to the
All-cause definition when chart review is not available.
<!-- TODO table (supplementary?) showing counts & frequency of positives-->

</div>

<div id="fig-performance">

![](figures/ml-performance.png)

Figure 2: **Performance of ML models.** Area under the receiver-operator
characteristic curve (AUROC) for the test sets and cross-validation
folds of the training sets, and the area under the balanced
precision-recall curve (AUBPRC) for the test sets. Left: models were
trained on the full dataset, with different numbers of samples available
for each severity definition. Right: models were trained on the
intersection of samples with all labels available for each definition.
Note that Attributable and Pragmatic severity are exactly the same for
the intersection set. <!-- TODO add plots of AUROC and AUBPRC curves -->

</div>

<div id="fig-features">

![](figures/feature-importance.png)

Figure 3: **Feature importance.** Feature importance via permutation
test. For each OTU, the order of samples was randomized in the test set
100 times and the performance was re-calculated to estimate the
permutation performance. An OTU was considered important if the
performance decreased when the OTU was permuted in at least 80% of the
models. OTUs with a greater difference in AUROC (actual performance
minus permutation performance) are more important. Left: models were
trained on the full dataset, with different numbers of samples available
for each severity definition. Right: models were trained on the
intersection of samples with all labels available for each definition.
Note that Attributable and Pragmatic severity are exactly the same for
the intersection set.

</div>
