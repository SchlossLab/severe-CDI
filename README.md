
# severe-CDI

#### Predicting Severity of *C. difficile* Infections from the Taxonomic Composition of the Gut Microbiome

Kelly L. Sovacool, Sarah E. Tomkovich, Megan L. Coden, Jenna Wiens,
Vincent B. Young, Krishna Rao, Patrick D. Schloss

## Abstract

*Clostridioides difficile* infection (CDI) can lead to adverse outcomes
including ICU admission, colectomy, and death. The composition of the
gut microbiome plays an important role in determining colonization
resistance and clearance upon exposure to *C. difficile*. We
investigated whether machine learning (ML) models trained on 16S rRNA
gene amplicon sequences from gut microbiota extracted from 1,277 patient
stool samples on the day of CDI diagnosis could predict which CDI cases
led to severe outcomes. We then trained ML models to predict CDI
severity on OTU relative abundances according to four different severity
definitions: the IDSA severity score on the day of diagnosis, all-cause
adverse outcomes within 30 days, adverse outcomes confirmed as
attributable to CDI via chart review, and a pragmatic definition that
uses the attributable definition when available and otherwise uses the
all-cause definition. The models predicting pragmatic severity performed
best, suggesting that while chart review is valuable to verify the cause
of complications, including as many samples as possible is indispensable
for training performant models on imbalanced datasets. Permutation
importance identified *Enterococcus* as the most important OTU for model
performance, and increased relative abundance of *Enterococcus* was
associated with severe outcomes. Finally, we evaluated the potential
clinical value of the OTU-based models and found similar performance
compared to prior models based on Electronic Health Records. The modest
performance of the OTU-based models represents a step toward the goal of
deploying models to inform clinical decisions and ultimately improve CDI
outcomes.

## Manuscript

- [Quarto](paper/paper.qmd)
- [PDF](paper/paper.pdf)
- [Markdown](paper/paper-gfm.md)

### Word count

- abstract: 242
- body: 4885
